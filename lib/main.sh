#!/usr/bin/env bash

# Created by argbash-init v2.8.1
# ARG_OPTIONAL_SINGLE([port],[p],[Port of Jupyter server],[8889])
# ARG_OPTIONAL_BOOLEAN([browser],[],[Open the notebook in a browser after startup.],[on])
# ARG_OPTIONAL_REPEATED([tunnel],[t],[<port on Jupyter server>:<remote server address>:<port on remote server>\n  Create an SSH tunnel. Can be specified multiple times to create multiple tunnels.\n  Example: Make a remote PostgreSQL server accessible to your Jupyter server:\n             -t 3333:database.example.org:5432\n],[])
# ARG_POSITIONAL_DOUBLEDASH([])
# ARG_POSITIONAL_SINGLE([target],[When Jupyter server is local, target defaults to pwd.\n    Example: cd ~/Documents/jupyterlab-demo && jupyterlab-connect\n    Example: jupyterlab-connect ~/Documents/jupyterlab-demo\n  When Jupyter server is remote, an ssh-style url is required.\n    Example: jupyterlab-connect example.org:Documents/jupyterlab-demo\n],[./])
# ARG_HELP([Connect to your Jupyter server])
# ARG_VERSION_AUTO([0.0.0])
# ARGBASH_GO()

# [ <-- needed because of Argbash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1

# Based on http://linuxcommand.org/lc3_wss0140.php
# and https://codeinthehole.com/tips/bash-error-reporting/
PROGNAME=$(basename "$0")

cleanup_complete=0

cleanup() {
  if [[ $connection_attempted -eq 1 ]]; then
    echo "******************************************"
    cleanup_msg="Disconnecting from Jupyter server"
    if [ "$SERVER_IS_REMOTE" ]; then
      echo "$cleanup_msg (remote)"
    else
      echo "$cleanup_msg (local)"
    fi
    echo "******************************************"

    if [ "$SERVER_IS_REMOTE" ]; then
      if ssh -qS "$ssh_control_path" -O check "$JUPYTER_SERVER_ADDRESS" 2>/dev/null; then
        ssh -S "$ssh_control_path" "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
          "$TARGET_DIR" "$port" <"$SCRIPT_DIR/jupyter-notebook-stop.sh"

        for tunnel in $tunnels; do
          ssh -S "$ssh_control_path" "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
            "$tunnel" "$ssh_control_path_expr" <"$SCRIPT_DIR/close-tunnel.sh"
        done

        ssh -qS "$ssh_control_path" -O exit "$JUPYTER_SERVER_ADDRESS"
      fi
    else
      sh "$SCRIPT_DIR/jupyter-notebook-stop.sh" "$TARGET_DIR" "$port"

      for tunnel in $tunnels; do
        sh "$SCRIPT_DIR/close-tunnel.sh" "$tunnel" "$ssh_control_path_expr"
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

# NOTE: we specify ssh_control_path_expr as a single-quoted expression so that
# we can pass it as an argument to open-tunnel.sh and close-tunnel.sh, even if
# they are executed on remote machines.
#
# If open-tunnel.sh and close-tunnel.sh are executed on a remote machine, we'll
# have a shared SSH connection on the remote machine and a different shared ssh
# connection on the local machine.
#
# If open-tunnel.sh and close-tunnel.sh are executed on the local machine, we'll
# re-use the existing shared SSH connection on the local machine.
ssh_control_path_expr='$HOME/.ssh/.jupyterlab-connect-control-socket:%h:%p:%r'
ssh_control_path="$(bash -c 'echo '"$ssh_control_path_expr")"
ssh_control_path_dir="$(dirname "$ssh_control_path")"
if [ ! -e "$ssh_control_path_dir" ]; then
  mkdir -p "$ssh_control_path_dir"
fi

############################################
# Make pretty names for args parsed by argbash
target="$_arg_target"
port="$_arg_port"
tunnels="$_arg_tunnel"
browser="$_arg_browser"
############################################

# ssh doesn't like '~' in the paths
ssh_safe_target=$(echo "$target" | sed 's/:~/:$HOME/')

# if input has a colon, assume target is referring to a remote Jupyter server
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
  echo "Connecting to Jupyter server on $JUPYTER_SERVER_ADDRESS (remote)"
  echo "for $ssh_safe_target"
else
  echo "Connecting to Jupyter server on $(hostname) (local)"
  echo "for $ssh_safe_target"
fi
echo "******************************************"

if [[ -z "$JUPYTER_SERVER_ADDRESS" ]]; then
  if direnv exec "$TARGET_DIR" jupyter-lab --version >/dev/null 2>&1; then
    token=$(bash "$SCRIPT_DIR/connect.sh" "$TARGET_DIR" "$port")
  else
    error_exit "jupyter-lab not installed locally. Did you mean to run on a remote server?
    Run $PROGNAME --help to see how to specify a remote server and target directory."
  fi
else
  # We only want to specify ControlMaster=yes the first time.
  if ssh -qS "$ssh_control_path" -O check "$JUPYTER_SERVER_ADDRESS" 2>/dev/null; then
    ControlMaster="no"
  else
    ControlMaster="yes"
  fi

  token=$(ssh -o ControlMaster="$ControlMaster" \
    -o ControlPersist=yes \
    -S "$ssh_control_path" \
    "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
    "$TARGET_DIR" "$port" <"$SCRIPT_DIR/connect.sh" ||
    connection_attempted=1)

  # TODO: could we use mosh for the tunnel?
  # related: https://github.com/mobile-shell/mosh/issues/24#issuecomment-303151487

  remote_hosts_controlled+=("$JUPYTER_SERVER_ADDRESS")

  echo ""
  echo "Opening tunnel to allow browser to connect to Jupyter server:"
  echo "localhost:$port on $(hostname) <-> $JUPYTER_SERVER_ADDRESS:$port"
  ssh -S "$ssh_control_path" -L "$port":localhost:"$port" -N -f "$JUPYTER_SERVER_ADDRESS"
  # -S: re-use existing ssh connection
  # -L: local port forwarding
  # -f: send to background
  # -N: don't issue any commands on remote server
fi

connection_attempted=1

if [[ -z "$token" ]] || [[ "$token" == 'null' ]]; then
  error_exit "No token found"
fi

url="http://localhost:$port/?token=$token"

for tunnel in $tunnels; do
  if [ $SERVER_IS_REMOTE ]; then
    ssh -S "$ssh_control_path" "$JUPYTER_SERVER_ADDRESS" 'bash -s' -- \
      "$tunnel" "$ssh_control_path_expr" <"$SCRIPT_DIR/open-tunnel.sh"
  else
    sh "$SCRIPT_DIR/open-tunnel.sh" "$tunnel" "$ssh_control_path_expr"
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
