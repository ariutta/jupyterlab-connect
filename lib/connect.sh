#!/usr/bin/env bash

OUTPUT_FILE=$(mktemp) || exit 1

TARGET_DIR="$(readlink -f "$1")"

jq_output_cmd='.port, .token'

if ! direnv exec "$TARGET_DIR" jupyter server list >/dev/null 2>&1; then
  # If we can't run this command, tell the user. Example: direnv not allowed.
  echo "Failed to get list of running servers" 1>&2
  # the following may replicate the error so the user can see it:
  direnv exec "$TARGET_DIR" jupyter server list 1>&2
elif direnv exec "$TARGET_DIR" jupyter server list --jsonlist 2>/dev/null |
  jq -e 'length > 0' >/dev/null; then

  echo "Jupyter server(s) already running" 1>&2
  echo "* for $TARGET_DIR" 1>&2

  jupyter_connection_details="$(direnv exec "$TARGET_DIR" jupyter server list --jsonlist 2>/dev/null | jq -r 'first')"

  port=$(echo "$jupyter_connection_details" | jq -r '.port')
  root_dir=$(echo "$jupyter_connection_details" | jq -r '.root_dir')

  normalized_root_dir="$(readlink -f "$root_dir")"
  normalized_target_dir="$(readlink -f "$TARGET_DIR")"

  if [[ "$normalized_root_dir" != "$normalized_target_dir" ]]; then
    echo "Normalized root_dir must match normalized TARGET_DIR, but '$normalized_root_dir' != '$normalized_target_dir'" 1>&2
    exit 1
  fi

  echo "* connecting to Jupyter server on port $port..." 1>&2
  echo "$jupyter_connection_details" | jq -r "$jq_output_cmd"
else
  BASE_SERVER_START_CMD="jupyter lab --no-browser"

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

  # NOTE: We wait until jupyter is running before we try getting the token.

  #############################################################################
  # Method #1 (deprecated): watch for the OUTPUT_FILE to contain a URL
  #############################################################################

  # An old commit where we were using this option:
  # https://github.com/ariutta/jupyterlab-connect/blob/5c67493f5c6e0920f554176c37e577395c998fa1/jupyterlab-launch#L124

  # Using perl:
  # watch -t -g '[[ -f '"$OUTPUT_FILE"' ]] && perl -ne "print if s/(^|.*?[ \"])(http.*?)([\" >].*|$)/\$2/"' "$OUTPUT_FILE"

  # Using grep (an alternative way of doing the same thing):
  # watch -t -g "[[ -f "$OUTPUT_FILE" ]] && grep -E '(^|.*?[ \"])(http.*?)([\" >].*|$)'" "$OUTPUT_FILE"

  #############################################################################
  # Method #2 (preferred): watch for 'jupyter server list' to show jupyter server running.
  #############################################################################

  (nohup direnv exec "$TARGET_DIR" sh -c "$server_start_cmd" >"$OUTPUT_FILE" 2>&1 &) &&
    watch -t -g 'direnv exec '"$TARGET_DIR"' jupyter server list' "$OUTPUT_FILE" >/dev/null &&
    direnv exec "$TARGET_DIR" jupyter server list --jsonlist 2>/dev/null |
    jq -r "first | $jq_output_cmd"

  # TODO: if the server ever finishes starting before the watch starts, the
  #       watch will never end, meaning the connection process will hang.
fi
