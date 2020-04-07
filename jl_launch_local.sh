#!/usr/bin/env bash

OUTPUT_FILE=$(mktemp) || exit 1

TARGET_DIR="$(readlink -f "$1")"
port="$2"

# Note: --arg always makes strings, so we need to convert '.port' (in the JSON) from number to string to match
if direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist | jq -e --arg port $port 'map(select((.port | tostring) == $port)) | length > 0' >/dev/null; then

  notebook_dir="$(direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist | jq -r --arg port $port 'map(select((.port | tostring) == $port)) | first | .notebook_dir')"

  if [[ "$(readlink -f "$notebook_dir")" == "$TARGET_DIR" ]]; then
    echo "Port $port already started." >/dev/stderr
    token=$(direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist | jq -r --arg port $port 'map(select((.port | tostring) == $port)) | first | .token')
    echo "$token"
    exit 0
  else
    echo "Port $port already in use. Please specify an unused port and try again."
    exit 1
  fi
fi

BASE_SERVER_START_CMD="jupyter lab --no-browser --port=$port"
server_start_cmd=""

# Limiting memory available to the process.
# Doing this will avoid OOM errors that can crash the system.
memory_free="$(free -g | awk '/Mem:/ { print $4 }')";
memory_available="$(free -g | awk '/Mem:/ { print $7 }')";
jupyterlab_memory_limit="$(echo "($memory_free + $memory_available) / 3" | bc)";

if $(systemd-run --version >/dev/null 2>&1); then
  server_start_cmd="systemd-run --user --scope -p MemoryLimit=$jupyterlab_memory_limit'G' $BASE_SERVER_START_CMD"
else
  server_start_cmd="$BASE_SERVER_START_CMD"
fi

# TODO: DRY this up. See section for when jupyter server already running.
token=$((nohup direnv exec "$TARGET_DIR" sh -c "$server_start_cmd" >"$OUTPUT_FILE" 2>&1 &) && \
  watch -d -t -g ls -lR "$OUTPUT_FILE" >/dev/null && \
  direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist | \
    jq -r --arg port $port 'map(select((.port | tostring) == $port)) | first | .token')

echo "$token"

exit 0
