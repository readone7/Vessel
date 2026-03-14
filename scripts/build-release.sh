#!/usr/bin/env bash
set -euo pipefail

echo "Building Vessel release artifacts..."
zig build -Doptimize=ReleaseSafe

mkdir -p dist
cp zig-out/bin/vessel dist/
cp zig-out/bin/vesseld dist/
cp zig-out/bin/vegistry dist/

shasum -a 256 dist/vessel dist/vesseld dist/vegistry > dist/SHA256SUMS
echo "Release artifacts created in dist/"

