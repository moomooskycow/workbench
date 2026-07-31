# Side-effect-free environment for login, interactive, and GUI-launched shells.
typeset -U path PATH
path=("$HOME/.local/bin" $path)

if [[ -S "$HOME/.1password/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi

docker_socket="${XDG_RUNTIME_DIR:-/run/user/$UID}/docker.sock"
if [[ -S "$docker_socket" ]]; then
  export DOCKER_HOST="unix://$docker_socket"
fi
unset docker_socket

# Agent harnesses (omp bash tool, CI-styled runners) inject CI=1 into tool
# shells, which disables qmd's local LLM ops (query expansion, rerank).
# This is a workstation, not CI — let inherited qmd calls keep LLM ops.
export QMD_LLM_IN_CI=1
