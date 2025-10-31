#!/usr/bin/env bash

# Shared postpack script for all packages in the monorepo
# Removes license files copied during prepack

set -euo pipefail

# Remove license files from current package directory
rm -f LICENSE.md LICENSE-BUSL.md LICENSE-GPL.md

echo "✓ Cleaned up license files"
