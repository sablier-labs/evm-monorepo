# Real-World Examples

Examples from Monad mainnet deployment (Chain ID: 143).

## Standard Contract Verification

### Library Contract

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x1feB172238638897B13b69C65feB508a0a96b35D \
  src/libraries/LockupMath.sol:LockupMath \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

### NFT Descriptor Contract

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x619E7f9832522EDeBd883482Cd3d84653A050725 \
  src/LockupNFTDescriptor.sol:LockupNFTDescriptor \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

### Core Protocol Contract

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x003F5393F4836f710d492AD98D89F5BFCCF1C962 \
  src/SablierLockup.sol:SablierLockup \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" \
    0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399 \
    0x619E7f9832522EDeBd883482Cd3d84653A050725) \
  --watch
```

## Proxy Pattern Verification (Comptroller)

### Implementation Contract

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x53de3a712d2b6657e92fa2452d58a6b823f86920 \
  src/SablierComptroller.sol:SablierComptroller \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

### ERC1967 Proxy

```bash
# Get initialize calldata from broadcast
INIT_CALLDATA="0x8129fc1c"  # Example: initialize() selector

# Encode constructor args
CONSTRUCTOR_ARGS=$(cast abi-encode \
  "constructor(address,bytes)" \
  0x53de3a712d2b6657e92fa2452d58a6b823f86920 \
  $INIT_CALLDATA)

# Verify proxy
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399 \
  node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $CONSTRUCTOR_ARGS \
  --watch
```

## Factory Contract Verification (Airdrops)

### Factory Contracts

```bash
# MerkleInstant Factory
FOUNDRY_PROFILE=optimized forge verify-contract \
  0xaB15e653cD3bBCe7B7412f81056a450BC0f2e7B9 \
  src/SablierFactoryMerkleInstant.sol:SablierFactoryMerkleInstant \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch

# MerkleLL Factory
FOUNDRY_PROFILE=optimized forge verify-contract \
  0x7DcAB43465c1EbDA92133c92262a6c55394dD69e \
  src/SablierFactoryMerkleLL.sol:SablierFactoryMerkleLL \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

## Factory-Created Campaign Verification

### Step 1: Extract Constructor Args

```bash
# Get initCode from broadcast
jq -r '.transactions[0].transaction.input' \
  broadcast/CreateMerkleInstant.s.sol/143/run-latest.json > /tmp/initcode.txt

# Extract args (airdrops uses solc 0.8.29)
python scripts/extract_constructor_args.py /tmp/initcode.txt 0.8.29
# Output: 0x00000000000000000000000079fb3e81aac012c08501f41296ccc145a1e15844...
```

### Step 2: Verify Campaign Contract

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  0xEEd8aBF8D93Df0185d5A683Dff7DC00F656aD61C \
  src/SablierMerkleInstant.sol:SablierMerkleInstant \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args 0x00000000000000000000000079fb3e81aac012c08501f41296ccc145a1e15844... \
  --watch
```

## Bytecode Mismatch Resolution

### Problem

Verification failed with "bytecode does not match" despite same Solidity version.

### Solution

```bash
# 1. Find deployment commit from SDK
cat ../sdk/deployments/airdrops/v1.4/broadcasts/monad.json | jq -r '.commit'
# Output: cec949f

# 2. Checkout commit
git checkout cec949f

# 3. Reinstall dependencies (critical step!)
bun install

# 4. Rebuild
FOUNDRY_PROFILE=optimized forge build

# 5. Verify bytecode matches
cast code 0xaB15e653cD3bBCe7B7412f81056a450BC0f2e7B9 --rpc-url monad > /tmp/onchain.txt
jq -r '.deployedBytecode.object' out/SablierFactoryMerkleInstant.sol/SablierFactoryMerkleInstant.json > /tmp/local.txt
diff /tmp/onchain.txt /tmp/local.txt  # Should be empty

# 6. Retry verification
FOUNDRY_PROFILE=optimized forge verify-contract ...
```

## Complete Monad Deployment Addresses

### Lockup Protocol

| Contract            | Address                                      |
| ------------------- | -------------------------------------------- |
| LockupMath          | `0x1feB172238638897B13b69C65feB508a0a96b35D` |
| LockupNFTDescriptor | `0x619E7f9832522EDeBd883482Cd3d84653A050725` |
| SablierBatchLockup  | `0x4FCACf614E456728CaEa87f475bd78EC3550E20B` |
| SablierLockup       | `0x003F5393F4836f710d492AD98D89F5BFCCF1C962` |

### Flow Protocol

| Contract          | Address                                      |
| ----------------- | -------------------------------------------- |
| FlowNFTDescriptor | `0xf51BB8bd1cfc7C890dB68c39dCCA67CAd7810Ce4` |
| SablierFlow       | `0x0340a829b6dC3aDF7710a5bAF1970914af4977f5` |

### Comptroller

| Contract       | Address                                      |
| -------------- | -------------------------------------------- |
| Implementation | `0x53de3a712d2b6657e92fa2452d58a6b823f86920` |
| Proxy          | `0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399` |

### Airdrops Factories

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| SablierFactoryMerkleInstant | `0xaB15e653cD3bBCe7B7412f81056a450BC0f2e7B9` |
| SablierFactoryMerkleLL      | `0x7DcAB43465c1EbDA92133c92262a6c55394dD69e` |
| SablierFactoryMerkleLT      | `0xfA2Bf3EDdEfE67631BfFA5C53b621A9C6BEbc9C3` |
| SablierFactoryMerkleVCA     | `0xCdCc46A7759dE01271E533BBC3b0F32899545a76` |

### Airdrops Campaigns (Test)

| Contract             | Address                                      |
| -------------------- | -------------------------------------------- |
| SablierMerkleInstant | `0xEEd8aBF8D93Df0185d5A683Dff7DC00F656aD61C` |
| SablierMerkleLL      | `0x24B114Ce16a6B7A0CE1C1548e2843A97D07FE879` |
| SablierMerkleLT      | `0x618BC29c7bDAd6e5e86D3cD0c9c31EeA2Ab71d9F` |
| SablierMerkleVCA     | `0x256cFd4829cf25A61021EAe6AD498E600b28bC4f` |
