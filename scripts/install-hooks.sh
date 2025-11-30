#!/usr/bin/env bash
# Install local git hooks to use .githooks directory
set -euo pipefail

echo "Setting git hooksPath to .githooks"
git config core.hooksPath .githooks
echo "Done: git will now use .githooks/pre-commit"
