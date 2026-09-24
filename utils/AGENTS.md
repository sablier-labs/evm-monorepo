# Sablier EVM Utils

Shared utilities and comptroller contract used across all Sablier protocols.

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

## Import Paths

```solidity
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
```
