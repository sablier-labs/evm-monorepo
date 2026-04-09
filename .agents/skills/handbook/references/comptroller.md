# Comptroller

The `SablierComptroller` is the protocol's admin contract that manages settings across all protocols. This contract is
upgradeable through an `ERC1967Proxy`.

## Admin Functions

These are the functions with `onlyComptroller` modifier.

| Protocol | Admin Functions (some examples)                |
| -------- | ---------------------------------------------- |
| Lockup   | Allow hooks, recover funds, set NFT descriptor |
| Flow     | Recover funds, set NFT descriptor              |
| Airdrops | Set native token                               |

Any function not mentioned above but has `onlyComptroller` modifier is considered an admin function.

## Governance Characteristics

- **No timelocks**: Changes execute immediately
- **Non-upgradeable**: Contracts are not upgradeable except for Sablier Comptroller
- **Non-pausable**: Protocol cannot be halted
- **No escape hatches**: Admin cannot access user funds

## Comptrollerable

Base contract that protocol contracts inherit to allow the comptroller to take administrative actions. It can be
imported from `@sablier/evm-utils` package. This contract has the `onlyComptroller` modifier that can be used to
restrict functions to only be called by the comptroller.

### References

Refer to https://docs.sablier.com/concepts/governance.md for up-to-date documentation on Comptroller.
