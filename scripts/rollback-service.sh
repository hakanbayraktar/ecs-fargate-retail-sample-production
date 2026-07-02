#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/rollback-service.sh <cluster-name> <service-name> [task-definition-arn] [--wait]

If task-definition-arn is omitted, the script tries to select the most recent
non-primary deployment task definition from the ECS service description.

Examples:
  scripts/rollback-service.sh ecs-retail-prod ecs-retail-prod-ui
  scripts/rollback-service.sh ecs-retail-prod ecs-retail-prod-ui arn:aws:ecs:... --wait
EOF
}

if [[ $# -lt 2 || $# -gt 4 ]]; then
  usage
  exit 1
fi

cluster_name="$1"
service_name="$2"
target_task_definition=""
wait_for_stability="false"

if [[ $# -ge 3 ]]; then
  case "$3" in
    --wait)
      wait_for_stability="true"
      ;;
    *)
      target_task_definition="$3"
      ;;
  esac
fi

if [[ $# -eq 4 ]]; then
  if [[ "$4" != "--wait" ]]; then
    usage
    exit 1
  fi
  wait_for_stability="true"
fi

service_json="$(aws ecs describe-services --cluster "$cluster_name" --services "$service_name" --output json)"

current_task_definition="$(jq -r '.services[0].taskDefinition' <<<"$service_json")"

if [[ -z "$target_task_definition" ]]; then
  target_task_definition="$(jq -r '
    .services[0].deployments
    | map(select(.status != "PRIMARY"))
    | sort_by(.createdAt)
    | reverse
    | map(.taskDefinition)
    | first // empty
  ' <<<"$service_json")"
fi

if [[ -z "$target_task_definition" || "$target_task_definition" == "null" ]]; then
  echo "No previous task definition could be determined for ${service_name}."
  echo "Current task definition: ${current_task_definition}"
  exit 1
fi

if [[ "$target_task_definition" == "$current_task_definition" ]]; then
  echo "Target task definition is already current: ${target_task_definition}"
  exit 1
fi

echo "Rolling back ${service_name}"
echo "Current task definition: ${current_task_definition}"
echo "Target task definition:  ${target_task_definition}"

aws ecs update-service \
  --cluster "$cluster_name" \
  --service "$service_name" \
  --task-definition "$target_task_definition" \
  --force-new-deployment >/dev/null

if [[ "$wait_for_stability" == "true" ]]; then
  echo "Waiting for ECS service stability..."
  aws ecs wait services-stable --cluster "$cluster_name" --services "$service_name"
fi

echo "Rollback request submitted."

