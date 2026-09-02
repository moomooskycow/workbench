# capture.py — record mic + call audio into one mono WAV.
#
# Design: one ffmpeg process reads two pulse streams at the same time —
#   input[0]: the default output sink's monitor  (the remote caller + app audio)
#   input[1]: the default input source          (the local voice)
# and mixes them into a single mono stream. The two voices land in the same
# file, so diarization can separate them later. No virtual sinks, no loopbacks,
# no changes to the user's audio graph.
#
# Notes:
#   * Remote audio must play through the default sink (the call app's normal
#     behaviour when it uses system audio).
#   * The default monitor on this machine carries playback correctly; verified
#     by playing a known tone and reading it back at full amplitude.

import argparse
import shutil
import signal
import subprocess
import sys


def run(*args, timeout=20):
    r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if r.returncode != 0:
        raise RuntimeError(
            f"command failed: {' '.join(args)}\n{r.stderr.strip() or r.stdout.strip()}"
        )
    return r


def default_sink_name():
    return run("pactl", "get-default-sink").stdout.strip()


def default_source_name():
    return run("pactl", "get-default-source").stdout.strip()


def record(out_path, duration=None):
    """Record mic + call audio into out_path. duration=seconds or Ctrl-C to stop."""
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        print("[capture] ffmpeg not found. Install it: sudo apt install ffmpeg", file=sys.stderr)
        sys.exit(1)

    sink = default_sink_name()
    monitor = sink + ".monitor"
    mic = default_source_name()
    if mic == monitor or mic.endswith(".monitor"):
        # No distinct mic picked; record only the sink monitor to avoid a dupe.
        inputs = ["-f", "pulse", "-i", monitor]
        mix = "[0:a]aresample=48000"
    else:
        inputs = ["-f", "pulse", "-i", monitor, "-f", "pulse", "-i", mic]
        mix = "[0:a][1:a]amix=inputs=2:duration=longest:dropout_transition=0,aresample=48000"

    print(f"[capture] monitor={monitor}", file=sys.stderr)
    print(f"[capture] mic={mic}", file=sys.stderr)
    print(
        f"[capture] recording to {out_path}"
        + (f" for {duration}s" if duration is not None else " (Ctrl-C to stop)"),
        file=sys.stderr,
    )

    cmd = [
        ffmpeg, "-v", "error",
        *inputs,
        "-filter_complex", mix,
        "-ac", "1", "-ar", "48000",
    ]
    if duration is not None:
        cmd += ["-t", str(duration)]
    cmd += ["-y", out_path]

    proc = subprocess.Popen(cmd)
    rc = None
    try:
        rc = proc.wait()
    except KeyboardInterrupt:
        proc.send_signal(signal.SIGINT)
        try:
            rc = proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
            rc = proc.wait()
    # ffmpeg returns 0 on clean finish; -2/255 indicate a SIGINT stop, which is
    # the intended "stop recording" path. Anything else is a failed capture
    # (including a hard kill after the 10 s finalize window).
    if rc not in (0, -2, 255):
        print(f"[capture] ffmpeg exited with code {rc}", file=sys.stderr)
        raise RuntimeError(f"ffmpeg failed with code {rc}")
    return out_path


def main():
    ap = argparse.ArgumentParser(description="record mic + call audio into one wav")
    ap.add_argument("out")
    ap.add_argument("--seconds", type=float, default=None)
    args = ap.parse_args()
    record(args.out, args.seconds)


if __name__ == "__main__":
    main()
