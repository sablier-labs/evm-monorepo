# Sablier EVM Utils

Shared utilities and comptroller contract used across all Sablier protocols.

@../CLAUDE.md

## Package Overview

Two main components:

### Comptroller

Standalone admin contract with:

- Fee management across all Sablier protocols
- Authority over admin functions
- Oracle integration for fee calculations

### Utility Contracts

Reusable base contracts:

- `Adminable`: Admin role management
- `Batch`: Batch transaction support
- `Comptrollerable`: Base for contracts governed by a comptroller
- `NoDelegateCall`: Prevent delegate calls
- `RoleAdminable`: Role-based admin management

## Package Structure

```
src/
├── SablierComptroller.sol      # Fee and admin management
├── Adminable.sol               # Admin base contract
├── Batch.sol                   # Batch operations
├── Comptrollerable.sol         # Comptroller integration base
├── NoDelegateCall.sol          # Security modifier
├── RoleAdminable.sol           # Role-based admin
├── interfaces/                 # Public interfaces
├── libraries/                  # Helper libraries
├── mocks/                      # Test mocks
└── tests/                      # Test helpers
tests/
├── integration/                # BTT-based and fuzz tests
├── invariant/                  # Invariant tests
├── fork/                       # Fork tests
├── mocks/                      # Mock contracts
└── utils/                      # Test utilities
scripts/
└── solidity/                   # Deployment scripts
```

## Commands

```bash
just utils::build            # Build
just utils::test             # Run tests
just utils::test-lite        # Fast tests (no optimizer)
just utils::coverage         # Coverage report
just utils::full-check       # All checks
```

## Import Paths

```solidity
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
```
