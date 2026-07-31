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
