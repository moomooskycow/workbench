#!/usr/bin/env bash
# status.sh — detects headphone status across USB, Bluetooth, and sysfs
set -euo pipefail

usb_connected=false
usb_name=""
usb_vendor=""
usb_product=""
usb_serial=""

# Scan sysfs for known USB headphones (e.g. Bose 05a7:4082)
for dev in /sys/bus/usb/devices/*; do
  if [[ -f "$dev/idVendor" && -f "$dev/idProduct" ]]; then
    v=$(cat "$dev/idVendor" 2>/dev/null || true)
    p=$(cat "$dev/idProduct" 2>/dev/null || true)
    if [[ "$v" == "05a7" && "$p" == "4082" ]]; then
      usb_connected=true
      usb_name=$(cat "$dev/product" 2>/dev/null || echo "Bose QC Ultra 2")
      usb_vendor="$v"
      usb_product="$p"
      usb_serial=$(cat "$dev/serial" 2>/dev/null || true)
      break
    fi
  fi
done

# Check bluetooth battery via bluez dbus
bt_connected=false
bt_name=""
bt_battery=-1

# Read all bluez devices with Battery1 interface
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    dev_path=$(echo "$line" | awk '{print $1}')
    pct=$(busctl get-property org.bluez "$dev_path" org.bluez.Battery1 Percentage 2>/dev/null | awk '{print $2}' || true)
    alias=$(busctl get-property org.bluez "$dev_path" org.bluez.Device1 Alias 2>/dev/null | cut -d'"' -f2 || true)
    conn=$(busctl get-property org.bluez "$dev_path" org.bluez.Device1 Connected 2>/dev/null | awk '{print $2}' || true)
    if [[ "$conn" == "true" ]]; then
      bt_connected=true
      bt_name="$alias"
      if [[ -n "$pct" && "$pct" =~ ^[0-9]+$ ]]; then
        bt_battery=$pct
      fi
      break
    fi
  fi
done < <(busctl tree org.bluez 2>/dev/null | grep -E "dev_" || true)

cat <<EOF
{
  "usbConnected": $usb_connected,
  "usbName": "$usb_name",
  "usbVendor": "$usb_vendor",
  "usbProduct": "$usb_product",
  "usbSerial": "$usb_serial",
  "btConnected": $bt_connected,
  "btName": "$bt_name",
  "btBattery": $bt_battery
}
EOF
