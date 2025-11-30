#!/usr/bin/env bash
# pre-commit-aln.sh — Git-friendly pre-commit runner for SAFE_RESOLUTION
set -euo pipefail

# Detect staged .aln changes
staged=$(git diff --cached --name-only --diff-filter=ACM | grep -E "\.aln$" || true)
if [ -z "$staged" ]; then
  echo "No .aln changes staged; skipping SAFE_RESOLUTION validation"
  exit 0
fi

echo "Staged .aln files detected:"
echo "$staged"

# Choose how to run ALN validation: use local aln binary if present, otherwise docker runner
if command -v aln >/dev/null 2>&1; then
  echo "Found native 'aln' binary; running validate"
  aln run cicd/hooks/validate_safe_resolution_matrix.aln
  status=$?
else
  echo "Native 'aln' not found; using Docker aln-runner image"
  docker build -f docker/Dockerfile.aln-runner -t ide-lab/aln-runner:precommit .
  docker run --rm -v "$PWD":/workspace -w /workspace -e ALN_RUNTIME=mock ide-lab/aln-runner:precommit ./docker/entrypoint_aln_runner.sh cicd/hooks/validate_safe_resolution_matrix.aln
  status=$?
fi

if [ "$status" -ne 0 ]; then
  echo "SAFE_RESOLUTION validation failed; aborting commit"
  exit 1
fi

echo "SAFE_RESOLUTION validation passed"
exit 0
