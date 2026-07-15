---
argument-hint: <chain-name-or-id> [airdrops|flow|lockup|all]
disable-model-invocation: false
name: protocol-deployment
user-invocable: true
description:
  Deploy Sablier protocols to a new EVM chain. Use for deployment preparation, dry runs, broadcasts, resumes,
  post-deployment checks, or runbooks involving airdrops/, flow/, lockup/, and their Comptroller prerequisite.
---

# Protocol Deployment

Prepare and execute evidence-backed deployments of Sablier Airdrops, Flow, and Lockup to a new EVM chain.

## Arguments

- Resolve the first argument as the target chain name or numeric chain ID.
- Default the package selection to `all`; otherwise limit work to the named packages and their prerequisites.

## Contract

- Treat deployment preparation, simulation, and reporting as read-only or local work.
- Treat `--broadcast`, contract verification submissions, Safe creation, role changes, and other on-chain writes as
  external writes. Require explicit user authorization immediately before the first such action.
- Never read, print, log, or echo an existing `.env`, mnemonic, private key, keystore password, or API key. Ask the user
  to populate secrets; inspect only variable names, example files, permissions, and signer addresses.
- Preserve deterministic deployment inputs: repository revision, package version, optimizer profile, constructor
  arguments, salt logic, CREATE2 deployer, and admin selection.
- Unless the user specifies another address, propose `0xcB88fBf459000853F22a7296b23d163901BB385E` as the initial admin
  for new deployments. Do not assume the broadcaster is also the admin. Confirm the proposed admin before broadcast. If
  a legacy bootstrap requires a transient upgrader, disclose it and transfer control to the proposed admin before
  deploying dependent protocols.
- For an existing protocol release, resolve the canonical deployment commit, package version, compiler settings,
  creation bytecode, runtime bytecode, and salt version from `~/sablier/sdk/deployments` when that checkout is
  available. Treat checked-in artifacts, broadcasts, and on-chain code as authoritative when their README prose
  conflicts.
- A newer branch is acceptable only after its creation and runtime bytecode match the canonical SDK artifacts exactly.
  Matching bytecode does not permit a different package version to silently change `BaseScript`'s CREATE2 salt; pin the
  documented release version separately and record how it was pinned.
- Stop before broadcast when the chain ID, administrator, broadcaster, CREATE2 factory, Comptroller address, package
  selection, or funding is unresolved.
- Finish only after recording transaction hashes, deployed addresses, receipt status, runtime code, constructor
  relationships, and any incomplete verification or repository bookkeeping.

## Workflow

### 1. Inspect the Deployment Surface

Read the root and applicable package `AGENTS.md` files. Do not read `TODO.md`. Inspect rather than assume:

- Root and package `justfile` deployment recipes and their package ordering.
- `.env.example`, root `.gitignore`, `foundry.base.toml`, and package `foundry.toml` files.
- `utils/src/tests/BaseScript.sol` and `utils/src/tests/ChainId.sol`.
- The selected packages' deterministic and non-deterministic deployment scripts.
- Flow and Lockup NFT descriptor address maps.
- Current package versions, salts, constructor arguments, and broadcast artifact paths.
- The matching SDK deployment README, broadcast commit, artifacts, and transaction inputs for an already-deployed
  release. Inspect the deployment commit's pinned Foundry version and use it when current tooling does not reproduce the
  canonical artifacts.

Snapshot `git status --short` before generators, builds, simulations, or broadcasts. Ignore unrelated changes from other
agents and do not modify or report them.

Completion criterion: identify the exact scripts, prerequisite graph, signer-selection path, admin-selection path,
canonical release commit and salt version, and expected deployment artifacts for every selected package. Either use the
canonical deployment checkout or prove byte-for-byte creation and runtime parity for every deployed contract.

### 2. Resolve and Probe the Chain

Use `$evm-atlas` to resolve the target mainnet, native token, authoritative chain ID, public RPC, RouteMesh support,
provider route, and explorer. If Atlas does not support the chain, surface that limitation and request authoritative
chain data rather than silently substituting another chain or RPC.

Prefer the Atlas public RPC when `routeMesh` is false. Before any live or API command, run harmless prerequisites and
identify local files it may create.

Run the bundled read-only helper from the repository root:

```shell
bash '.agents/skills/protocol-deployment/scripts/preflight.sh' '<RPC_URL>' '<CHAIN_ID>'
```

It verifies `eth_chainId`, requires code at Foundry's canonical CREATE2 deployer
`0x4e59b44847b379578588920cA78FbF26c0B4956C`, and reports whether the expected Sablier Comptroller proxy
`0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399` already has code. Pass a fourth argument only when repository evidence
selects a chain-specific Comptroller address.

Completion criterion: the RPC returns the expected chain ID, the deterministic deployer has code, and current
Comptroller state is known.

### 3. Prepare New-Chain Support

If `ChainId.isSupported` rejects the chain, make the minimum conventional change in `utils/src/tests/ChainId.sol`:

- Increment the relevant count.
- Add the chain constant.
- Insert it into the corresponding chain array without leaving uninitialized entries.
- Add its canonical lowercase name to `getName`.

Add an RPC alias to `foundry.base.toml` only when it improves the workflow; a full `--rpc-url` is sufficient. Do not add
a RouteMesh endpoint when Atlas reports `routeMesh: false`.

Do not pre-populate Flow or Lockup NFT descriptor maps with predicted addresses. Their scripts use a zero mapping entry
to decide that the descriptor must be deployed. Add the actual addresses after successful deployment.

Validate the narrow change with the Utils tests/checks and optimized builds for only the selected packages. Inspect the
relevant recipes first and prefer `just` when they provide the needed signal.

Completion criterion: `getComptroller()` accepts the target chain and all selected optimized deployment scripts build
without changing unrelated files.

### 4. Separate Broadcaster from Administrator

Establish both roles explicitly:

- **Broadcaster**: pays gas and signs deployment transactions.
- **Comptroller admin**: controls protocol administration after deployment and is selected by `getAdmin()`; it is not
  automatically the broadcaster.

Inspect `getAdmin()`, including default EOA and shared multisig branches. Check whether a selected Safe address has
runtime code and is controllable on the target chain. Do not select an undeployed or uncontrolled Safe merely to match
another chain.

Use the repository-root `.env`, which `just setup` symlinks into packages. For mnemonic mode, instruct the user to set
only:

```dotenv
MNEMONIC="..."
```

Remove `ETH_FROM`; it takes precedence. `BaseScript` derives mnemonic index `0` and remembers that key for Forge.

For a raw private key, instruct the user to set:

```dotenv
ETH_FROM="0xBROADCASTER"
PRIVATE_KEY="0xPRIVATE_KEY"
```

Export the file in the user's shell and pass `--private-key "$PRIVATE_KEY"` to every Forge/`just` deployment command.
The Solidity scripts read `ETH_FROM`, not `PRIVATE_KEY`; the Forge CLI needs the latter to sign. Prefer a Foundry
keystore or interactive signer when the user wants to avoid a raw key in process arguments.

Ensure `.env` is ignored and mode `600`. Derive or obtain the public broadcaster address without displaying secret
material, then verify sufficient native-token funding.

Completion criterion: the user confirms the intended Comptroller admin, and the selected broadcaster is available to
Forge and funded.

### 5. Deploy the Comptroller Prerequisite

Every selected protocol constructor obtains and validates a Comptroller. When its expected proxy has no code, deploy the
proxy before any protocol.

Inspect `utils/justfile` before choosing a recipe. In this repository, `utils::deploy` may target only
`DeployDeterministicComptrollerImpl.s.sol`, which is for chains where the proxy already exists. A fresh chain requires
`utils/scripts/solidity/DeployDeterministicComptrollerProxy.s.sol` unless current repository evidence says otherwise.

Before using the fresh-proxy script from a newer Utils release, inspect the SDK Comptroller history. The vanity proxy
salt commits to both the proxy creation bytecode and its initial implementation address. If the proxy was originally
created by an older release, replay that canonical proxy deployment first, then deploy and upgrade to each required
newer implementation. Do not reuse the old vanity salt with a newer implementation and accept a different proxy address;
the script's expected-address assertion must pass in simulation.

Simulate with the optimized profile and exact broadcast arguments, omitting only `--broadcast` and verification flags.
Inspect the trace, predicted addresses, transactions, admin, initializer values, and gas. After explicit broadcast
authorization, rerun with `--broadcast --slow`.

Confirm successful receipts and runtime code at the expected proxy before continuing. If submission stops after any
transaction, preserve the broadcast artifact and use `--resume`; do not restart a deterministic multi-transaction script
from scratch.

Completion criterion: the expected Comptroller proxy has code, its implementation and initialized admin are correct, and
the deployment transaction hashes are recorded.

### 6. Deploy the Selected Protocols

Default to this human-readable order after the Comptroller:

1. Lockup
2. Flow
3. Airdrops

There is no deployment-time dependency among these three in the current scripts; Airdrops factories do not require the
fresh Lockup address. Reconfirm this from constructors whenever the scripts change.

Use each package's optimized deterministic recipe. Simulate each exact command first, then request broadcast authority
once the simulations and total funding estimate are available. Broadcast sequentially with `--slow`. Include
`--private-key "$PRIVATE_KEY"` only for raw-key mode.

Do not use root `deploy-all` without inspecting its current package set and order. It may include Bob and may run Utils
after dependent protocols, which expands scope and violates the prerequisite order.

On a partial run, use that script's broadcast artifact with `--resume`. A descriptor may already exist even while its
chain map still returns zero, so rerunning from the beginning can revert at CREATE2.

Completion criterion: every selected script has only successful receipts and every reported contract address has runtime
code on the target chain.

### 7. Verify and Reconcile

Extract contract names, addresses, and transaction hashes from each package's
`broadcast/<Script>.s.sol/<CHAIN_ID>/run-latest.json`. Verify on-chain:

- Comptroller proxy implementation, admin, oracle, and initialized fee settings.
- Each protocol or factory's Comptroller address.
- Flow and Lockup NFT descriptor relationships.
- Runtime code at every deployment address.

Add the deployed descriptor addresses to the Flow and Lockup address maps after the first successful deployment, then
run narrow formatting/build validation. Keep these bookkeeping edits distinct from already-broadcast bytecode inputs.

When contract verification is requested, use `$explorer-contract-verification` with the Atlas-resolved explorer. Treat
verification as a separate external write and report partial verifier failures without implying deployment failure.

Report the resolved chain/provider route, repository revision, broadcaster address, admin address, deployed contract
table, transaction hashes, explorer links, validations, verification status, and any incomplete history or manual
follow-up. Never include secret values.
