#!/bin/bash
# Switch Hyprland xkb layout on real keyboards only.
# Omarchy's layout widget warns that `switchxkblayout all` also advances
# power/lid/video devices, which then steal the bar label.
cmd="${1:-}"
case "$cmd" in
  0 | 1 | next | prev) ;;
  *)
    echo "usage: $0 0|1|next|prev" >&2
    exit 2
    ;;
esac

mapfile -t names < <(hyprctl -j devices | jq -r '.keyboards[].name')
for name in "${names[@]}"; do
  case "$name" in
    hl-virtual-keyboard* | power-button* | sleep-button* | lid-switch* | video-bus*)
      continue
      ;;
  esac
  hyprctl switchxkblayout "$name" "$cmd" >/dev/null
done

# Xwayland side: X11 games under Proton (e.g. StarCraft II) read the X
# server's own xkb config, which is independent of Hyprland's keyboard
# state. In game layout (1) pin the X server to US QWERTY so the game
# sees standard keys. In layout 0 leave X as-is (US is fine there too).
if [ "$cmd" = "1" ]; then
  xdisplay=$(pgrep -a Xwayland 2>/dev/null | head -n1 | awk '{print $3}')
  if [ -n "$xdisplay" ] && command -v setxkbmap >/dev/null 2>&1; then
    DISPLAY="$xdisplay" setxkbmap -layout us -variant "" 2>/dev/null || true
  fi
fi
