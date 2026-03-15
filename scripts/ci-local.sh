#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Local CI: Zig build and smoke tests"

if ! command -v zig >/dev/null 2>&1; then
  echo "error: zig is not installed or not in PATH" >&2
  exit 1
fi

echo "==> fetching zig version"
zig version

echo "==> running tests"
zig build test

echo "==> running version"
zig build run -- version

echo "==> running help"
zig build run -- help

echo "==> running doctor"
zig build run -- doctor

echo "==> running deploy --no-push"
zig build run -- deploy --no-push

echo "==> Local CI: Build release artifacts"
chmod +x scripts/build-release.sh
./scripts/build-release.sh

if [[ "${SKIP_ELIXIR:-0}" == "1" ]]; then
  echo "==> Skipping hosted Elixir compile check (SKIP_ELIXIR=1)"
  exit 0
fi

echo "==> Local CI: Hosted control API compile and Credo check"

if ! command -v mix >/dev/null 2>&1; then
  echo "error: mix is not installed or not in PATH (set SKIP_ELIXIR=1 to skip)" >&2
  exit 1
fi

pushd hosted/control_api >/dev/null
mix deps.get
mix compile --warnings-as-errors
mix credo --strict
popd >/dev/null

echo "==> Local CI completed successfully"

