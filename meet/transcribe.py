# transcribe.py — local transcription with faster-whisper on CUDA.

import sys


def flatten_words(segments):
    """Flatten all words in transcript order with (start, end, text) tuples."""
    words = []
    for seg in segments:
        if seg["words"]:
            for w in seg["words"]:
                words.append((w["s"], w["e"], w["w"]))
        else:
            words.append((seg["start"], seg["end"], seg["text"]))
    return words


def transcribe(audio, model_name="large-v3-turbo", device="cuda"):
    """Return ([segment dicts], info). Segments have start/end/text/words."""
    try:
        from faster_whisper import WhisperModel
    except ImportError as e:
        print(f"[transcribe] missing dependency: {e}", file=sys.stderr)
        print(
            "[transcribe] run: meet setup (or: "
            "uv pip install --python ~/.local/share/meet-venv/bin/python faster-whisper)",
            file=sys.stderr,
        )
        sys.exit(1)

    if device == "auto":
        import subprocess

        try:
            subprocess.run(["nvidia-smi"], capture_output=True, timeout=5, check=True)
            device = "cuda"
        except Exception:
            device = "cpu"

    # float16 requires CUDA; the installed CTranslate2 CPU build only has int8.
    compute_type = "float16" if device == "cuda" else "int8"
    model = WhisperModel(model_name, device=device, compute_type=compute_type)
    segments, info = model.transcribe(
        audio,
        word_timestamps=True,
        vad_filter=True,
        vad_parameters=dict(min_silence_duration_ms=500),
        beam_size=5,
        condition_on_previous_text=True,
    )
    out = []
    for seg in segments:
        words = [
            {"w": w.word, "s": w.start, "e": w.end}
            for w in (seg.words or [])
        ]
        out.append(
            {
                "start": seg.start,
                "end": seg.end,
                "text": seg.text.strip(),
                "words": words,
            }
        )
    return out, info
