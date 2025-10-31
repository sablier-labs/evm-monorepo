#!/usr/bin/env bash

# Shared prepack script for all packages in the monorepo
# This script should be called from a package directory via: bash ../scripts/bash/publish_prepack.sh

set -euo pipefail

# Get the script directory (monorepo_root/scripts/bash)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go up two levels: scripts/bash -> scripts -> monorepo_root
MONOREPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Copy license files from monorepo root to current package directory
cp "$MONOREPO_ROOT/LICENSE.md" \
   "$MONOREPO_ROOT/LICENSE-BUSL.md" \
   "$MONOREPO_ROOT/LICENSE-GPL.md" \
   .

echo "✓ Copied license files from monorepo root"

# Install dependencies
echo "Installing dependencies..."
bun install --frozen-lockfile
echo "✓ Installed dependencies"

# Run package-specific artifact preparation if it exists
if [ -f "./scripts/bash/prepare-artifacts.sh" ]; then
  echo "Preparing artifacts..."
  ./scripts/bash/prepare-artifacts.sh
  echo "✓ Prepared artifacts"
fi
