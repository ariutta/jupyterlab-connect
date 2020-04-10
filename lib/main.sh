#!/usr/bin/env bash

# Created by argbash-init v2.8.1
# ARG_OPTIONAL_SINGLE([port],[p],[Port of jupyter server],[8889])
# ARG_OPTIONAL_BOOLEAN([browser],[],[Open the notebook in a browser after startup.],[on])
# ARG_OPTIONAL_REPEATED([tunnel],[t],[<port on jupyter server>:<remote server address>:<port on remote server>\n  Tunnel to create, e.g., to connect to a remote database server.\n  Example: 3333:wikipathways-workspace:5432],[])
# ARG_POSITIONAL_DOUBLEDASH([])
# ARG_POSITIONAL_SINGLE([target],[When jupyter server is local, target defaults to pwd.\n  When jupyter server is remote, an ssh-style url is required, e.g.:\n   jupyterlab-connect nixos.gladstone.internal:code/jupyterlab-demo],[./])
# ARG_HELP([Connect to your jupyterlab server])
# ARG_VERSION_AUTO([0.0.0])
# ARGBASH_GO()

# [ <-- needed because of Argbash

# see https://stackoverflow.com/a/246128/5354298
get_script_dir() { echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
SCRIPT_DIR=$(get_script_dir)

# Based on http://linuxcommand.org/lc3_wss0140.php
# and https://codeinthehole.com/tips/bash-error-reporting/
PROGNAME=$(basename "$0")

cleanup_complete=0

cleanup() {
  if [[ $jupyterlab_started -eq 1 ]]; then
    echo "******************************************"
    cleanup_msg="Disconnecting from jupyter server"
    if [ $SERVER_IS_REMOTE ]; then
      echo "$cleanup_msg (remote)"
    else
      echo "$cleanup_msg (local)"
    fi
    echo "******************************************"

    if [ $SERVER_IS_REMOTE ]; then
      # TODO: how do we get the actual name of the session file?
      # something approx. like this:
      # ls -1 /tmp/jlsession:remote-address:port:username

      if ls -1 /tmp/jlsession":$JUPYTER_SERVER_ADDRESS:"* >/dev/null 2>&1; then
        ssh -S /tmp/jlsession:%h:%p:%r "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
          < "$SCRIPT_DIR/../lib/jupyter-notebook-stop.sh" "$TARGET_DIR" "$port"
        for t in $tunnels; do
          ssh -S /tmp/jlsession:%h:%p:%r "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
            < "$SCRIPT_DIR/../lib/close-tunnel.sh" "$tunnel"
        done
        ssh -S /tmp/jlsession:%h:%p:%r -O exit "$JUPYTER_SERVER_ADDRESS" \
          2>/dev/null
      fi
    else
      sh "$SCRIPT_DIR/../lib/jupyter-notebook-stop.sh" "$TARGET_DIR" $port

      for tunnel in $tunnels; do
        sh "$SCRIPT_DIR/../lib/close-tunnel.sh" "$tunnel"
      done
    fi

    echo "$PROGNAME: goodbye"
  fi

  cleanup_complete=1
}

error_exit() {
#	----------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	----------------------------------------------------------------

  read -r line file <<<"$(caller)"
  echo "" 1>&2
  echo "ERROR: file $file, line $line" 1>&2
  if [ ! "$1" ]; then
    sed "${line}q;d" "$file" 1>&2
  else
    echo "${1:-"Unknown Error"}" 1>&2
  fi
  echo "" 1>&2

  # TODO: should error_exit call cleanup?
  #       The EXIT trap already calls cleanup, so
  #       calling it here means calling it twice.
  if [ ! $cleanup_complete ]; then
    cleanup
  fi
  exit 1
}

trap error_exit ERR
trap cleanup EXIT INT QUIT TERM

############################################
# Make pretty names for args parsed by argbash
target="$_arg_target"
port="$_arg_port"
tunnels="$_arg_tunnel"
browser="$_arg_browser"
############################################

# ssh doesn't like '~' in the paths
ssh_safe_target=$(echo "$target" | sed 's/:~/:$HOME/')

# if input has a colon, assume target is referring to a remote jupyter server
if [[ "$ssh_safe_target" == *":"* ]]; then
  SERVER_IS_REMOTE=1
  JUPYTER_SERVER_ADDRESS="${ssh_safe_target%:*}"
  TARGET_DIR="${ssh_safe_target##*:}"
else
  TARGET_DIR="$ssh_safe_target"
fi

token=""

remote_hosts_controlled=()

echo "******************************************"
if [ $SERVER_IS_REMOTE ]; then
  echo "Connecting to jupyter server on $JUPYTER_SERVER_ADDRESS (remote)"
  echo "for $ssh_safe_target"
else
  echo "Connecting to jupyter server on $(hostname) (local)"
  echo "for $ssh_safe_target"
fi
echo "******************************************"

if [[ -z "$JUPYTER_SERVER_ADDRESS" ]]; then
  if direnv exec "$TARGET_DIR" jupyter-lab --version >/dev/null 2>&1; then
    token=$(bash "$SCRIPT_DIR/../lib/connect.sh" "$TARGET_DIR" "$port")
  else
    error_exit "jupyter-lab not installed locally. Did you mean to run on a remote server?
    Run $PROGNAME --help to see how to specify a remote server and target directory."
  fi
else
  token=$(ssh -o ControlMaster=yes -o ControlPersist=yes \
    -S /tmp/jlsession:%h:%p:%r "$JUPYTER_SERVER_ADDRESS" \
    'bash -s' -- < "$SCRIPT_DIR/../lib/connect.sh" "$TARGET_DIR" "$port")

  # TODO: could we use mosh for the tunnel?
  # related: https://github.com/mobile-shell/mosh/issues/24#issuecomment-303151487

  remote_hosts_controlled+=("$JUPYTER_SERVER_ADDRESS")

  echo ""
  echo "Opening tunnel to allow browser to connect to jupyter server:"
  echo "localhost:$port on $(hostname) <-> $JUPYTER_SERVER_ADDRESS:$port"  
  ssh -S /tmp/jlsession:%h:%p:%r -L $port:localhost:$port -N -f "$JUPYTER_SERVER_ADDRESS"
  # -S: re-use existing ssh connection
  # -L: local port forwarding
  # -f: send to background
  # -N: don't issue any commands on remote server
fi

jupyterlab_started=1

if [[ -z "$token" ]] || [[ "$token" == 'null' ]]; then
  error_exit "No token found"
fi

url="http://localhost:$port/?token=$token"

for tunnel in $tunnels; do
  if [ $SERVER_IS_REMOTE ]; then
    ssh -S /tmp/jlsession:%h:%p:%r "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
      < "$SCRIPT_DIR/../lib/open-tunnel.sh" "$tunnel"
  else
    sh "$SCRIPT_DIR/../lib/open-tunnel.sh" "$tunnel"
  fi
done

echo ""
to_view_msg="To view the notebook, visit:\n   $url"
if [ "$browser" == 'on' ]; then
  if xdg-open --version >/dev/null 2>&1; then
    # NixOS
    xdg-open "$url"
  elif which open >/dev/null 2>&1; then
    # macOS
    open "$url"
  else
    echo -e "Not sure how to open browser. $to_view_msg"
  fi
else
  echo -e "$to_view_msg"
fi

echo ""
read -rp "To quit, hit Enter"
echo ""

# ] <-- needed because of Argbash
