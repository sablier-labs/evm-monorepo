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
rm -rf "$artifacts"

# Create the new artifacts directories
mkdir "$artifacts" \
  "$artifacts/interfaces" \
  "$artifacts/interfaces/external" \
  "$artifacts/libraries" \
  "$artifacts/erc20"

################################################
####                  BOB                   ####
################################################

bob=./artifacts/
cp out-optimized/SablierBob.sol/SablierBob.json "$bob"
cp out-optimized/SablierEscrow.sol/SablierEscrow.json "$bob"
cp out-optimized/SablierLidoAdapter.sol/SablierLidoAdapter.json "$bob"
cp out-optimized/BobVaultShare.sol/BobVaultShare.json "$bob"

bob_interfaces=./artifacts/interfaces
cp out-optimized/IBobVaultShare.sol/IBobVaultShare.json "$bob_interfaces"
cp out-optimized/ISablierBob.sol/ISablierBob.json "$bob_interfaces"
cp out-optimized/ISablierEscrow.sol/ISablierEscrow.json "$bob_interfaces"
cp out-optimized/ISablierLidoAdapter.sol/ISablierLidoAdapter.json "$bob_interfaces"

bob_external=./artifacts/interfaces/external
cp out-optimized/ICurveStETHPool.sol/ICurveStETHPool.json "$bob_external"
cp out-optimized/ILidoWithdrawalQueue.sol/ILidoWithdrawalQueue.json "$bob_external"
cp out-optimized/IStETH.sol/IStETH.json "$bob_external"
cp out-optimized/IWETH9.sol/IWETH9.json "$bob_external"
cp out-optimized/IWstETH.sol/IWstETH.json "$bob_external"

bob_libraries=./artifacts/libraries
cp out-optimized/Errors.sol/Errors.json "$bob_libraries"


################################################
####                OTHERS                  ####
################################################

erc20=./artifacts/erc20
cp out-optimized/IERC20.sol/IERC20.json "$erc20"

# Format the artifacts with Prettier
bun prettier --write ./artifacts
