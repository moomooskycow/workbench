# Fuzzy find files in the current directory and open in Neovim.
f() {
  local files
  files=$(rg --files --hidden --glob '!.git' "${1:-.}" 2>/dev/null | fzf -m) || return
  [[ -n "$files" ]] && nvim "${files}"
}

# Daybook journal helpers.
_journal_open() {
  local day="${1:-$(date +%F)}"
  local append_ts="${2:-false}"
  local heading
  heading="$(date -d "$day" '+%B %-d, %Y: %A')" || return 1

  local y="${day:0:4}"
  local m="${day:5:2}"
  local d="${day:8:2}"
  local file="$HOME/development/moomooskycow/daybook/journal/$y/$m/$d.md"
  mkdir -p "$(dirname "$file")"
  if [[ ! -e "$file" ]]; then
    cat > "$file" <<EOF
---
type: journal
created: $(date -Iseconds)
tags: [journal]
---

# $heading
EOF
  fi

  local nvim_args=()
  if [[ "$append_ts" == "true" ]]; then
    printf '\n\n## %s\n\n' "$(date +%T)" >> "$file"
    nvim_args=(+)
  fi

  NVIM_APPNAME=nvim-prose nvim "${nvim_args[@]}" "$file"
}

p() {
  _journal_open "$(date +%F)" true
}

jd() {
  _journal_open "${1:-$(date +%F)}" false
}

jy() {
  _journal_open "$(date -d yesterday +%F)" false
}

jl() {
  local count="${1:-10}"
  find "$HOME/development/moomooskycow/daybook/journal" -type f -name '*.md' 2>/dev/null | sort -r | head -n "$count"
}
