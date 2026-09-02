# diarize.py — speaker attribution for a transcript.
#
# Two backends:
#   pyannote  — "pyannote/speaker-diarization-3.1", best quality. The model is
#               gated on Hugging Face: it needs HF_TOKEN set and the user must
#               have accepted the model terms at huggingface.co/pyannote/speaker-diarization-3.1
#   cluster   — tokenless fallback. faster-whisper word timestamps + ECAPA
#               (speechbrain) speaker embeddings + agglomerative clustering.
#               Lower quality; enough to separate two distinct voices.
#
# The CLI chooses pyannote when HF_TOKEN is set and torch is available, else the
# clustering fallback, else no diarization with a clear warning.

import os
import sys


from transcribe import flatten_words

# Just the word/segment flattening is shared; transcription itself stays lazy.


class NoDiarization(Exception):
    pass


def _load_audio_mono(audio):
    """Decode any audio file to float32 mono at 16 kHz via PyAV."""
    import av
    import numpy as np

    container = av.open(audio)
    try:
        resampler = av.AudioResampler(format="s16", layout="mono", rate=16000)
        chunks = []
        for frame in container.decode(audio=0):
            for out in resampler.resample(frame):
                arr = out.to_ndarray()
                chunks.append(arr.reshape(-1))
        for out in resampler.resample(None):  # flush
            arr = out.to_ndarray()
            chunks.append(arr.reshape(-1))
    finally:
        container.close()
    if not chunks:
        raise RuntimeError(f"no audio decoded from {audio}")
    pcm = np.concatenate(chunks).astype(np.float32) / 32768.0
    return pcm


def pyannote_diarize(audio, hf_token, device="cuda", num_speakers=None):
    try:
        import torch
        from pyannote.audio import Pipeline
    except ImportError:
        raise
    pipeline = Pipeline.from_pretrained(
        "pyannote/speaker-diarization-3.1", token=hf_token
    )
    if device and device.startswith("cuda"):
        target = device if ":" in device else "cuda:0"
        try:
            pipeline.to(torch.device(target))
        except Exception as e:
            print(f"[diarize] warn: could not move pyannote to {target} ({e}); running on CPU",
                  file=sys.stderr)
    # Feed a decoded in-memory waveform so we do not depend on torchcodec's
    # ffmpeg bundle (unavailable in this venv); use our PyAV decoder instead.
    pcm = _load_audio_mono(audio)
    waveform = {"waveform": torch.from_numpy(pcm).unsqueeze(0), "sample_rate": 16000}
    diarization = pipeline(waveform, num_speakers=num_speakers)
    out = []
    for turn, _, speaker in diarization.itertracks(yield_label=True):
        out.append({"start": turn.start, "end": turn.end, "speaker": speaker})
    return out


def _silhouette(D, labels):
    """Mean silhouette over non-singleton points; -1 when undefined."""
    import numpy as np

    uniq = np.unique(labels)
    if len(uniq) < 2:
        return -1.0
    scores = []
    for i in range(len(labels)):
        same = labels == labels[i]
        same[i] = False
        if not same.any():
            continue  # singleton cluster: no intra distance
        a = D[i][same].mean()
        b = min(D[i][labels == c].mean() for c in uniq if c != labels[i])
        scores.append((b - a) / max(a, b))
    return float(np.mean(scores)) if scores else -1.0


def cluster_diarize(audio, segments, device="cuda", num_speakers=None):
    """Tokenless: ECAPA embeddings per word-cluster, agglomerative clustering.

    Cluster count: `num_speakers` when given; otherwise the k in 2..8 with the
    best silhouette, collapsing to one speaker when separation is weak. A flat
    distance threshold is deliberately avoided — per-chunk embeddings are noisy
    and a threshold explodes into one cluster per utterance."""
    import numpy as np
    from scipy.cluster.hierarchy import fcluster, linkage
    from scipy.spatial.distance import pdist, squareform

    try:
        from speechbrain.inference.speaker import SpeakerRecognition  # noqa: F401
        import torch
    except ImportError:
        raise

    if device == "cuda":
        device = "cuda:0"

    pcm = _load_audio_mono(audio)

    rec = SpeakerRecognition.from_hparams(
        source="speechbrain/spkrec-ecapa-voxceleb",
        savedir=os.path.expanduser("~/.cache/speechbrain"),
        run_opts={"device": device},
    )

    # Group words into utterance chunks (~1.5-3 s). A single word is too short
    # for a stable speaker embedding; a chunk spans one voice cleanly.
    words = flatten_words(segments)
    if not words:
        return []

    chunks = []
    cur = []
    for s, e, w in words:
        if cur and (s - cur[-1][1]) > 0.7:
            chunks.append(cur)
            cur = []
        cur.append((s, e, w))
    if cur:
        chunks.append(cur)
    chunks = [c for c in chunks if len(c) >= 3]
    if not chunks:
        chunks = [words]

    embeddings = []
    for chunk in chunks:
        s = chunk[0][0]
        e = chunk[-1][1]
        i0 = max(0, int(s * 16000))
        i1 = min(len(pcm), int(e * 16000) + 4000)  # +250 ms context
        seg = pcm[i0:i1]
        if seg.shape[0] < 16000 * 0.3:
            continue
        t = torch.from_numpy(seg).unsqueeze(0).to(device)
        with torch.no_grad():
            emb = rec.encode_batch(t).cpu().numpy().reshape(-1)
        embeddings.append((s, e, emb))

    if not embeddings:
        return []
    if len(embeddings) < 2:
        return [{
            "start": min(w[0] for w in words),
            "end": max(w[1] for w in words),
            "speaker": "Speaker 1",
        }]

    X = np.stack([r[2] for r in embeddings])
    # L2-normalize -> cosine distance is then Euclidean distance.
    X = X / (np.linalg.norm(X, axis=1, keepdims=True) + 1e-8)
    dist = pdist(X, metric="euclidean")
    Z = linkage(dist, method="average")
    D = squareform(dist)
    n = X.shape[0]
    if num_speakers:
        # Over-cluster, then merge back down to the pinned count below; a
        # plain maxclust at k wastes clusters on outlier chunks.
        k = max(1, min(num_speakers, n))
        labels = fcluster(Z, t=min(k + 4, n), criterion="maxclust") - 1
    else:
        best_k, best_score = 1, -1.0
        for k in range(2, min(8, n - 1) + 1):
            cand = fcluster(Z, t=k, criterion="maxclust") - 1
            score = _silhouette(D, cand)
            if score > best_score:
                best_k, best_score = k, score
        # Weak separation means the "clusters" are embedding noise, not voices.
        if best_score < 0.15:
            best_k = 1
        k = None
        labels = fcluster(Z, t=best_k, criterion="maxclust") - 1
    labels = np.asarray(labels)

    # Fold outlier clusters (crosstalk, noise, laughter) into real voices:
    # repeatedly merge the smallest cluster into the nearest other centroid,
    # until the pinned count is reached (k set) or every cluster clears the
    # size floor (auto mode).
    min_chunks = max(2, int(0.02 * n))
    while True:
        uniq = sorted(set(labels.tolist()))
        if len(uniq) <= 1:
            break
        counts = {c: int((labels == c).sum()) for c in uniq}
        smallest = min(uniq, key=lambda c: counts[c])
        if not ((k and len(uniq) > k)
                or (not k and counts[smallest] < min_chunks)):
            break
        others = [c for c in uniq if c != smallest]
        centroids = {c: X[labels == c].mean(axis=0) for c in others}
        sc = X[labels == smallest].mean(axis=0)
        dest = min(others, key=lambda c: np.linalg.norm(sc - centroids[c]))
        labels[labels == smallest] = dest
    labels = list(labels)

    units = []
    for (s, e, _), lab in zip(embeddings, labels):
        units.append((s, e, int(lab)))

    # Merge consecutive same-speaker units (gap-tolerant).
    turns = []
    for s, e, lab in units:
        if turns and turns[-1]["speaker"] == lab and s - turns[-1]["end"] < 0.6:
            turns[-1]["end"] = max(turns[-1]["end"], e)
        else:
            turns.append({"start": s, "end": e, "speaker": lab})

    if not turns:
        return []
    # Relabel by first-appearance order: Speaker 1, Speaker 2, ...
    order = {}
    for t in turns:
        if t["speaker"] not in order:
            order[t["speaker"]] = f"Speaker {len(order) + 1}"
        t["speaker"] = order[t["speaker"]]
    return turns


def diarize(audio, segments, hf_token=None, device="cuda", num_speakers=None):
    """Return list of {start, end, speaker} turns. Raises NoDiarization if
    no backend is available."""
    if hf_token:
        try:
            return pyannote_diarize(audio, hf_token, device=device,
                                    num_speakers=num_speakers)
        except ImportError:
            pass  # pyannote not installed -> fall through
        except Exception as e:
            msg = str(e).lower()
            if any(k in msg for k in ("401", "403", "restrict", "gated")):
                print(
                    "[diarize] pyannote token rejected or model terms not accepted. "
                    "Falling back to clustering.",
                    file=sys.stderr,
                )
            else:
                raise
    try:
        return cluster_diarize(audio, segments, device=device,
                               num_speakers=num_speakers)
    except ImportError:
        raise NoDiarization(
            "no diarization backend installed. Run `meet setup` to install "
            "the diarization stack."
        )
