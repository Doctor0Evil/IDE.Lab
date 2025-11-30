#!/usr/bin/env bash
# Local integration test using docker image built from Dockerfile.aln-runner
set -euo pipefail
IMAGE_TAG="ghcr.io/${GITHUB_REPOSITORY:-local/IDE.Lab}:aln-runner-local"

docker build -f docker/Dockerfile.aln-runner -t ${IMAGE_TAG} .

echo "Running test harness in container (mock runtime)"
docker run --rm -e ALN_RUNTIME=mock -e GPU_TYPE=none -e VRAM_GB=8 ${IMAGE_TAG} run_tests.aln

echo "Running SAFE_RESOLUTION validation in container"
docker run --rm -e ALN_RUNTIME=mock -e GPU_TYPE=none -e VRAM_GB=8 ${IMAGE_TAG} validate_safe_resolution_matrix.aln

echo "Running Raptor capacity check"
docker run --rm -e ALN_RUNTIME=mock -e GPU_TYPE=pro -e VRAM_GB=24 ${IMAGE_TAG} raptor_mini_check.aln

echo "All containerized tests completed successfully."
