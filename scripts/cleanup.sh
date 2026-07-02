#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/cleanup.sh <dev|prod> [--auto-approve]

Destroys the selected environment using the shared Terraform root and the
matching backend.hcl and tfvars files.

Examples:
  scripts/cleanup.sh dev
  scripts/cleanup.sh prod --auto-approve
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

environment="$1"
auto_approve="${2:-}"

if [[ "$environment" != "dev" && "$environment" != "prod" ]]; then
  echo "environment must be dev or prod"
  exit 1
fi

if [[ -n "$auto_approve" && "$auto_approve" != "--auto-approve" ]]; then
  usage
  exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
terraform_dir="${repo_root}/terraform"
backend_file="envs/${environment}/backend.hcl"
tfvars_file="envs/${environment}/${environment}.tfvars"

if [[ ! -f "${terraform_dir}/${backend_file}" ]]; then
  echo "missing backend file: ${terraform_dir}/${backend_file}"
  exit 1
fi

if [[ ! -f "${terraform_dir}/${tfvars_file}" ]]; then
  echo "missing tfvars file: ${terraform_dir}/${tfvars_file}"
  exit 1
fi

terraform -chdir="$terraform_dir" init -backend-config="$backend_file" >/dev/null

destroy_args=(
  destroy
  -var-file="$tfvars_file"
)

if [[ "$auto_approve" == "--auto-approve" ]]; then
  destroy_args+=(-auto-approve)
fi

terraform -chdir="$terraform_dir" "${destroy_args[@]}"

