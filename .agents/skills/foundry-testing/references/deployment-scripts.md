# Deployment Scripts

Patterns for Foundry deployment scripts (`*.s.sol`). Find examples in `scripts/solidity/`.

## Script Location

```
scripts/
└── solidity/
    ├── Deploy*.s.sol        # Contract deployments
    ├── Initialize*.s.sol    # Post-deployment setup
    └── Batch*.s.sol         # Multi-step operations
```

______________________________________________________________________

## Base Script Pattern

```solidity
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "./Base.s.sol";

contract DeployFoo is BaseScript {
    function run() public broadcast returns (address deployed) {
        deployed = address(new Foo(constructorArg));
    }
}
```

______________________________________________________________________

## BaseScript Inheritance

| Component            | Purpose                                 |
| -------------------- | --------------------------------------- |
| `broadcast` modifier | Wraps `vm.startBroadcast/stopBroadcast` |
| `broadcaster`        | Address derived from env vars           |
| Environment vars     | `ETH_FROM`, `MNEMONIC`, `PRIVATE_KEY`   |

______________________________________________________________________

## Environment Variables

| Variable      | Purpose               | Priority |
| ------------- | --------------------- | -------- |
| `ETH_FROM`    | Explicit broadcaster  | 1st      |
| `MNEMONIC`    | Derive from HD wallet | 2nd      |
| `PRIVATE_KEY` | Direct private key    | 3rd      |

______________________________________________________________________

## Script Patterns

### Simple Deployment

```solidity
function run() public broadcast returns (ISablierLockup lockup) {
    lockup = new SablierLockup(initialAdmin, nftDescriptor);
}
```

### Deployment with Verification Args

```solidity
function run() public broadcast returns (ISablierLockup lockup) {
    lockup = new SablierLockup(initialAdmin, nftDescriptor);
    // Constructor args for verification logged automatically
}
```

### Multi-Contract Deployment

```solidity
function run()
    public
    broadcast
    returns (
        ISablierLockup lockup,
        INFTDescriptor nftDescriptor
    )
{
    nftDescriptor = new NFTDescriptor();
    lockup = new SablierLockup(initialAdmin, nftDescriptor);
}
```

### Parameterized Script

```solidity
function run(address admin, address token) public broadcast returns (address) {
    return address(new Vault(admin, token));
}
```

______________________________________________________________________

## Running Scripts

### Simulation (dry run)

```bash
forge script scripts/solidity/Deploy.s.sol \
    --sig "run(address)" <ADMIN_ADDRESS> \
    --rpc-url $RPC_URL
```

### Broadcast (actual deployment)

```bash
forge script scripts/solidity/Deploy.s.sol \
    --sig "run(address)" <ADMIN_ADDRESS> \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify
```

### With Specific Sender

```bash
ETH_FROM=0x... forge script scripts/solidity/Deploy.s.sol \
    --rpc-url $RPC_URL \
    --broadcast
```

______________________________________________________________________

## Verification

| Flag                  | Purpose                              |
| --------------------- | ------------------------------------ |
| `--verify`            | Verify on Etherscan after deploy     |
| `--etherscan-api-key` | API key (or set `ETHERSCAN_API_KEY`) |
| `--verifier-url`      | Custom verifier URL                  |

______________________________________________________________________

## Best Practices

| Practice                     | Reason                               |
| ---------------------------- | ------------------------------------ |
| Always simulate first        | Catch errors before spending gas     |
| Use `broadcast` modifier     | Consistent transaction handling      |
| Return deployed addresses    | Enable script composition            |
| Log constructor args         | Simplify verification                |
| Use deterministic deployment | Reproducible addresses across chains |

______________________________________________________________________

## Deterministic Deployment

For same address across chains, use CREATE2:

```solidity
function run() public broadcast returns (address) {
    bytes32 salt = keccak256("SablierLockup-v1.0.0");
    return address(new SablierLockup{salt: salt}(admin, nftDescriptor));
}
```

______________________________________________________________________

## Post-Deployment Setup

```solidity
contract InitializeFoo is BaseScript {
    function run(address foo, address newAdmin) public broadcast {
        IFoo(foo).transferAdmin(newAdmin);
        IFoo(foo).setParameter(value);
    }
}
```

______________________________________________________________________

## Commands

```bash
# Simulate deployment
forge script scripts/solidity/Deploy.s.sol --rpc-url $RPC_URL

# Deploy and verify
forge script scripts/solidity/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify

# Resume failed verification
forge script scripts/solidity/Deploy.s.sol --rpc-url $RPC_URL --resume
```
