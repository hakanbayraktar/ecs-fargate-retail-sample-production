#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/sync-github-variables.sh <dev|prod> [--apply]

Reads Terraform outputs from the shared root and prints the GitHub variable
commands required by the deploy workflows. With --apply, it writes them to the
current GitHub repository using gh.

Prerequisites:
  - terraform init/apply already run for the selected environment
  - jq installed
  - gh authenticated if --apply is used
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

environment="$1"
apply_mode="${2:-}"

if [[ "$environment" != "dev" && "$environment" != "prod" ]]; then
  echo "environment must be dev or prod"
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

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
terraform_dir="${repo_root}/terraform"
tfvars_file="${terraform_dir}/envs/${environment}/${environment}.tfvars"

if [[ ! -f "$tfvars_file" ]]; then
  echo "missing tfvars file: $tfvars_file"
  exit 1
fi

extract_tfvars_string() {
  local key="$1"
  sed -n "s/^${key}[[:space:]]*=[[:space:]]*\"\\([^\"]*\\)\"/\\1/p" "$tfvars_file" | head -n 1
}

aws_region="$(extract_tfvars_string "aws_region")"

if [[ -z "$aws_region" ]]; then
  echo "could not determine aws_region from $tfvars_file"
  exit 1
fi

outputs_json="$(terraform -chdir="$terraform_dir" output -json)"

application_url="$(jq -r '.application_url.value' <<<"$outputs_json")"
ecs_cluster_name="$(jq -r '.ecs_cluster_name.value' <<<"$outputs_json")"

declare -A variable_map=(
  ["AWS_REGION"]="$aws_region"
  ["ECS_CLUSTER_NAME"]="$ecs_cluster_name"
  ["SMOKE_TEST_URL"]="$application_url"
  ["ECS_UI_SERVICE_NAME"]="$(jq -r '.ecs_service_names.value.ui' <<<"$outputs_json")"
  ["ECS_CATALOG_SERVICE_NAME"]="$(jq -r '.ecs_service_names.value.catalog' <<<"$outputs_json")"
  ["ECS_CART_SERVICE_NAME"]="$(jq -r '.ecs_service_names.value.cart' <<<"$outputs_json")"
  ["ECS_CHECKOUT_SERVICE_NAME"]="$(jq -r '.ecs_service_names.value.checkout' <<<"$outputs_json")"
  ["ECS_ORDERS_SERVICE_NAME"]="$(jq -r '.ecs_service_names.value.orders // empty' <<<"$outputs_json")"
  ["ECS_UI_TASK_DEFINITION_FAMILY"]="$(jq -r '.ecs_task_definition_families.value.ui' <<<"$outputs_json")"
  ["ECS_CATALOG_TASK_DEFINITION_FAMILY"]="$(jq -r '.ecs_task_definition_families.value.catalog' <<<"$outputs_json")"
  ["ECS_CART_TASK_DEFINITION_FAMILY"]="$(jq -r '.ecs_task_definition_families.value.cart' <<<"$outputs_json")"
  ["ECS_CHECKOUT_TASK_DEFINITION_FAMILY"]="$(jq -r '.ecs_task_definition_families.value.checkout' <<<"$outputs_json")"
  ["ECS_ORDERS_TASK_DEFINITION_FAMILY"]="$(jq -r '.ecs_task_definition_families.value.orders // empty' <<<"$outputs_json")"
  ["ECR_UI_REPOSITORY"]="$(jq -r '.ecr_repository_urls.value.ui' <<<"$outputs_json")"
  ["ECR_CATALOG_REPOSITORY"]="$(jq -r '.ecr_repository_urls.value.catalog' <<<"$outputs_json")"
  ["ECR_CART_REPOSITORY"]="$(jq -r '.ecr_repository_urls.value.cart' <<<"$outputs_json")"
  ["ECR_CHECKOUT_REPOSITORY"]="$(jq -r '.ecr_repository_urls.value.checkout' <<<"$outputs_json")"
  ["ECR_ORDERS_REPOSITORY"]="$(jq -r '.ecr_repository_urls.value.orders // empty' <<<"$outputs_json")"
)

for key in "${!variable_map[@]}"; do
  value="${variable_map[$key]}"

  if [[ -z "$value" || "$value" == "null" ]]; then
    continue
  fi

  if [[ "$apply_mode" == "--apply" ]]; then
    gh variable set "$key" --body "$value"
    echo "set $key"
  else
    printf 'gh variable set %s --body %q\n' "$key" "$value"
  fi
done

