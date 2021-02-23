#!/usr/bin/env bash

TARGET_DIR="$(readlink -f "$1")"
port="$2"

direnv exec "$TARGET_DIR" jupyter server stop $port 2>/dev/null
