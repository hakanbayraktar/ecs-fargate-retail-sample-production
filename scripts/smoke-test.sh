#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/smoke-test.sh <base-url> [mode]

Modes:
  ui-only      Basic public UI reachability check
  ui-backends  UI reachability plus backend health endpoint checks
  backend-only Backend health endpoint checks only

Environment variables for backend checks:
  CATALOG_HEALTHCHECK_URL
  CART_HEALTHCHECK_URL
  CHECKOUT_HEALTHCHECK_URL
  ORDERS_HEALTHCHECK_URL

Optional environment variables:
  SMOKE_RETRIES
  SMOKE_RETRY_DELAY_SECONDS
  SMOKE_TIMEOUT_SECONDS
  UI_EXPECT_SUBSTRING
  CATALOG_HEALTHCHECK_EXPECTED_SUBSTRING
  CART_HEALTHCHECK_EXPECTED_SUBSTRING
  CHECKOUT_HEALTHCHECK_EXPECTED_SUBSTRING
  ORDERS_HEALTHCHECK_EXPECTED_SUBSTRING
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

base_url="${1%/}"
mode="${2:-ui-only}"
smoke_retries="${SMOKE_RETRIES:-12}"
smoke_retry_delay_seconds="${SMOKE_RETRY_DELAY_SECONDS:-10}"
smoke_timeout_seconds="${SMOKE_TIMEOUT_SECONDS:-10}"

validate_body() {
  local label="$1"
  local body="$2"
  local expected_substring="${3:-}"

  if [[ -n "$expected_substring" ]]; then
    grep -Fq "$expected_substring" <<<"$body"
    return 0
  fi

  if command -v jq >/dev/null 2>&1 && jq -e . >/dev/null 2>&1 <<<"$body"; then
    jq -e '
      .status? == "UP" or
      .status? == "up" or
      .status? == "ok" or
      .status? == "OK" or
      .status? == "pass"
    ' >/dev/null <<<"$body" && return 0
  fi

  [[ -n "$body" ]]
}

check_url() {
  local label="$1"
  local url="$2"
  local expected_substring="${3:-}"
  local attempt=1
  local body

  while (( attempt <= smoke_retries )); do
    echo "checking ${label}: ${url} (attempt ${attempt}/${smoke_retries})"

    if body="$(curl -fsS --max-time "$smoke_timeout_seconds" "$url")" && validate_body "$label" "$body" "$expected_substring"; then
      echo "${label} check passed"
      return 0
    fi

    if (( attempt == smoke_retries )); then
      echo "${label} check failed after ${smoke_retries} attempts"
      return 1
    fi

    sleep "$smoke_retry_delay_seconds"
    attempt=$((attempt + 1))
  done
}

case "$mode" in
  ui-only)
    check_url "ui" "$base_url" "${UI_EXPECT_SUBSTRING:-}"
    ;;
  ui-backends)
    check_url "ui" "$base_url" "${UI_EXPECT_SUBSTRING:-}"
    [[ -n "${CATALOG_HEALTHCHECK_URL:-}" ]] && check_url "catalog" "$CATALOG_HEALTHCHECK_URL" "${CATALOG_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    [[ -n "${CART_HEALTHCHECK_URL:-}" ]] && check_url "cart" "$CART_HEALTHCHECK_URL" "${CART_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    [[ -n "${CHECKOUT_HEALTHCHECK_URL:-}" ]] && check_url "checkout" "$CHECKOUT_HEALTHCHECK_URL" "${CHECKOUT_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    [[ -n "${ORDERS_HEALTHCHECK_URL:-}" ]] && check_url "orders" "$ORDERS_HEALTHCHECK_URL" "${ORDERS_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    ;;
  backend-only)
    [[ -n "${CATALOG_HEALTHCHECK_URL:-}" ]] && check_url "catalog" "$CATALOG_HEALTHCHECK_URL" "${CATALOG_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    [[ -n "${CART_HEALTHCHECK_URL:-}" ]] && check_url "cart" "$CART_HEALTHCHECK_URL" "${CART_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    [[ -n "${CHECKOUT_HEALTHCHECK_URL:-}" ]] && check_url "checkout" "$CHECKOUT_HEALTHCHECK_URL" "${CHECKOUT_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    [[ -n "${ORDERS_HEALTHCHECK_URL:-}" ]] && check_url "orders" "$ORDERS_HEALTHCHECK_URL" "${ORDERS_HEALTHCHECK_EXPECTED_SUBSTRING:-}"
    ;;
  *)
    echo "unsupported mode: ${mode}"
    exit 1
    ;;
esac
