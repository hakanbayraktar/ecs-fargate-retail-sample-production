#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/list-ecs-events.sh <cluster-name> <service-name> [limit]

Examples:
  scripts/list-ecs-events.sh ecs-retail-dev ecs-retail-dev-ui
  scripts/list-ecs-events.sh ecs-retail-prod ecs-retail-prod-catalog 30
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 1
fi

cluster_name="$1"
service_name="$2"
limit="${3:-20}"

aws ecs describe-services \
  --cluster "$cluster_name" \
  --services "$service_name" \
  --query "services[0].events[0:${limit}].[createdAt,message]" \
  --output table

