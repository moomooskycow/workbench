# Fuzzy find files in the current directory and open in Neovim.
f() {
  local -a files
  files=("${(@f)$(rg --files --hidden --glob '!.git' "${1:-.}" 2>/dev/null | fzf -m)}") || return
  [[ ${#files[@]} -gt 0 && -n "${files[1]}" ]] && nvim -- "${files[@]}"
}

# Daybook journal helpers.
_journal_open() {
  local day="${1:-$(date +%F)}"
  local heading
  heading="$(date -d "$day" '+%B %-d, %Y: %A')" || return 1

  local file="$HOME/Development/daybook/journal/${day[1,4]}/${day[6,7]}/${day[9,10]}.md"
  mkdir -p "${file:h}"
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
  command find "$HOME/Development/daybook/journal" -type f -name '*.md' | sort -r | command head -n "$count"
}
