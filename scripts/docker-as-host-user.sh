#!/usr/bin/env bash
set -euo pipefail

DOCKER_BIN="${DOCKER_BIN:-docker}"

if [ "${1:-}" = "run" ]; then
  shift
  exec "$DOCKER_BIN" run --user "$(id -u):$(id -g)" \
    -e CARGO_HOME=/tmp/nxvk-cargo \
    -e XDG_CACHE_HOME=/tmp/nxvk-cache \
    -e PATH=/opt/rust/cargo/bin:/opt/devkitpro/tools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$@"
fi

exec "$DOCKER_BIN" "$@"
