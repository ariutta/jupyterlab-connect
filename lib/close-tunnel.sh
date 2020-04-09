#!/usr/bin/env bash

tunnel="$1"

jupyter_server_hostname="$(hostname)"

IFS=':' read -r -a tunnels_array <<< "$tunnel"
local_port="${tunnels_array[0]}"
remote_server_address="${tunnels_array[1]}"
remote_port="${tunnels_array[2]}"
if ls -1 /tmp/jlsession":$remote_server_address:"* >/dev/null 2>&1; then
  echo "Closing tunnel: $jupyter_server_hostname:$local_port <-> $remote_server_address:$remote_port"
  ssh -S /tmp/jlsession:%h:%p:%r -O exit "$remote_server_address" 2>/dev/null
fi
