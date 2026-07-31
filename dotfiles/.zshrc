# Environment (PATH, DEVELOPMENT, tool homes). Keep this before interactive tools.
[[ -r "$HOME/.env" ]] && source "$HOME/.env"

# Completion
fpath=(/usr/share/zsh/vendor-completions $fpath)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt append_history inc_append_history share_history extended_history
setopt hist_ignore_all_dups hist_find_no_dups hist_reduce_blanks hist_verify

# Interactive tools
export EDITOR=nvim
export VISUAL=nvim
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'

(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
if [[ "$TERM" != dumb ]]; then
  [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -r /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
  (( $+commands[starship] )) && eval "$(starship init zsh)"
fi

[[ -r "$HOME/.aliases" ]] && source "$HOME/.aliases"
[[ -r "$HOME/.fun" ]] && source "$HOME/.fun"

# Keep syntax highlighting last.
[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
