# Deployment Checklist

Pre-mainnet deployment checklist for Sablier contracts.

## Pre-Deployment

### Code Readiness

- [ ] All tests passing (`just test-all`)
- [ ] Coverage meets threshold (`just coverage <package>`)
- [ ] BTT trees aligned (`just test-bulloak <package>`)
- [ ] Gas snapshot baseline captured (`forge snapshot`)
- [ ] Contract sizes under 24kb (`forge build --sizes`)
- [ ] Static analysis clean (`slither src/ --exclude-dependencies`)

### Security

- [ ] Audit completed and findings addressed
- [ ] Pre-audit checklist passed (see `pre-audit-checklist.md`)
- [ ] Access control verified for all admin functions
- [ ] Pausability/emergency mechanisms tested (if applicable)

### Configuration

- [ ] Constructor arguments documented
- [ ] Environment variables set:
  - [ ] `RPC_URL` for target network
  - [ ] `PRIVATE_KEY` or `MNEMONIC` for deployer
  - [ ] `ETHERSCAN_API_KEY` for verification
- [ ] Deployer address has sufficient ETH for gas

______________________________________________________________________

## Deployment Execution

### 1. Simulation (Dry Run)

```bash
# Always simulate first
forge script scripts/solidity/Deploy.s.sol \
    --sig "run(address)" <ADMIN_ADDRESS> \
    --rpc-url $RPC_URL \
    -vvvv
```

**Verify in simulation output**:

- [ ] Correct contracts being deployed
- [ ] Constructor arguments as expected
- [ ] No unexpected reverts
- [ ] Gas estimate reasonable

### 2. Broadcast

```bash
forge script scripts/solidity/Deploy.s.sol \
    --sig "run(address)" <ADMIN_ADDRESS> \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

### 3. Record Deployment

Save to deployment record:

```
Network: <chain name>
Block: <deployment block>
Timestamp: <UTC timestamp>
Deployer: <address>
Gas Used: <total gas>
Contracts:
  - <ContractName>: <address>
  - <ContractName2>: <address>
```

______________________________________________________________________

## Post-Deployment Verification

### On-Chain Verification

- [ ] Contract verified on block explorer
- [ ] Source code matches deployed bytecode
- [ ] Constructor args decoded correctly on explorer

### Functional Verification

```bash
# Run post-deployment verification script
forge script scripts/solidity/Verify.s.sol \
    --sig "run(address)" <DEPLOYED_ADDRESS> \
    --rpc-url $RPC_URL
```

**Manual checks**:

- [ ] Owner/admin set correctly
- [ ] Initial parameters as expected
- [ ] Comptroller address correct
- [ ] NFT descriptor connected (if applicable)

### Integration Verification

- [ ] Test transaction succeeds (testnet first)
- [ ] Events emitting correctly
- [ ] Subgraph indexing (if applicable)
- [ ] Frontend integration working

______________________________________________________________________

## Deterministic Deployment

For same address across chains:

### CREATE2 with Salt

```solidity
function run() public broadcast returns (address) {
    bytes32 salt = keccak256("SablierLockup-v2.0.0");
    return address(new SablierLockup{salt: salt}(admin, nftDescriptor));
}
```

### Verification

| Chain    | Expected Address | Verified |
| -------- | ---------------- | -------- |
| Ethereum | 0x...            | [ ]      |
| Arbitrum | 0x...            | [ ]      |
| Optimism | 0x...            | [ ]      |
| Base     | 0x...            | [ ]      |
| Polygon  | 0x...            | [ ]      |

______________________________________________________________________

## Multisig Deployment

For production deployments via Gnosis Safe:

### 1. Prepare Transaction

```bash
# Generate calldata for Safe
forge script scripts/solidity/Deploy.s.sol \
    --sig "run(address)" <ADMIN_ADDRESS> \
    --rpc-url $RPC_URL \
    --json > deployment-tx.json
```

### 2. Safe Transaction Builder

1. Go to Safe Transaction Builder
2. Import contract ABI
3. Set:
   - To: CREATE2 deployer or direct deployment
   - Value: 0
   - Data: from `deployment-tx.json`
4. Simulate via Tenderly

### 3. Collect Signatures

- [ ] Signer 1 approved
- [ ] Signer 2 approved
- [ ] Signer N approved
- [ ] Threshold met

### 4. Execute

- [ ] Transaction executed
- [ ] Transaction confirmed
- [ ] Deployment address recorded

______________________________________________________________________

## Rollback Plan

If deployment fails or issues discovered:

### Immediate Actions

1. **Pause** if pausable and issue is critical
2. **Communicate** to team immediately
3. **Document** the issue and affected transactions

### For Upgradeable Contracts

1. Prepare fix in new implementation
2. Test fix thoroughly
3. Deploy new implementation
4. Queue upgrade (if timelock)
5. Execute upgrade

### For Non-Upgradeable Contracts

1. Deploy fixed version at new address
2. Migrate users/state if needed
3. Update frontend to new address
4. Communicate migration path

______________________________________________________________________

## Post-Launch Monitoring

### First 24 Hours

- [ ] Monitor for unusual transactions
- [ ] Check gas usage patterns
- [ ] Verify events in subgraph
- [ ] Monitor social channels for issues

### First Week

- [ ] Review all admin transactions
- [ ] Check protocol metrics (TVL, volume)
- [ ] Gather user feedback
- [ ] Update documentation

______________________________________________________________________

## Commands Reference

```bash
# Full deployment workflow
just build-optimized <package>     # Build with optimization
forge snapshot                     # Capture gas baseline
forge script ... --broadcast      # Deploy
forge verify-contract ...         # Manual verification if needed

# Verification retry
forge script scripts/solidity/Deploy.s.sol --rpc-url $RPC_URL --resume
```
