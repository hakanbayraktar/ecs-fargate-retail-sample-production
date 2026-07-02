#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/preflight-prod-cutover.sh [tfvars-file]

Validates that the production tfvars file is ready for HTTPS and Route53 cutover.

Defaults:
  tfvars-file=terraform/envs/prod/prod.tfvars
EOF
}

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

tfvars_file="${1:-terraform/envs/prod/prod.tfvars}"

if [[ ! -f "$tfvars_file" ]]; then
  echo "missing tfvars file: $tfvars_file"
  exit 1
fi

require_match() {
  local pattern="$1"
  local message="$2"

  if ! grep -Eq "$pattern" "$tfvars_file"; then
    echo "$message"
    exit 1
  fi
}

reject_match() {
  local pattern="$1"
  local message="$2"

  if grep -Eq "$pattern" "$tfvars_file"; then
    echo "$message"
    exit 1
  fi
}

require_match '^environment[[:space:]]*=[[:space:]]*"prod"$' "environment must be prod"
require_match '^enable_waf[[:space:]]*=[[:space:]]*true$' "enable_waf must be true in prod"
require_match '^certificate_arn[[:space:]]*=' "certificate_arn must be set"
require_match '^route53_zone_id[[:space:]]*=' "route53_zone_id must be set"
require_match '^public_domain_name[[:space:]]*=' "public_domain_name must be set"

reject_match '^certificate_arn[[:space:]]*=[[:space:]]*"CHANGE_ME"$' "certificate_arn still uses placeholder"
reject_match '^route53_zone_id[[:space:]]*=[[:space:]]*"CHANGE_ME"$' "route53_zone_id still uses placeholder"
reject_match '^public_domain_name[[:space:]]*=[[:space:]]*"shop\.example\.com"$' "public_domain_name still uses example placeholder"
reject_match '^public_domain_name[[:space:]]*=[[:space:]]*null$' "public_domain_name cannot be null in prod"
reject_match '^route53_zone_id[[:space:]]*=[[:space:]]*null$' "route53_zone_id cannot be null in prod"

echo "prod cutover preflight passed for ${tfvars_file}"
