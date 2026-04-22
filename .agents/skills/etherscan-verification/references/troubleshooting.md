# Troubleshooting

## Bytecode Mismatch

**Error:** "Bytecode does not match" or "Unable to verify"

**Root Cause:** Local compilation produces different bytecode than what was deployed.

### Diagnosis

1. **Check optimizer settings** - Must match deployment profile
2. **Check Solidity version** - Must match exactly
3. **Check dependencies** - `node_modules` may have drifted

### Resolution

#### Step 1: Find Deployment Commit

Check SDK broadcast JSON or deployment records:

```bash
# If commit is in broadcast metadata
jq -r '.commit' broadcast/<Script>/<CHAIN_ID>/run-latest.json

# Or check SDK deployment file
cat ../sdk/deployments/<protocol>/<version>/broadcasts/<chain>.json | jq -r '.commit'
```

#### Step 2: Checkout and Reinstall

```bash
git checkout <DEPLOYMENT_COMMIT>
bun install  # or npm install / yarn
```

#### Step 3: Rebuild

```bash
FOUNDRY_PROFILE=optimized forge build
```

#### Step 4: Verify Bytecode Match

Compare local bytecode with on-chain:

```bash
# Get on-chain bytecode
cast code <CONTRACT_ADDRESS> --rpc-url <chain_name> > /tmp/onchain.txt

# Get local bytecode (from build output)
jq -r '.deployedBytecode.object' \
  out/<Contract>.sol/<Contract>.json > /tmp/local.txt

# Compare (should show no diff if matching)
diff /tmp/onchain.txt /tmp/local.txt
```

#### Step 5: Retry Verification

If bytecodes match, retry the verification command.

## No Known Etherscan API URL

**Error:** "No known Etherscan API URL for chain X"

**Cause:** Chain not in Foundry's built-in chain registry.

**Solution:** Use Etherscan V2 API with explicit `--verifier-url`:

```bash
--verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>"
```

Check if chain is supported: https://docs.etherscan.io/supported-chains

## Constructor Arguments Mismatch

**Error:** "Constructor arguments do not match" or verification fails silently

### Diagnosis

1. Check if contract has constructor parameters
2. Verify args are ABI-encoded correctly
3. For factory contracts, extract from `initCode`

### Resolution

#### For Standard Deployments

Find constructor call in broadcast:

```bash
jq '.transactions[] | select(.contractName == "<Contract>")' \
  broadcast/<Script>/<CHAIN_ID>/run-latest.json
```

The `arguments` field shows the values. Encode them:

```bash
cast abi-encode "constructor(address,uint256)" 0x... 1000
```

#### For Factory Deployments

Use the extraction script:

```bash
python scripts/extract_constructor_args.py /tmp/initcode.txt
```

## Already Verified

**Message:** "Contract source code already verified" or "Already Verified"

**This is not an error.** The contract is already verified on the explorer.

## Rate Limiting

**Error:** "Rate limit exceeded" or 429 errors

**Solution:** Wait and retry. Etherscan has rate limits per API key.

For batch verification, add delays between requests:

```bash
for addr in $ADDRESSES; do
  forge verify-contract $addr ...
  sleep 5
done
```

## Invalid API Key

**Error:** "Invalid API Key" or "Missing API Key"

**Diagnosis:**

```bash
# Check if key is set
echo $ETHERSCAN_API_KEY

# Test key validity
curl "https://api.etherscan.io/api?module=account&action=balance&address=0x0&apikey=$ETHERSCAN_API_KEY"
```

**Solution:** Get API key from https://etherscan.io/myapikey

Note: Single Etherscan API key works for V2 API across all supported chains.

## Compiler Version Mismatch

**Error:** References wrong compiler version

**Diagnosis:** Check `foundry.toml` for Solidity version:

```bash
grep solc_version foundry.toml
# or
grep solc foundry.toml
```

**Solution:** Ensure local `solc` version matches. Foundry auto-downloads correct version, but verify:

```bash
forge --version
```

## Source File Not Found

**Error:** "Source file not found" or path resolution errors

**Common Causes:**

1. Wrong source path format
2. Remappings not applied
3. OpenZeppelin path variations

**Solutions:**

```bash
# Check remappings
forge remappings

# Use full node_modules path for dependencies
node_modules/@openzeppelin/contracts/...

# For libraries in src/
src/libraries/Library.sol:Library
```

## Verification Pending Forever

**Symptom:** `--watch` never completes

**Causes:**

1. Explorer queue backed up
2. Network issues
3. Invalid submission

**Solutions:**

1. Check explorer directly for status
2. Try without `--watch` and check manually
3. Resubmit verification

```bash
# Without --watch
forge verify-contract ... 2>&1 | grep -i guid

# Then check status manually on explorer
```
