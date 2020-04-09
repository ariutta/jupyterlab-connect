#!/usr/bin/env bash

tunnel="$1"

jupyter_server_hostname="$(hostname)"

IFS=':' read -r -a tunnels_array <<< "$tunnel"
local_port="${tunnels_array[0]}"
remote_server_address="${tunnels_array[1]}"
remote_port="${tunnels_array[2]}"

echo ""
echo "Opening tunnel to connect jupyter server host and external service:"
echo "$jupyter_server_hostname:$local_port on $jupyter_server_hostname <-> $remote_server_address:$remote_port"

# If this is a tunnel to database remote from the jupyter server, you can
# access it in jupyterlab via a URI like this:
#   postgres://localhost:3333/pfocr
# You don't need a tunnel for a database on the jupyter server. You can always
# connect to it like this:
#   postgres:///pfocr20200224

# TODO: if there's a password prompt, the code below won't handle it.

# TODO: We only want to specify ControlMaster=yes the first time, but passing
# $control_params as a variable as below doesn't work.
#control_params=""
#if ! ls -1 /tmp/jlsession":$remote_server_address:"* >/dev/null 2>&1; then
#  control_params="-o ControlMaster=yes -o ControlPersist=yes"
#fi
#ssh "$control_params" -S /tmp/jlsession:%h:%p:%r -L $local_port:localhost:$remote_port -N -f "$remote_server_address"

if ls -1 /tmp/jlsession":$remote_server_address:"* >/dev/null 2>&1; then
  ssh -S /tmp/jlsession:%h:%p:%r -L $local_port:localhost:$remote_port -N -f "$remote_server_address"
else
  ssh -o ControlMaster=yes -o ControlPersist=yes -S /tmp/jlsession:%h:%p:%r -L $local_port:localhost:$remote_port -N -f "$remote_server_address"
fi
