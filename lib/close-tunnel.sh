#!/usr/bin/env bash

tunnel="$1"

jupyter_server_hostname="$(hostname)"
ssh_control_path="$HOME/.ssh/.jupyterlab-connect-control-socket:%h:%p:%r"

IFS=':' read -r -a tunnels_array <<<"$tunnel"
local_port="${tunnels_array[0]}"
remote_server_address="${tunnels_array[1]}"
remote_port="${tunnels_array[2]}"

if ssh -qS "$ssh_control_path" -O check "$remote_server_address" 2>/dev/null; then
  echo "Closing tunnel: $jupyter_server_hostname:$local_port <-> $remote_server_address:$remote_port"
  ssh -S "$ssh_control_path" -O exit "$remote_server_address" 2>/dev/null
fi
