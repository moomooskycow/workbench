#!/usr/bin/env bash
# pair.sh — non-blocking discovery, pairing, and connection verification for Bose headphones
set -euo pipefail

notify() {
  local title="$1"
  local msg="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Headphone Battery" -i "audio-headphones" "$title" "$msg" || true
  fi
}

# Ensure bluetooth is powered on
if command -v omarchy-bluetooth-power >/dev/null 2>&1; then
  omarchy-bluetooth-power on || true
else
  bluetoothctl power on >/dev/null 2>&1 || true
fi

notify "Bluetooth Pairing" "Scanning for Bose QuietComfort headphones (12s)…\nPlease hold the Bluetooth button on your headphones until the light blinks blue."

scan_result=$(python3 - <<'EOF'
import subprocess, select, time, os, fcntl, re, sys

proc = subprocess.Popen(['bluetoothctl'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
proc.stdin.write('scan on\n')
proc.stdin.flush()

fd = proc.stdout.fileno()
fl = fcntl.fcntl(fd, fcntl.F_GETFL)
fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)

start = time.time()
deadline = 12.0
found_mac = None
found_name = None

while time.time() - start < deadline:
    r, _, _ = select.select([fd], [], [], 0.3)
    if r:
        try:
            line = proc.stdout.readline()
            if not line:
                break
            lower = line.lower()
            if any(k in lower for k in ['bose', 'quietcomfort', 'qc ultra', 'qc_ultra', 'wolverine']):
                m = re.search(r'([0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5})', line)
                if m:
                    found_mac = m.group(1)
                    found_name = line.strip()
                    break
        except Exception:
            break

try:
    proc.stdin.write('scan off\nexit\n')
    proc.stdin.flush()
    proc.terminate()
except Exception:
    pass

if found_mac:
    print(f"MATCH:{found_mac}:{found_name}")
else:
    print("TIMEOUT")
EOF
)

if [[ "$scan_result" != MATCH:* ]]; then
  notify "Pairing Timed Out" "Could not find Bose headphones in pairing mode.\nHold the Bluetooth button until the LED blinks blue and try again."
  exit 1
fi

matched_mac=$(echo "$scan_result" | cut -d':' -f2-7)
matched_name=$(echo "$scan_result" | cut -d':' -f8-)

notify "Bose Headphones Detected" "Connecting to $matched_mac…"

# Attempt pairing and connection
pair_status=0
if command -v omarchy-bluetooth-device >/dev/null 2>&1; then
  omarchy-bluetooth-device pair "$matched_mac" || pair_status=$?
else
  (
    bluetoothctl pair "$matched_mac"
    bluetoothctl trust "$matched_mac"
    bluetoothctl connect "$matched_mac"
  ) || pair_status=$?
fi

# Verify actual BlueZ connection state via D-Bus
dev_path="/org/bluez/hci0/dev_${matched_mac//:/_}"
is_connected="false"

# Poll connection for up to 5 seconds
for (( i = 0; i < 10; i++ )); do
  conn_val=$(busctl get-property org.bluez "$dev_path" org.bluez.Device1 Connected 2>/dev/null | awk '{print $2}' || true)
  if [[ "$conn_val" == "true" ]]; then
    is_connected="true"
    break
  fi
  sleep 0.5
done

if [[ "$is_connected" != "true" ]]; then
  notify "Connection Failed" "Could not connect to $matched_mac (exit code: $pair_status). Please ensure headphones are in pairing mode and try again."
  exit 1
fi

# Connection verified! Check if Battery1 telemetry is already populated
batt_val=$(busctl get-property org.bluez "$dev_path" org.bluez.Battery1 Percentage 2>/dev/null | awk '{print $2}' || true)

if [[ -n "$batt_val" && "$batt_val" =~ ^[0-9]+$ ]]; then
  notify "Bose Headphones Connected" "Bluetooth connected with $batt_val% battery reported."
else
  notify "Bose Headphones Connected" "Bluetooth connected! Waiting for battery telemetry to sync."
fi

exit 0
