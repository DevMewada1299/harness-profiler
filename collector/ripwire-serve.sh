#!/usr/bin/env bash
# Start Ripwire as a loopback Streamable-HTTP MCP server so TrueForge can use it
# as a connector. This is the "keep it ready" half: the user points it at their
# source tree, and TrueForge's `ripwire` connector talks to it over HTTP.
#
# Why HTTP and not stdio: TrueForge connectors are URL-only. Ripwire's default
# MCP transport is stdio, but `--listen=HOST:PORT` serves the same MCP over
# Streamable HTTP (implies --mcp), which is exactly what TrueForge expects.
#
# Why loopback only: no bearer token is required on 127.0.0.1, and edit verbs
# are refused unless --allow-remote-edits is passed. We keep it read-only.
#
# Usage:
#   collector/ripwire-serve.sh /abs/path/to/your/repo [PORT]
# Then (one-time) register the connector in TrueForge:
#   curl -s -X POST http://localhost:8790/api/v1/settings/mcp-servers \
#     -H 'Content-Type: application/json' \
#     -d '{"manifest":{"type":"remote","name":"ripwire",
#          "description":"Ripwire code-context MCP",
#          "url":"http://127.0.0.1:PORT/mcp"}}'
#
# NOTE: Ripwire indexes the HOST copy of the repo you point it at. A TrueForge
# agent editing inside its Daytona sandbox will NOT be reflected here until you
# restart against the updated tree. Ripwire's job is understand-before-edit
# context, so this is fine — just don't read it as live post-edit state.

set -euo pipefail

REPO="${1:?usage: ripwire-serve.sh /abs/path/to/repo [port]}"
PORT="${2:-9700}"
RIPWIRE_BIN="${RIPWIRE_BIN:-/private/tmp/ripwire/build-release/ripwire}"

if [[ ! -x "$RIPWIRE_BIN" ]]; then
  echo "ripwire binary not found at $RIPWIRE_BIN" >&2
  echo "build it: cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release && cmake --build build-release -j" >&2
  exit 1
fi

# stop any existing listener on this port
pkill -f "ripwire.*--listen=127.0.0.1:${PORT}" 2>/dev/null || true

echo "indexing + serving $REPO on http://127.0.0.1:${PORT}/mcp (loopback, read-only)"
exec "$RIPWIRE_BIN" "$REPO" --listen="127.0.0.1:${PORT}"
