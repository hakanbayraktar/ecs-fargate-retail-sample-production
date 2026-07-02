#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/check-ecr-scan.sh <repository-name-or-uri> <image-tag>

Environment variables:
  MAX_CRITICAL_FINDINGS
  MAX_HIGH_FINDINGS
  IMAGE_SCAN_RETRIES
  IMAGE_SCAN_DELAY_SECONDS
EOF
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

repository_input="$1"
image_tag="$2"
max_critical_findings="${MAX_CRITICAL_FINDINGS:-0}"
max_high_findings="${MAX_HIGH_FINDINGS:-0}"
image_scan_retries="${IMAGE_SCAN_RETRIES:-18}"
image_scan_delay_seconds="${IMAGE_SCAN_DELAY_SECONDS:-10}"

repository_name="${repository_input#*/}"
scan_json=""
scan_status=""

for (( attempt=1; attempt<=image_scan_retries; attempt++ )); do
  echo "checking ECR scan for ${repository_name}:${image_tag} (attempt ${attempt}/${image_scan_retries})"

  if scan_json="$(aws ecr describe-image-scan-findings \
    --repository-name "$repository_name" \
    --image-id "imageTag=${image_tag}" \
    --output json 2>/dev/null)"; then
    scan_status="$(jq -r '.imageScanStatus.status // empty' <<<"$scan_json")"

    case "$scan_status" in
      COMPLETE|ACTIVE)
        break
        ;;
      FAILED)
        echo "image scan failed"
        exit 1
        ;;
    esac
  fi

  if (( attempt == image_scan_retries )); then
    echo "image scan did not become ready in time"
    exit 1
  fi

  sleep "$image_scan_delay_seconds"
done

critical_findings="$(jq -r '.imageScanFindings.findingSeverityCounts.CRITICAL // 0' <<<"$scan_json")"
high_findings="$(jq -r '.imageScanFindings.findingSeverityCounts.HIGH // 0' <<<"$scan_json")"

echo "scan status: ${scan_status}"
echo "critical findings: ${critical_findings}"
echo "high findings: ${high_findings}"

if (( critical_findings > max_critical_findings )); then
  echo "critical findings exceed threshold"
  exit 1
fi

if (( high_findings > max_high_findings )); then
  echo "high findings exceed threshold"
  exit 1
fi
