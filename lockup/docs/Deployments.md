# Deployments

The contracts can be deployed with the deployment scripts available in the [`script`](../script) directory.

To run the scripts, you need to have your environment variables correctly set up, as explained in the
[CONTRIBUTING](../CONTRIBUTING.md) guide.

The examples below deploy to the Goerli testnet, but you can pick any other chain defined under the `[rpc_endpoints]`
section in [`foundry.toml`](../foundry.toml).

If you want to deploy to a local development chain, you can spin up an instance of
[Anvil](https://book.getfoundry.sh/anvil).

## Scripts

### Deploy `SablierV2Comptroller`

```sh
forge script script/deploy/DeployComptroller.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address)" \
  ADMIN_ADDRESS
```

### Deploy `SablierV2LockupLinear`

You should replace the placeholders with the actual arguments you want to pass.

```sh
forge script script/deploy/DeployLockupLinear.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,uint256)" \
  ADMIN_ADDRESS \
  COMPTROLLER_ADDRESS \
  MAX_FEE
```

### Deploy `SablierV2LockupPro`

You should replace the placeholders with the actual arguments you want to pass.

```sh
forge script script/deploy/DeployLockupPro.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,uint256,uint256)" \
  ADMIN_ADDRESS \
  COMPTROLLER_ADDRESS \
  MAX_FEE \
  MAX_SEGMENT_COUNT
```

### Deploy Protocol

```sh
forge script script/deploy/DeployProtocol.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,uint256,uint256)" \
  ADMIN_ADDRESS \
  MAX_FEE \
  MAX_SEGMENT_COUNT
```

### Deploy Test Asset

```sh
forge script script/deploy/DeployTestAsset.s.sol \
  --broadcast \
  --rpc-url goerli
```

## Via IR

The contracts have been deployed to the production chains with the
[`--via-ir`](https://docs.soliditylang.org/en/v0.8.17/ir-breaking-changes.html) flag enabled.

Via IR means that the contracts are compiled with a lot of powerful optimizations, but the cost is very slow compile
times, which are not great for local development. Nonetheless, we want to run our tests against this optimized version
of the contracts, since this is what end users will ultimately interact with.

To get the best of both worlds, we have come up with a set-up where on our local machines we build and test the
contracts normally, but in CI we build and test the contracts with IR enabled. This gives us the freedom to develop and
test the contracts rapidly, but also the peace of mind that they work as expected when deployed (tests pass with and
without IR enabled).
