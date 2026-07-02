#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/sync-github-environment-vars.sh <dev|stage|prod> [--apply]

Reads Terraform outputs for the selected environment and prepares the GitHub
Environment variables used by the deploy workflows.

Default mode prints the `gh variable set` commands without executing them.
Use `--apply` to write the variables directly through the GitHub CLI.

Examples:
  scripts/sync-github-environment-vars.sh dev
  scripts/sync-github-environment-vars.sh stage --apply
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

environment="$1"
apply_mode="${2:-}"

if [[ "$environment" != "dev" && "$environment" != "stage" && "$environment" != "prod" ]]; then
  echo "environment must be dev, stage, or prod"
  exit 1
fi

if [[ -n "$apply_mode" && "$apply_mode" != "--apply" ]]; then
  usage
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required"
  exit 1
fi

if [[ "$apply_mode" == "--apply" ]] && ! command -v gh >/dev/null 2>&1; then
  echo "gh is required for --apply mode"
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
outputs_json="$(terraform -chdir="$terraform_dir" output -json)"

declare -A vars

vars[AWS_REGION]="$(jq -r '.aws_region.value' <<<"$outputs_json")"
vars[ECS_CLUSTER_NAME]="$(jq -r '.ecs_cluster_name.value' <<<"$outputs_json")"
vars[ECS_UI_SERVICE_NAME]="$(jq -r '.ecs_service_names.value.ui // empty' <<<"$outputs_json")"
vars[ECS_CATALOG_SERVICE_NAME]="$(jq -r '.ecs_service_names.value.catalog // empty' <<<"$outputs_json")"
vars[ECS_CART_SERVICE_NAME]="$(jq -r '.ecs_service_names.value.cart // empty' <<<"$outputs_json")"
vars[ECS_CHECKOUT_SERVICE_NAME]="$(jq -r '.ecs_service_names.value.checkout // empty' <<<"$outputs_json")"
vars[ECS_ORDERS_SERVICE_NAME]="$(jq -r '.ecs_service_names.value.orders // empty' <<<"$outputs_json")"
vars[ECS_UI_TASK_DEFINITION_FAMILY]="$(jq -r '.ecs_task_definition_families.value.ui // empty' <<<"$outputs_json")"
vars[ECS_CATALOG_TASK_DEFINITION_FAMILY]="$(jq -r '.ecs_task_definition_families.value.catalog // empty' <<<"$outputs_json")"
vars[ECS_CART_TASK_DEFINITION_FAMILY]="$(jq -r '.ecs_task_definition_families.value.cart // empty' <<<"$outputs_json")"
vars[ECS_CHECKOUT_TASK_DEFINITION_FAMILY]="$(jq -r '.ecs_task_definition_families.value.checkout // empty' <<<"$outputs_json")"
vars[ECS_ORDERS_TASK_DEFINITION_FAMILY]="$(jq -r '.ecs_task_definition_families.value.orders // empty' <<<"$outputs_json")"
vars[ECR_UI_REPOSITORY]="$(jq -r '.ecr_repository_urls.value.ui // empty' <<<"$outputs_json")"
vars[ECR_CATALOG_REPOSITORY]="$(jq -r '.ecr_repository_urls.value.catalog // empty' <<<"$outputs_json")"
vars[ECR_CART_REPOSITORY]="$(jq -r '.ecr_repository_urls.value.cart // empty' <<<"$outputs_json")"
vars[ECR_CHECKOUT_REPOSITORY]="$(jq -r '.ecr_repository_urls.value.checkout // empty' <<<"$outputs_json")"
vars[ECR_ORDERS_REPOSITORY]="$(jq -r '.ecr_repository_urls.value.orders // empty' <<<"$outputs_json")"
vars[SMOKE_TEST_URL]="$(jq -r '.application_url.value // empty' <<<"$outputs_json")"

print_var() {
  local name="$1"
  local value="$2"
  printf '%s=%q\n' "$name" "$value"
}

if [[ "$apply_mode" == "--apply" ]]; then
  for name in "${!vars[@]}"; do
    gh variable set "$name" --env "$environment" --body "${vars[$name]}"
  done

  cat <<EOF
Synced GitHub Environment variables for ${environment}.

Set these manually if you use backend reachability checks from the runner:
  CATALOG_HEALTHCHECK_URL
  CART_HEALTHCHECK_URL
  CHECKOUT_HEALTHCHECK_URL
  ORDERS_HEALTHCHECK_URL
EOF
else
  echo "# dry run for GitHub Environment: ${environment}"
  echo "# apply with: scripts/sync-github-environment-vars.sh ${environment} --apply"
  echo

  for name in "${!vars[@]}"; do
    print_var "$name" "${vars[$name]}"
  done | sort

  cat <<'EOF'

# manual-only variables if you want backend health checks from GitHub runners:
# CATALOG_HEALTHCHECK_URL
# CART_HEALTHCHECK_URL
# CHECKOUT_HEALTHCHECK_URL
# ORDERS_HEALTHCHECK_URL
EOF
fi
