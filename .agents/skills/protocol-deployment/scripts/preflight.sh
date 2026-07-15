#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: bash scripts/preflight.sh <rpc-url> <chain-id> [comptroller-address]" >&2
  exit 2
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage
fi

if ! command -v cast >/dev/null 2>&1; then
  echo "Error: cast is required but was not found on PATH." >&2
  exit 1
fi

rpc_url=$1
expected_chain_id=$2
comptroller_address=${3:-0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399}
create2_deployer=0x4e59b44847b379578588920cA78FbF26c0B4956C

actual_chain_id=$(cast chain-id --rpc-url "$rpc_url")
if [ "$actual_chain_id" != "$expected_chain_id" ]; then
  echo "Error: RPC chain ID $actual_chain_id does not match expected chain ID $expected_chain_id." >&2
  exit 1
fi

create2_code=$(cast code "$create2_deployer" --rpc-url "$rpc_url")
if [ -z "$create2_code" ] || [ "$create2_code" = "0x" ]; then
  echo "Error: canonical CREATE2 deployer has no code on chain $actual_chain_id." >&2
  exit 1
fi

comptroller_code=$(cast code "$comptroller_address" --rpc-url "$rpc_url")

echo "chain_id=$actual_chain_id"
echo "create2_deployer=$create2_deployer"
echo "create2_code_bytes=$(((${#create2_code} - 2) / 2))"
echo "comptroller_address=$comptroller_address"
if [ -z "$comptroller_code" ] || [ "$comptroller_code" = "0x" ]; then
  echo "comptroller_has_code=false"
  echo "comptroller_code_bytes=0"
else
  echo "comptroller_has_code=true"
  echo "comptroller_code_bytes=$(((${#comptroller_code} - 2) / 2))"
fi
