# Fuzzy find files in the current directory and open in Neovim.
f() {
  local files
  files=$(rg --files --hidden --glob '!.git' "${1:-.}" 2>/dev/null | fzf -m) || return
  [[ -n "$files" ]] && nvim "${files}"
}

# Daybook journal helpers.
_journal_open() {
  local day="${1:-$(date +%F)}"
  local heading
  heading="$(date -d "$day" '+%B %-d, %Y: %A')" || return 1

  local y="${day:0:4}"
  local m="${day:5:2}"
  local d="${day:8:2}"
  local file="$HOME/Development/daybook/journal/$y/$m/$d.md"
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
  nvim "$file"
}

p() {
  _journal_open
}

jd() {
  _journal_open "${1:-$(date +%F)}"
}

jy() {
  _journal_open "$(date -d yesterday +%F)"
}

jl() {
  local count="${1:-10}"
  find "$HOME/Development/daybook/journal" -type f -name '*.md' 2>/dev/null | sort -r | head -n "$count"
}
