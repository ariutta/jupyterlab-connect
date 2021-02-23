#!/usr/bin/env bash

TARGET_DIR="$(readlink -f "$1")"
port="$2"

# TODO: is there a way to avoid repeating this in connect.sh and jupyter-server-stop.sh?
# Determine whether to use jupyter server, jupyter notebook or something else
if direnv exec "$TARGET_DIR" jupyter-server --version >/dev/null 2>&1; then
  JUPYTER_BACKEND="direnv exec "$TARGET_DIR" jupyter-server"
elif direnv exec "$TARGET_DIR" jupyter-notebook --version >/dev/null 2>&1; then
  JUPYTER_BACKEND="direnv exec "$TARGET_DIR" jupyter-notebook"
else
    echo "Could call neither jupyter-server nor jupyter-notebook" >&2
    echo "jupyter-server --version:" >&2
    direnv exec "$TARGET_DIR" jupyter-server --version
    echo "jupyter-notebook --version:" >&2
    direnv exec "$TARGET_DIR" jupyter-notebook --version
    echo "Add a JUPYTER_BACKEND to lib/connect.sh and lib/jupyter-server-stop.sh" >&2
    exit 1
fi

sh -c "$JUPYTER_BACKEND"' stop '"$port" 2>/dev/null
