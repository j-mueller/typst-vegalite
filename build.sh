#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd -- "${project_dir}"
nix flake check --print-build-logs
exec nix build .#nulite "$@"
