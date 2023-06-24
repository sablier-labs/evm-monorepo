# Deployments

The contracts can be deployed with the deployment scripts available in the [`script`](../script) directory.

To run the scripts, you need to have your environment variables correctly set up, as explained in the
[CONTRIBUTING](../CONTRIBUTING.md) guide.

The examples below deploy to the Goerli testnet, but you can pick any other chain defined under the `[rpc_endpoints]`
section in [`foundry.toml`](../foundry.toml).

If you want to deploy to a local development chain, you can spin up an instance of
[Anvil](https://book.getfoundry.sh/anvil).

## Via IR

The contracts are deployed to production with
[`--via-ir`](https://docs.soliditylang.org/en/v0.8.19/ir-breaking-changes.html) enabled.

Using the Via IR compilation pipeline enables a host of powerful optimizations, albeit at the expense of significantly
slower compilation times, which can hinder local development efficiency. However, it is crucial to test our contracts
against this optimized version, as this is what end users will ultimately interact with.

In order to strike a balance, we have come up with a setup that allows for efficient development and testing on local
machines, while still ensuring compatibility with the IR-enabled version. Our approach involves building and testing the
contracts normally on local machines, while leveraging the CI environment to build and test the IR-enabled contracts.
This ensures rapid development and testing while providing confidence that the contracts function as intended when
deployed (with tests passing both with and without IR enabled).

## Scripts

### Deploy `SablierV2Comptroller`

```shell
forge script script/DeployComptroller.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address)" \
  --verify \
  ADMIN_ADDRESS
```

### Deploy `SablierV2LockupDynamic`

You should replace the placeholders with the actual arguments you want to pass.

```shell
forge script script/DeployLockupDynamic.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,address,address,uint256)" \
  --verify \
  ADMIN_ADDRESS \
  COMPTROLLER_ADDRESS \
  NFT_DESCRIPTOR_ADDRESS \
  MAX_SEGMENT_COUNT
```

### Deploy `SablierV2LockupLinear`

You should replace the placeholders with the actual arguments you want to pass.

```shell
forge script script/DeployLockupLinear.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,address,address)" \
  --verify \
  ADMIN_ADDRESS \
  COMPTROLLER_ADDRESS \
  NFT_DESCRIPTOR_ADDRESS
```

### Deploy All Contracts

```shell
forge script script/DeployCore.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,address,uint256)" \
  --verify \
  ADMIN_ADDRESS \
  NFT_DESCRIPTOR_ADDRESS \
  MAX_SEGMENT_COUNT
```
