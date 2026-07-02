#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/smoke-test.sh <base-url> [mode]

Modes:
  ui-only      Basic public UI reachability check
  ui-backends  UI reachability plus backend health endpoint checks

Environment variables for backend checks:
  CATALOG_HEALTHCHECK_URL
  CART_HEALTHCHECK_URL
  CHECKOUT_HEALTHCHECK_URL
  ORDERS_HEALTHCHECK_URL
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

base_url="${1%/}"
mode="${2:-ui-only}"

check_url() {
  local label="$1"
  local url="$2"

  echo "checking ${label}: ${url}"
  curl -fsS "$url" >/dev/null
}

check_url "ui" "$base_url"

case "$mode" in
  ui-only)
    ;;
  ui-backends)
    [[ -n "${CATALOG_HEALTHCHECK_URL:-}" ]] && check_url "catalog" "$CATALOG_HEALTHCHECK_URL"
    [[ -n "${CART_HEALTHCHECK_URL:-}" ]] && check_url "cart" "$CART_HEALTHCHECK_URL"
    [[ -n "${CHECKOUT_HEALTHCHECK_URL:-}" ]] && check_url "checkout" "$CHECKOUT_HEALTHCHECK_URL"
    [[ -n "${ORDERS_HEALTHCHECK_URL:-}" ]] && check_url "orders" "$ORDERS_HEALTHCHECK_URL"
    ;;
  *)
    echo "unsupported mode: ${mode}"
    exit 1
    ;;
esac

