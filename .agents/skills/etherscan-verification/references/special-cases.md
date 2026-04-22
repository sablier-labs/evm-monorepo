# Special Cases

## Proxy Contracts (ERC1967)

Proxy pattern requires verifying **both** implementation and proxy contracts.

### Identifying Proxy Deployments

In Foundry broadcast JSON, proxy deployments typically show 3 transactions:

```json
{
  "transactions": [
    { "contractName": "Implementation", "contractAddress": "0xIMPL..." },
    { "contractName": "ERC1967Proxy", "contractAddress": "0xPROXY..." },
    { "contractName": null, "function": "initialize(...)" }
  ]
}
```

### Step 1: Verify Implementation

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <IMPLEMENTATION_ADDRESS> \
  src/<Implementation>.sol:<Implementation> \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

### Step 2: Get Initialize Calldata

Extract from broadcast JSON:

```bash
INIT_CALLDATA=$(jq -r '.transactions[2].transaction.input' broadcast/<Script>/<CHAIN_ID>/run-latest.json)
```

### Step 3: Encode Proxy Constructor Args

```bash
CONSTRUCTOR_ARGS=$(cast abi-encode \
  "constructor(address,bytes)" \
  <IMPLEMENTATION_ADDRESS> \
  $INIT_CALLDATA)
```

### Step 4: Verify Proxy

Use `node_modules` path for OpenZeppelin contracts:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <PROXY_ADDRESS> \
  node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $CONSTRUCTOR_ARGS \
  --watch
```

### Common Path Issues

| Attempted Path                   | Correct Path                               |
| -------------------------------- | ------------------------------------------ |
| `@openzeppelin/contracts/...`    | `node_modules/@openzeppelin/contracts/...` |
| `lib/openzeppelin-contracts/...` | Check actual location in project           |

## Factory-Created Contracts (CREATE2)

Contracts deployed via factory have constructor args embedded in the factory call's `initCode`.

### Extracting Constructor Args

```bash
# Get solc version from foundry.toml
grep solc foundry.toml

# Get initCode from broadcast
jq -r '.transactions[0].transaction.input' \
  broadcast/<Script>/<CHAIN_ID>/run-latest.json > /tmp/initcode.txt

# Extract args (pass solc version)
python scripts/extract_constructor_args.py /tmp/initcode.txt 0.8.29
```

The script finds the Solidity metadata hash (`64736f6c6343` + version + `0033`) and returns everything after it.

### Verification Command

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args <EXTRACTED_ARGS> \
  --watch
```

### Important Notes

- `--guess-constructor-args` does NOT work with custom `--verifier-url`
- Constructor args must be ABI-encoded, prefixed with `0x`
- Factory return values are in broadcast `returns` field, not `contractAddress`

## Library Contracts

Libraries require full source path including directory:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <LIBRARY_ADDRESS> \
  src/libraries/<Library>.sol:<Library> \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

Libraries typically have no constructor arguments.

## Contracts with Complex Constructor Args

For contracts with struct or array constructor parameters:

```bash
# Example: constructor(address admin, Config memory config)
cast abi-encode \
  "constructor(address,(uint256,bool,address))" \
  0xADMIN... \
  "(1000,true,0xTOKEN...)"
```

For nested structs, use nested tuple syntax matching the struct definition order.
