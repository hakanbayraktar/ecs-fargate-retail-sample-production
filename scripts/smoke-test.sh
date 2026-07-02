#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <base-url>"
  exit 1
fi

base_url="${1%/}"

curl -fsS "$base_url" >/dev/null

