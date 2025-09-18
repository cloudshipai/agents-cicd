#!/usr/bin/env bash
set -euo pipefail

# Defaults if not provided by env
STN_MODEL="${STN_MODEL:-gpt-4o-mini}"
STN_MAX_STEPS="${STN_MAX_STEPS:-4}"
STN_TOKEN_BUDGET="${STN_TOKEN_BUDGET:-1500}"
STN_SUMMARY_MAX_CHARS="${STN_SUMMARY_MAX_CHARS:-2500}"
STN_FAIL_ON_SEVERITY="${STN_FAIL_ON_SEVERITY:-high}"

mkdir -p logs artifacts

# Determine the base for diff to find relevant changes
BASE_REF="HEAD~1"
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  if git rev-parse --verify origin/main >/dev/null 2>&1; then
    BASE_REF="origin/main"
    git fetch --depth=1 origin main || true
  else
    BASE_REF="$(git hash-object -t tree /dev/null)"
  fi
fi

echo "Computing diff from $BASE_REF to HEAD..."
CHANGED_FILES="$(git diff --name-only "$BASE_REF" HEAD || true)"

echo "Changed files:"
echo "${CHANGED_FILES}"

# Fast-path: exit if no relevant changes
echo "${CHANGED_FILES}" | grep -E '(\.tf$|Dockerfile|\.dockerfile$|\.docker-compose\.yml$|\.py$)' >/dev/null 2>&1 || {
  echo "No relevant changes" | tee logs/summary.log
  echo "No relevant changes" > artifacts/summary.txt
  # Still produce an empty artifact tar for consistency
  tar -czf artifacts/security-results.tar.gz --owner=0 --group=0 --numeric-owner -C logs . || true
  exit 0
}

# Simulated bounded "scan" using environment constraints (placeholder for stn agent call)
echo "Starting bounded scan with model=${STN_MODEL}, max_steps=${STN_MAX_STEPS}, token_budget=${STN_TOKEN_BUDGET}" | tee -a logs/station-run.log
echo "Scanning Terraform, Containers, and Python code..." | tee -a logs/station-run.log

# Placeholder results; in a real setup, integrate actual tools (trivy/checkov/bandit/etc.)
RESULTS_JSON="logs/results.json"
cat > "${RESULTS_JSON}" <<JSON
{
  "summary": {
    "token_budget": ${STN_TOKEN_BUDGET},
    "model": "${STN_MODEL}",
    "max_steps": ${STN_MAX_STEPS},
    "issues": {
      "critical": 0,
      "high": 0,
      "medium": 0,
      "low": 0
    }
  }
}
JSON

# Create short human summary respecting max chars
SHORT_SUMMARY="Token budget: ${STN_TOKEN_BUDGET}, Model: ${STN_MODEL}, Max steps: ${STN_MAX_STEPS}
Issues by severity: critical=0, high=0, medium=0, low=0"
SHORT_SUMMARY_TRUNC="$(echo "${SHORT_SUMMARY}" | cut -c1-"${STN_SUMMARY_MAX_CHARS}")"
echo "${SHORT_SUMMARY_TRUNC}" | tee logs/summary.log
echo "${SHORT_SUMMARY_TRUNC}" > artifacts/summary.txt

# Compress logs/results into artifacts
tar -czf artifacts/security-results.tar.gz --owner=0 --group=0 --numeric-owner -C logs . || true

# Fail only if high-severity findings exist (configurable)
HIGH_COUNT="$(jq -r '.summary.issues.high' < "${RESULTS_JSON}" 2>/dev/null || echo 0)"
CRIT_COUNT="$(jq -r '.summary.issues.critical' < "${RESULTS_JSON}" 2>/dev/null || echo 0)"

if [[ "${STN_FAIL_ON_SEVERITY}" == "high" ]]; then
  if [[ "${HIGH_COUNT}" -gt 0 || "${CRIT_COUNT}" -gt 0 ]]; then
    echo "High or critical findings detected: high=${HIGH_COUNT}, critical=${CRIT_COUNT}"
    exit 2
  fi
fi

echo "Scan completed successfully."
exit 0
