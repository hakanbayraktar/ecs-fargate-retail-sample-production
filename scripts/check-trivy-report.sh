#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: scripts/check-trivy-report.sh <trivy-json-report>

Environment variables:
  CI_MAX_CRITICAL_FINDINGS
  CI_MAX_HIGH_FINDINGS

Fallback environment variables:
  MAX_CRITICAL_FINDINGS
  MAX_HIGH_FINDINGS
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

report_file="$1"

if [[ ! -f "$report_file" ]]; then
  echo "missing Trivy report: $report_file"
  exit 1
fi

max_critical_findings="${CI_MAX_CRITICAL_FINDINGS:-${MAX_CRITICAL_FINDINGS:-0}}"
max_high_findings="${CI_MAX_HIGH_FINDINGS:-${MAX_HIGH_FINDINGS:-0}}"

critical_findings="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$report_file")"
high_findings="$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$report_file")"

echo "Trivy policy report: $report_file"
echo "critical findings: ${critical_findings}"
echo "high findings: ${high_findings}"
echo "thresholds: critical<=${max_critical_findings} high<=${max_high_findings}"

if (( critical_findings > max_critical_findings )); then
  echo "critical findings exceed threshold"
  exit 1
fi

if (( high_findings > max_high_findings )); then
  echo "high findings exceed threshold"
  exit 1
fi
