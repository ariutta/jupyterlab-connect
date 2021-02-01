#!/usr/bin/env bash

tunnel="$1"
ssh_control_path_expr="$2"
ssh_control_path="$(bash -c 'echo '"$ssh_control_path_expr")"
ssh_control_path_dir="$(dirname "$ssh_control_path")"
if [ ! -e "$ssh_control_path_dir" ]; then
  mkdir -p "$ssh_control_path_dir"
fi

jupyter_server_hostname="$(hostname)"

IFS=':' read -r -a tunnels_array <<<"$tunnel"
local_port="${tunnels_array[0]}"
remote_server_address="${tunnels_array[1]}"
remote_port="${tunnels_array[2]}"

if ssh -qS "$ssh_control_path" -O check "$remote_server_address" 2>/dev/null; then
  echo "Closing tunnel: $jupyter_server_hostname:$local_port <-> $remote_server_address:$remote_port"
  ssh -S "$ssh_control_path" -O exit "$remote_server_address" 2>/dev/null
else
  echo "Tunnel already closed: $jupyter_server_hostname:$local_port <-> $remote_server_address:$remote_port"
fi
