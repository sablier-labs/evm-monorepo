# Foundry Cheat Codes Reference

## Authoritative Source

The complete cheatcodes reference is in `forge-std`:

```
https://github.com/foundry-rs/forge-std/blob/<version>/src/Vm.sol
```

Check `package.json` for forge-std version, then read that version's `Vm.sol`.

______________________________________________________________________

## Quick Reference

### Time

| Cheatcode              | Usage                |
| ---------------------- | -------------------- |
| `vm.warp(timestamp)`   | Set block.timestamp  |
| `vm.roll(blockNumber)` | Set block.number     |
| `vm.skip(seconds)`     | Skip forward in time |

### Caller

| Cheatcode             | Usage                        |
| --------------------- | ---------------------------- |
| `vm.prank(addr)`      | Set msg.sender for next call |
| `vm.startPrank(addr)` | Set msg.sender for all calls |
| `vm.stopPrank()`      | Reset msg.sender             |

### Expectations

| Cheatcode                     | Usage                             |
| ----------------------------- | --------------------------------- |
| `vm.expectRevert(selector)`   | Expect next call reverts          |
| `vm.expectEmit(emitter)`      | Expect event (call BEFORE action) |
| `vm.expectCall(callee, data)` | Expect function call              |

### State

| Cheatcode                       | Usage                         |
| ------------------------------- | ----------------------------- |
| `vm.deal(addr, amount)`         | Set ETH balance               |
| `deal(token, addr, amount)`     | Set ERC20 balance (StdCheats) |
| `vm.store(target, slot, value)` | Set storage slot              |
| `vm.load(target, slot)`         | Read storage slot             |

### Forking

| Cheatcode                    | Usage              |
| ---------------------------- | ------------------ |
| `vm.createSelectFork(alias)` | Fork and select    |
| `vm.selectFork(forkId)`      | Switch forks       |
| `vm.rollFork(blockNumber)`   | Roll fork to block |

### Fuzzing

| Cheatcode              | Usage                               |
| ---------------------- | ----------------------------------- |
| `vm.assume(condition)` | Skip if false                       |
| `bound(x, min, max)`   | Bound to range (prefer over assume) |

### Other

| Cheatcode              | Usage                 |
| ---------------------- | --------------------- |
| `vm.label(addr, name)` | Label for traces      |
| `vm.snapshot()`        | Create state snapshot |
| `vm.revertTo(id)`      | Revert to snapshot    |

______________________________________________________________________

## Common Patterns

### Persistent Caller

```solidity
function setMsgSender(address sender) internal {
    vm.stopPrank();
    vm.startPrank(sender);
}
```

### Event Assertion

```solidity
vm.expectEmit({ emitter: address(vault) });
emit ITokenVault.EventName({ ... });
vault.action();  // Call AFTER expectEmit
```

### Revert Assertion

```solidity
vm.expectRevert(abi.encodeWithSelector(Errors.Name.selector, arg));
vault.action();  // Call AFTER expectRevert
```

______________________________________________________________________

## External References

- [Vm.sol Source](https://github.com/foundry-rs/forge-std/blob/master/src/Vm.sol)
- [Foundry Cheatcodes Docs](https://getfoundry.sh/reference/cheatcodes)
