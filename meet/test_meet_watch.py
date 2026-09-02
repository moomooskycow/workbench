import os
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from meet import meet


class WatchProcessedRecordingsTest(unittest.TestCase):
    def test_growing_recording_waits_for_quiet_window(self):
        class StopWatch(Exception):
            pass

        with tempfile.TemporaryDirectory() as tmp:
            inbox = Path(tmp)
            recording = inbox / "growing.wav"
            chunks = [b"first", b" second", b" final"]
            recording.write_bytes(chunks[0])
            base_mtime_ns = 1_000_000_000
            os.utime(recording, ns=(base_mtime_ns, base_mtime_ns))
            process_calls = []
            sleep_calls = 0
            clock = 0.0

            def monotonic():
                return clock

            def process(audio, _args, note_out=None):
                process_calls.append((sleep_calls, Path(audio).read_bytes()))

            def sleep(_interval):
                nonlocal clock, sleep_calls
                sleep_calls += 1
                if sleep_calls <= 2:
                    with recording.open("ab") as stream:
                        stream.write(chunks[sleep_calls])
                    timestamp = base_mtime_ns + sleep_calls * 1_000_000_000
                    os.utime(recording, ns=(timestamp, timestamp))
                    self.assertEqual(process_calls, [])
                elif sleep_calls == 3:
                    self.assertEqual(process_calls, [])
                else:
                    raise StopWatch
                clock += 2.0

            args = SimpleNamespace(dir=str(inbox), interval=0)
            with patch.object(meet, "_process_audio", side_effect=process), patch.object(
                meet.time, "monotonic", side_effect=monotonic
            ), patch.object(meet.time, "sleep", side_effect=sleep):
                with self.assertRaises(StopWatch):
                    meet.cmd_watch(args)

            self.assertEqual(
                process_calls,
                [(3, b"first second final")],
            )
            self.assertEqual(
                (inbox / "processed" / "growing.wav").read_bytes(),
                b"first second final",
            )

    def test_later_file_starts_quiet_window_after_prior_processing(self):
        class StopWatch(Exception):
            pass

        with tempfile.TemporaryDirectory() as tmp:
            inbox = Path(tmp)
            first = inbox / "a.wav"
            later = inbox / "b.wav"
            first.write_bytes(b"first")
            later.write_bytes(b"later")
            base_mtime_ns = 1_000_000_000
            os.utime(first, ns=(base_mtime_ns, base_mtime_ns))
            later_mtime_ns = base_mtime_ns + 1_000_000_000
            os.utime(later, ns=(later_mtime_ns, later_mtime_ns))
            process_calls = []
            sleep_calls = 0
            clock = 0.0

            def monotonic():
                return clock

            def process(audio, _args, note_out=None):
                nonlocal clock
                name = Path(audio).name
                process_calls.append((name, clock))
                if name == "a.wav":
                    clock += 10.0
                    later.write_bytes(b"later updated")
                    changed_mtime_ns = later_mtime_ns + 1_000_000_000
                    os.utime(later, ns=(changed_mtime_ns, changed_mtime_ns))

            def sleep(_interval):
                nonlocal clock, sleep_calls
                sleep_calls += 1
                if sleep_calls == 1:
                    self.assertEqual(process_calls, [])
                elif sleep_calls == 2:
                    clock += 0.1
                    self.assertEqual(process_calls, [("a.wav", 2.0)])
                    return
                elif sleep_calls == 3:
                    self.assertEqual(process_calls, [("a.wav", 2.0)])
                    clock += 1.9
                    return
                else:
                    raise StopWatch
                clock += 2.0

            args = SimpleNamespace(dir=str(inbox), interval=0)
            with patch.object(meet, "_process_audio", side_effect=process), patch.object(
                meet.time, "monotonic", side_effect=monotonic
            ), patch.object(meet.time, "sleep", side_effect=sleep):
                with self.assertRaises(StopWatch):
                    meet.cmd_watch(args)

            self.assertEqual(process_calls, [("a.wav", 2.0), ("b.wav", 14.0)])
            done = inbox / "processed"
            self.assertEqual((done / "a.wav").read_bytes(), b"first")
            self.assertEqual((done / "b.wav").read_bytes(), b"later updated")

    def test_same_named_recordings_keep_contents_and_names(self):
        class StopWatch(Exception):
            pass

        with tempfile.TemporaryDirectory() as tmp:
            inbox = Path(tmp)
            first = inbox / "meeting.wav"
            first.write_bytes(b"first recording")
            first_mtime_ns = first.stat().st_mtime_ns
            second = inbox / "meeting.wav"
            process_calls = []
            sleep_calls = 0
            clock = 0.0

            def monotonic():
                return clock

            def process(audio, _args, note_out=None):
                process_calls.append(Path(audio).read_bytes())

            def sleep(_interval):
                nonlocal clock, sleep_calls
                sleep_calls += 1
                if sleep_calls == 1:
                    self.assertEqual(process_calls, [])
                elif sleep_calls == 2:
                    second.write_bytes(b"second recording")
                    second_mtime_ns = first_mtime_ns + 1_000_000_000
                    os.utime(second, ns=(second_mtime_ns, second_mtime_ns))
                    self.assertNotEqual(second.stat().st_mtime_ns, first_mtime_ns)
                elif sleep_calls == 3:
                    self.assertEqual(process_calls, [b"first recording"])
                else:
                    raise StopWatch
                clock += 2.0

            args = SimpleNamespace(dir=str(inbox), interval=0)
            with patch.object(meet, "_process_audio", side_effect=process), patch.object(
                meet.time, "monotonic", side_effect=monotonic
            ), patch.object(meet.time, "sleep", side_effect=sleep):
                with self.assertRaises(StopWatch):
                    meet.cmd_watch(args)

            done = inbox / "processed"
            free_destination = done / "meeting.wav"
            occupied_destination = done / "meeting-2.wav"
            self.assertEqual(free_destination.read_bytes(), b"first recording")
            self.assertEqual(occupied_destination.read_bytes(), b"second recording")
            self.assertEqual(process_calls, [b"first recording", b"second recording"])
            self.assertEqual(
                sorted(path.name for path in done.iterdir()),
                ["meeting-2.wav", "meeting.wav"],
            )
