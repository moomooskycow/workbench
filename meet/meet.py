# meet.py — record, transcribe, and diarize meetings locally.
#
# Subcommands:
#   record  <out.wav> [--seconds N]   capture mic + call audio into one file
#   session [--seconds N]             record a call, then transcribe+diarize to daybook
#   watch  [dir]                      daemon: auto-transcribe new files in dir to daybook
#   all  <audio> [-o OUT]             transcript + speakers -> markdown
#   transcribe <audio> [-o OUT]       whisper transcript (no diarization)
#   diarize <audio> [-o OUT]          speaker turns only
#   speakers <audio>                  quick speaker-count/attribution summary
#   setup                             install the transcription + diarization stack
#
# Default write location for notes: ~/Documents/daybook/meetings/

import argparse
import datetime as dt
import os
import sys
import time
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# The venv lives outside the repo tree (it is huge and the review gate requires
# a clean worktree under tracked paths). See the `meet` launcher.
VENV_PY = os.path.expanduser("~/.local/share/meet-venv/bin/python")
RECORDINGS = os.path.expanduser("~/.local/state/meet/recordings")

import capture as cap  # noqa: E402
import transcribe as tr  # noqa: E402
import diarize as dz  # noqa: E402

DEFAULT_MODEL = os.environ.get("MEET_MODEL", "large-v3-turbo")
DEFAULT_DEVICE = os.environ.get("MEET_DEVICE", "auto")
DAYBOOK = os.path.expanduser("~/Documents/daybook/meetings")
DEFAULT_SPEAKERS = int(os.environ.get("MEET_SPEAKERS", "0")) or None
WATCH_SETTLE_SECONDS = 2.0


def _fmt(sec):
    sec = int(sec)
    return f"{sec//3600:02d}:{sec//60%60:02d}:{sec%60:02d}"


def _hf_token():
    return os.environ.get("HF_TOKEN") or os.environ.get("HUGGING_FACE_HUB_TOKEN")


def _resolve_device():
    d = DEFAULT_DEVICE
    if d != "auto":
        return d
    import subprocess

    try:
        subprocess.run(["nvidia-smi"], capture_output=True, timeout=5, check=True)
        return "cuda"
    except Exception:
        return "cpu"


def _transcribe_segments(audio, args):
    """Run transcription respecting MEET defaults; shared by all commands."""
    return tr.transcribe(
        audio,
        model_name=args.model or DEFAULT_MODEL,
        device=args.device or _resolve_device(),
    )


def cmd_record(args):
    out = args.out
    os.makedirs(os.path.dirname(os.path.abspath(out)) or ".", exist_ok=True)
    res = cap.record(out, duration=args.seconds)
    print(f"saved {res}")


def cmd_transcribe(args):
    segments, info = _transcribe_segments(args.audio, args)
    text = "\n".join(seg["text"] for seg in segments)
    if args.out:
        _atomic_write(args.out, text + "\n")
        print(f"wrote {args.out}")
    else:
        print(text)


def cmd_diarize(args):
    segments, info = _transcribe_segments(args.audio, args)
    try:
        turns = dz.diarize(args.audio, segments, hf_token=_hf_token(),
                           device=args.device or _resolve_device(),
                           num_speakers=args.speakers or DEFAULT_SPEAKERS)
    except dz.NoDiarization as e:
        print(f"[diarize] {e}", file=sys.stderr)
        sys.exit(2)
    out = args.out or (os.path.splitext(args.audio)[0] + ".speakers.txt")
    _atomic_write(out, "".join(f"{_fmt(t['start'])}  {t['speaker']}\n" for t in turns))
    print(f"wrote {out}")


def _unique_path(path):
    """Return path if free, else path with a numeric suffix that is free."""
    if not os.path.exists(path):
        return path
    stem, ext = os.path.splitext(path)
    for i in range(2, 100):
        cand = f"{stem}-{i}{ext}"
        if not os.path.exists(cand):
            return cand
    # Extremely unlikely fallback: microseconds make collisions improbable.
    cand = f"{stem}-{dt.datetime.now().strftime('%H%M%S%f')}{ext}"
    if not os.path.exists(cand):
        return cand
    raise RuntimeError(f"cannot allocate a unique path near {path}")


def _reserve_unique_path(path):
    """Reserve a free path atomically, adding a numeric suffix when needed."""
    path = os.fspath(path)
    stem, ext = os.path.splitext(path)
    suffix = 1
    while True:
        candidate = path if suffix == 1 else f"{stem}-{suffix}{ext}"
        try:
            fd = os.open(candidate, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o666)
        except FileExistsError:
            suffix += 1
            continue
        os.close(fd)
        return Path(candidate)


def _atomic_write(path, text):
    import tempfile

    out_dir = os.path.dirname(path) or "."
    os.makedirs(out_dir, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=out_dir, prefix=os.path.basename(path) + ".", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(text)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def _write_markdown(audio, segments, turns, out, now=None):
    now = now or dt.datetime.now()
    body = [
        "# Meeting transcript",
        "",
        f"- Date: {now.strftime('%Y-%m-%d %H:%M')}",
        f"- Source: {audio}",
        f"- Model: {DEFAULT_MODEL}",
    ]
    if turns:
        speakers = []
        for t in turns:
            if t["speaker"] not in speakers:
                speakers.append(t["speaker"])
        body.append(f"- Speakers: {', '.join(speakers)}")
    body.append("")

    frontmatter = (
        "---\n"
        f"type: meeting\n"
        f"status: active\n"
        f"created: {now.strftime('%Y-%m-%dT%H:%M:%S')}\n"
        "tags: [meeting, transcript]\n"
        "---\n\n"
    )
    lines = [frontmatter] + body

    if turns:
        # Merge transcript words across diarized turns by containment.
        words = []
        for seg in segments:
            for w in seg["words"] or []:
                words.append((w["s"], w["e"], w["w"]))
            if not seg["words"]:
                words.append((seg["start"], seg["end"], seg["text"]))
        if words:
            merged = _merge_words_turns(words, turns)
            for start, end, speaker, text in merged:
                lines.append(f"\n[{_fmt(start)} - {_fmt(end)}] **{speaker}:** {text}")
            _atomic_write(out, "\n".join(lines) + "\n")
            return

    # No usable diarization: plain transcript.
    for seg in segments:
        lines.append(f"\n[{_fmt(seg['start'])} - {_fmt(seg['end'])}] {seg['text']}")
    _atomic_write(out, "\n".join(lines) + "\n")


def _merge_words_turns(words, turns):
    """Join consecutive words into attributed lines. A line ends on a speaker
    change, when the gap from the previous word exceeds 2.0 s, or once it spans
    more than 4.0 s. Each word is attributed to the turn that contains it;
    words that fall in a gap carry the nearest preceding turn's speaker."""
    import bisect

    ws = sorted(words, key=lambda w: w[0])
    ts = sorted(turns, key=lambda t: t["start"])
    starts = [t["start"] for t in ts]
    ends = [t["end"] for t in ts]

    def spk_of(s):
        i = bisect.bisect_right(starts, s) - 1
        if i < 0:
            return ts[0]["speaker"]  # before the first turn: nearest
        if s <= ends[i]:
            return ts[i]["speaker"]
        if i + 1 < len(ts) and s >= starts[i + 1] and s < ends[i + 1]:
            return ts[i + 1]["speaker"]
        return ts[i]["speaker"]  # after a turn, in a gap: carry that speaker

    merged = []
    line_start = line_end = line_spk = None
    line_words = []

    def flush():
        nonlocal line_start, line_end, line_spk, line_words
        if line_words:
            merged.append((line_start, line_end, line_spk,
                           " ".join(line_words).replace("  ", " ").strip()))
        line_start = line_end = line_spk = None
        line_words = []

    for s, e, w in ws:
        spk = spk_of(s)
        if line_spk is None:
            line_start, line_end, line_spk, line_words = s, e, spk, [w]
        elif (spk == line_spk and (s - line_end) < 2.0
              and (s - line_start) < 4.0):
            line_words.append(w)
            line_end = e
        else:
            flush()
            line_start, line_end, line_spk, line_words = s, e, spk, [w]
    flush()
    return merged


def _process_audio(audio, args, note_out=None):
    """Transcribe + diarize `audio`, write the markdown note, return its path."""
    if not os.path.exists(audio):
        print(f"audio not found: {audio}", file=sys.stderr)
        sys.exit(1)
    now = dt.datetime.now()  # local: file name and body stay consistent
    print(f"[meet] transcribing {audio} ...", file=sys.stderr)
    segments, info = _transcribe_segments(audio, args)
    print(f"[meet] transcription done ({len(segments)} segments)", file=sys.stderr)

    if note_out is None:
        base = os.path.join(DAYBOOK, f"{now.date().isoformat()}-transcript")
        note_out = _unique_path(base + ".md")

    # Try diarization; a missing backend is expected, a real error is not.
    turns = None
    try:
        turns = dz.diarize(audio, segments, hf_token=_hf_token(),
                           device=args.device or _resolve_device(),
                           num_speakers=args.speakers or DEFAULT_SPEAKERS)
        print(f"[meet] diarization done ({len(turns)} turns)", file=sys.stderr)
    except dz.NoDiarization as e:
        print(f"[meet] {e}", file=sys.stderr)
    except Exception as e:
        _write_markdown(audio, segments, None, note_out, now=now)
        print(f"wrote {note_out} (transcript only)", file=sys.stderr)
        print(f"[meet] DIARIZATION ERROR: {e!r}", file=sys.stderr)
        sys.exit(1)

    _write_markdown(audio, segments, turns, note_out, now=now)
    print(f"wrote {note_out}")
    if turns:
        speakers = []
        for t in turns:
            if t["speaker"] not in speakers:
                speakers.append(t["speaker"])
        print(f"speakers detected: {len(speakers)} ({', '.join(speakers)})", file=sys.stderr)
    return note_out


def cmd_all(args):
    _process_audio(args.audio, args, note_out=args.out)


def cmd_session(args):
    """Record a meeting, then transcribe + diarize it straight to the daybook."""
    os.makedirs(RECORDINGS, exist_ok=True)
    wav = args.out or os.path.join(
        RECORDINGS, f"session-{dt.datetime.now().strftime('%Y%m%d-%H%M%S')}.wav")
    cap.record(wav, duration=args.seconds)
    _process_audio(wav, args, note_out=None)


def cmd_watch(args):
    """Watch INBOX; every new audio file is transcribed to the daybook."""
    inbox = Path(os.path.expanduser(args.dir or "~/meet-inbox"))
    inbox.mkdir(parents=True, exist_ok=True)
    done = inbox / "processed"
    done.mkdir(exist_ok=True)
    exts = {".wav", ".ogg", ".m4a", ".mp3", ".flac", ".webm"}
    print(f"[meet] watching {inbox} for new recordings (Ctrl-C to stop)", file=sys.stderr)
    observations = {}
    while True:
        for p in sorted(inbox.iterdir()):
            if not p.is_file() or p.suffix.lower() not in exts:
                continue
            stat = p.stat()
            version = (stat.st_size, stat.st_mtime_ns)
            now = time.monotonic()
            observation = observations.get(p.name)
            if observation is None or observation["version"] != version:
                observations[p.name] = observation = {
                    "version": version,
                    "quiet_since": now,
                    "status": "candidate",
                }
                print(f"[meet] new file: {p}", file=sys.stderr)
                continue
            if observation["status"] == "failed":
                continue
            if now - observation["quiet_since"] < WATCH_SETTLE_SECONDS:
                continue
            try:
                _process_audio(str(p), args, note_out=None)
            except Exception as e:
                observation["status"] = "failed"
                print(f"[meet] FAILED {p.name}: {e}", file=sys.stderr)
            else:
                destination = _reserve_unique_path(done / p.name)
                try:
                    os.replace(str(p), str(destination))
                except OSError:
                    try:
                        os.unlink(destination)
                    except OSError:
                        pass
                    raise
                del observations[p.name]
                print(f"[meet] moved -> {destination}", file=sys.stderr)
        time.sleep(args.interval)


def cmd_speakers(args):
    segments, info = tr.transcribe(
        args.audio, model_name=args.model or DEFAULT_MODEL,
        device=args.device or _resolve_device(),
    )
    try:
        turns = dz.diarize(args.audio, segments, hf_token=_hf_token(),
                           device=args.device or _resolve_device(),
                           num_speakers=args.speakers or DEFAULT_SPEAKERS)
    except dz.NoDiarization as e:
        print(str(e), file=sys.stderr)
        sys.exit(2)
    from collections import Counter

    c = Counter(t["speaker"] for t in turns)
    for spk, n in c.most_common():
        print(f"{spk}: {n} turns")
    for t in turns:
        print(f"{_fmt(t['start'])} - {_fmt(t['end'])}  {t['speaker']}")


def cmd_setup(args):
    """Install the diarization stack (torch + pyannote + speechbrain + scipy)."""
    back = os.environ.get("MEET_SETUP_BACKEND", "")
    if back not in ("", "cpu", "cuda"):
        print(f"[meet] invalid MEET_SETUP_BACKEND={back!r} (use '', 'cpu' or 'cuda')",
              file=sys.stderr)
        sys.exit(2)
    # Pinned to the versions the venv was shipped and the code is tested against.
    pinned = ["torch==2.13.0", "torchaudio==2.11.0"]
    extra = ["pyannote.audio==4.0.7", "speechbrain", "scipy", "soundfile"]
    token = " with HF_TOKEN set." if _hf_token() else (
        " unset. Set HF_TOKEN (see huggingface.co/pyannote/speaker-diarization-3.1) "
        "for the best quality pyannote backend; without it the cluster fallback is used."
    )
    print(f"[meet] installing transcription + diarization stack")
    print(f"[meet] HF_TOKEN is {token}", file=sys.stderr)
    import subprocess

    base = ["uv", "pip", "install", "--python", VENV_PY]
    steps = [[*base, "faster-whisper", "pydub"]]
    if back == "cpu":
        # PyTorch CPU wheels come from their own index; the rest from PyPI.
        steps.append([*base, *pinned, "--index-url", "https://download.pytorch.org/whl/cpu"])
        steps.append([*base, *extra])
    else:
        steps.append([*base, *pinned, *extra])
    for step in steps:
        r = subprocess.run(step, cwd=HERE)
        if r.returncode != 0:
            print(f"[meet] setup failed (uv pip exit {r.returncode})", file=sys.stderr)
            sys.exit(1)
    print("[meet] setup complete. `meet all <audio>` now includes speakers.")


def build_parser():
    ap = argparse.ArgumentParser(prog="meet", description="local meeting transcription")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("record", help="capture mic + call audio into one wav")
    p.add_argument("out")
    p.add_argument("--seconds", type=float, default=None)
    p.set_defaults(fn=cmd_record)

    p = sub.add_parser("transcribe", help="whisper transcript")
    p.add_argument("audio")
    p.add_argument("-o", "--out")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--device", default=None)
    p.set_defaults(fn=cmd_transcribe)

    p = sub.add_parser("diarize", help="speaker turns only")
    p.add_argument("audio")
    p.add_argument("-o", "--out")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--device", default=None)
    p.add_argument("--speakers", type=int, default=None,
                   help="known speaker count (default: auto; env MEET_SPEAKERS)")
    p.set_defaults(fn=cmd_diarize)

    p = sub.add_parser("all", help="transcribe + diarize to markdown (default out: daybook/meetings/)")
    p.add_argument("audio")
    p.add_argument("-o", "--out")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--device", default=None)
    p.add_argument("--speakers", type=int, default=None,
                   help="known speaker count (default: auto; env MEET_SPEAKERS)")
    p.set_defaults(fn=cmd_all)

    p = sub.add_parser("session", help="record a call, then transcribe + diarize it to the daybook")
    p.add_argument("out", nargs="?", help="wav path (default: ~/.local/state/meet/recordings/)")
    p.add_argument("--seconds", type=float, default=None, help="stop after N seconds (default: Ctrl-C)")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--device", default=None)
    p.add_argument("--speakers", type=int, default=None,
                   help="known speaker count (default: auto; env MEET_SPEAKERS)")
    p.set_defaults(fn=cmd_session)

    p = sub.add_parser("watch", help="watch a folder; auto-transcribe new recordings to the daybook")
    p.add_argument("dir", nargs="?", help="folder to watch (default: ~/meet-inbox)")
    p.add_argument("--interval", type=float, default=3.0, help="poll seconds (default 3)")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--device", default=None)
    p.add_argument("--speakers", type=int, default=None,
                   help="known speaker count (default: auto; env MEET_SPEAKERS)")
    p.set_defaults(fn=cmd_watch)

    p = sub.add_parser("speakers", help="diarization summary")
    p.add_argument("audio")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--device", default=None)
    p.add_argument("--speakers", type=int, default=None,
                   help="known speaker count (default: auto; env MEET_SPEAKERS)")
    p.set_defaults(fn=cmd_speakers)

    p = sub.add_parser("setup", help="install diarization stack")
    p.set_defaults(fn=cmd_setup)

    return ap


def main():
    try:
        args = build_parser().parse_args()
        args.fn(args)
    except KeyboardInterrupt:
        print("\n[meet] interrupted", file=sys.stderr)
        sys.exit(130)


if __name__ == "__main__":
    main()
