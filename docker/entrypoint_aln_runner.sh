#!/usr/bin/env bash
# Entry point for aln-runner container
# Accepts env flags: ALN_RUNTIME, GPU_TYPE, VRAM_GB, CUDA_VISIBLE_DEVICES, ALN_POLICY_PROFILE
# Defaults: ALN_RUNTIME=mock, GPU_TYPE=none, VRAM_GB=8, ALN_POLICY_PROFILE=ci

set -euo pipefail

ALN_RUNTIME="${ALN_RUNTIME:-mock}"
GPU_TYPE="${GPU_TYPE:-none}"
VRAM_GB="${VRAM_GB:-8}"
CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"
ALN_POLICY_PROFILE="${ALN_POLICY_PROFILE:-ci}"
ALN_CONF="/workspace/cicd/aln-runner-config.aln"

export RAPTOR_GPU_TYPE="$GPU_TYPE"
export RAPTOR_VRAM_GB="$VRAM_GB"

# Compute RAPTOR_T_CTX_MAX based on a simple rule: if VRAM_GB >= 24 => 200k, else scaled
if [[ "$VRAM_GB" -ge 24 ]]; then
  export RAPTOR_T_CTX_MAX=200000
elif [[ "$VRAM_GB" -ge 16 ]]; then
  export RAPTOR_T_CTX_MAX=120000
else
  export RAPTOR_T_CTX_MAX=48000
fi

# Map ALN runtime profiles to config selections
# For mock runtime, simply set ALN_RUNTIME=mock
if [[ "$ALN_RUNTIME" = "mock" ]]; then
  RUNTIME_ARG="--runtime mock"
else
  RUNTIME_ARG="--runtime prod"
fi

# Default script is run_tests.aln; allow override with first arg
SCRIPT="${1:-run_tests.aln}"

# If script is a file within the container workspace, run it; else treat as command
if [[ -f "/workspace/$SCRIPT" ]]; then
  SCRIPT_PATH="/workspace/$SCRIPT"
else
  SCRIPT_PATH="$SCRIPT"
fi

# Launch runner with mapping config
echo "Entrypoint: runtime=$ALN_RUNTIME, gpu=$GPU_TYPE, vram=${VRAM_GB}GB, script=$SCRIPT_PATH, policy=${ALN_POLICY_PROFILE}"

# If ALN_RUNTIME=prod and vault env vars present, ensure they are exported
if [[ "$ALN_RUNTIME" = "prod" ]]; then
  # Require minimal runtime variables for prod mode
  echo "ALN_RUNTIME=prod enabled. Validating required environment variables..."
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "ERROR: GITHUB_TOKEN is required in prod mode (set as a secret in CI)."
    exit 1
  fi
  if [[ -z "${VAULT_ADDR:-}" ]]; then
    echo "ERROR: VAULT_ADDR is recommended to be provided in prod mode."
  else
    echo "Vault endpoint: $VAULT_ADDR"
  fi
  if [[ -z "${VAULT_TOKEN:-}" ]]; then
    echo "ERROR: VAULT_TOKEN is required in prod mode (set as a secret in CI)."
    exit 1
  fi
  if [[ -z "${KUBECONFIG:-}" ]]; then
    echo "WARNING: KUBECONFIG not provided; any K8s bindings may fail or be no-op."
  fi
fi

exec aln-runner $RUNTIME_ARG --config "$ALN_CONF" "$SCRIPT_PATH"
