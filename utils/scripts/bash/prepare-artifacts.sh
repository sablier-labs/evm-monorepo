#!/usr/bin/env bash

# Pre-requisites:
# - foundry (https://getfoundry.sh)
# - bun (https://bun.sh)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Generate the artifacts with Forge
FOUNDRY_PROFILE=optimized forge build

# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts

# Create the new artifacts directories
mkdir $artifacts \
  "$artifacts/interfaces" \
  "$artifacts/libraries"

# Copy the comptroller artifact
comptroller=./artifacts/
cp out-optimized/SablierComptroller.sol/SablierComptroller.json $comptroller
cp out-optimized/ERC1967Proxy.sol/ERC1967Proxy.json $comptroller

# Copy the interfaces
interfaces=./artifacts/interfaces
cp out-optimized/IAdminable.sol/IAdminable.json $interfaces
cp out-optimized/IRoleAdminable.sol/IRoleAdminable.json $interfaces
cp out-optimized/ISablierComptroller.sol/ISablierComptroller.json $interfaces

# Copy the libraries
libraries=./artifacts/libraries
cp out-optimized/Errors.sol/Errors.json $libraries

# Format the artifacts with Prettier
bun prettier --write ./artifacts
