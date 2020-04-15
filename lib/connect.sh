#!/usr/bin/env bash

OUTPUT_FILE=$(mktemp) || exit 1

TARGET_DIR="$(readlink -f "$1")"
port="$2"

# TODO: DRY this up. There's duplicated for code in here, e.g., for getting the
# token for a jupyter server running on a given port.

# Note: --arg always makes strings, so we need to convert '.port' (in the JSON) from number
# to string in order to match

if ! direnv exec "$TARGET_DIR" jupyter notebook list >/dev/null 2>&1; then
  # If we can't run this command, tell the user. Example: direnv not allowed.
  echo "Failed to get list of running notebooks" >/dev/stderr
  direnv exec "$TARGET_DIR" jupyter notebook list >/dev/stderr 1>&2
elif direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist 2>/dev/null |
  jq -e --arg port "$port" 'map(select((.port | tostring) == $port)) | length > 0' \
    >/dev/null; then

  notebook_dir="$(direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist 2>/dev/null |
    jq -r --arg port "$port" 'map(select((.port | tostring) == $port)) | first | .notebook_dir')"

  if [[ "$(readlink -f "$notebook_dir")" == "$TARGET_DIR" ]]; then
    echo "Jupyter server on Port $port already running." >/dev/stderr
    token=$(direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist 2>/dev/null |
      jq -r --arg port "$port" 'map(select((.port | tostring) == $port)) | first | .token')
    echo "$token"
  else
    echo "Port $port already in use. Please specify an unused port and try again." >/dev/stderr
  fi
else
  BASE_SERVER_START_CMD="jupyter lab --no-browser --port=$port"
  server_start_cmd=""

  # Limiting memory available to the process.
  # Doing this will avoid OOM errors that can crash the system.
  memory_free="$(free -g | awk '/Mem:/ { print $4 }')"
  memory_available="$(free -g | awk '/Mem:/ { print $7 }')"
  jupyterlab_memory_limit="$(echo "($memory_free + $memory_available) / 3" | bc)"

  if systemd-run --version >/dev/null 2>&1; then
    server_start_cmd="systemd-run --user --scope -p MemoryLimit=$jupyterlab_memory_limit'G' $BASE_SERVER_START_CMD"
  else
    server_start_cmd="$BASE_SERVER_START_CMD"
  fi

  # NOTE: We need to wait until jupyter is running before trying to get the token.
  # Previously, we watched for the OUTPUT_FILE to contain a URL.
  # https://github.com/ariutta/jupyterlab-connect/blob/5c67493f5c6e0920f554176c37e577395c998fa1/jupyterlab-launch#L124
  # watch -t -g '[[ -f '"$OUTPUT_FILE"' ]] && perl -ne "print if s/(^|.*?[ \"])(http.*?)([\" >].*|$)/\$2/"' "$OUTPUT_FILE"
  # an alternative way of doing the same thing:
  # watch -t -g "[[ -f "$OUTPUT_FILE" ]] && grep -E '(^|.*?[ \"])(http.*?)([\" >].*|$)'" "$OUTPUT_FILE"

  token=$( (nohup direnv exec "$TARGET_DIR" sh -c "$server_start_cmd" >"$OUTPUT_FILE" 2>&1 &) &&
    watch -t -g 'direnv exec '"$TARGET_DIR"' jupyter notebook list' "$OUTPUT_FILE" >/dev/null &&
    direnv exec "$TARGET_DIR" jupyter notebook list --jsonlist 2>/dev/null |
    jq -r --arg port "$port" 'map(select((.port | tostring) == $port)) | first | .token')

  echo "$token"
fi
