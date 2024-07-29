// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2LockupDynamic } from "src/core/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "src/core/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupTranched } from "src/core/interfaces/ISablierV2LockupTranched.sol";
import { ISablierV2NFTDescriptor } from "src/core/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2LockupDynamic } from "src/core/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "src/core/SablierV2LockupLinear.sol";
import { SablierV2LockupTranched } from "src/core/SablierV2LockupTranched.sol";
import { SablierV2NFTDescriptor } from "src/core/SablierV2NFTDescriptor.sol";
import { LockupDynamic, LockupLinear, LockupTranched } from "src/core/types/DataTypes.sol";
import { ISablierV2MerkleLockupFactory } from "src/periphery/interfaces/ISablierV2MerkleLockupFactory.sol";
import { ISablierV2BatchLockup } from "src/periphery/interfaces/ISablierV2BatchLockup.sol";
import { ISablierV2MerkleLL } from "src/periphery/interfaces/ISablierV2MerkleLL.sol";
import { ISablierV2MerkleLT } from "src/periphery/interfaces/ISablierV2MerkleLT.sol";
import { SablierV2BatchLockup } from "src/periphery/SablierV2BatchLockup.sol";
import { SablierV2MerkleLockupFactory } from "src/periphery/SablierV2MerkleLockupFactory.sol";

import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { Noop } from "./mocks/Noop.sol";
import { RecipientGood } from "./mocks/Hooks.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { Events } from "./utils/Events.sol";
import { Fuzzers } from "./utils/Fuzzers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Calculations, Constants, DeployOptimized, Events, Fuzzers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2BatchLockup internal batchLockup;
    ERC20Mock internal dai;
    Defaults internal defaults;
    ISablierV2LockupDynamic internal lockupDynamic;
    ISablierV2LockupLinear internal lockupLinear;
    ISablierV2LockupTranched internal lockupTranched;
    ISablierV2MerkleLockupFactory internal merkleLockupFactory;
    ISablierV2MerkleLL internal merkleLL;
    ISablierV2MerkleLT internal merkleLT;
    ISablierV2NFTDescriptor internal nftDescriptor;
    Noop internal noop;
    RecipientGood internal recipientGood;
    ERC20MissingReturn internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new ERC20Mock("Dai Stablecoin", "DAI");
        recipientGood = new RecipientGood();
        noop = new Noop();
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });
        vm.label({ account: address(recipientGood), newLabel: "Good Recipient" });
        vm.label({ account: address(noop), newLabel: "Noop" });
        vm.label({ account: address(usdt), newLabel: "USDT" });

        // Create the protocol admin.
        users.admin = payable(makeAddr({ name: "Admin" }));
        vm.startPrank({ msgSender: users.admin });

        // Deploy the defaults contract.
        defaults = new Defaults();
        defaults.setAsset(dai);

        // Deploy the protocol.
        deployProtocolConditionally();

        // Create users for testing.
        users.alice = createUser("Alice");
        users.broker = createUser("Broker");
        users.eve = createUser("Eve");
        users.operator = createUser("Operator");
        users.recipient = createUser("Recipient");
        users.recipient1 = createUser("Recipient1");
        users.recipient2 = createUser("Recipient2");
        users.recipient3 = createUser("Recipient3");
        users.recipient4 = createUser("Recipient4");
        users.sender = createUser("Sender");

        defaults.setUsers(users);
        defaults.initMerkleTree();

        // Warp to July 1, 2024 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: JULY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve `spender` to spend assets from `from`.
    function approveContract(IERC20 asset_, address from, address spender) internal {
        resetPrank({ msgSender: from });
        (bool success,) = address(asset_).call(abi.encodeCall(IERC20.approve, (spender, MAX_UINT256)));
        success;
    }

    /// @dev Approves all contracts to spend assets from the address passed.
    function approveProtocol(address from) internal {
        resetPrank({ msgSender: from });
        dai.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        dai.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        dai.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });
        dai.approve({ spender: address(lockupTranched), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleLockupFactory), value: MAX_UINT256 });
        usdt.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupTranched), value: MAX_UINT256 });
        usdt.approve({ spender: address(merkleLockupFactory), value: MAX_UINT256 });
    }

    /// @dev Generates a user, labels its address, funds it with test assets, and approves the protocol contracts.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        approveProtocol({ from: user });
        return user;
    }

    /// @dev Conditionally deploys the protocol normally or from an optimized source compiled with `--via-ir`.
    /// We cannot use the {DeployProtocol} script because some tests rely on hard coded addresses for the
    /// deployed contracts. Since the script itself would have to be deployed, using it would bump the
    /// deployer's nonce, which would in turn lead to different addresses (recall that the addresses
    /// for contracts deployed via `CREATE` are based on the caller-and-nonce-hash).
    function deployProtocolConditionally() internal {
        if (!isBenchmarkProfile() && !isTestOptimizedProfile()) {
            batchLockup = new SablierV2BatchLockup();
            nftDescriptor = new SablierV2NFTDescriptor();
            lockupDynamic = new SablierV2LockupDynamic(users.admin, nftDescriptor, defaults.MAX_SEGMENT_COUNT());
            lockupLinear = new SablierV2LockupLinear(users.admin, nftDescriptor);
            lockupTranched = new SablierV2LockupTranched(users.admin, nftDescriptor, defaults.MAX_TRANCHE_COUNT());
            merkleLockupFactory = new SablierV2MerkleLockupFactory();
        } else {
            (lockupDynamic, lockupLinear, lockupTranched, nftDescriptor, batchLockup, merkleLockupFactory) =
                deployOptimizedProtocol(users.admin, defaults.MAX_SEGMENT_COUNT(), defaults.MAX_TRANCHE_COUNT());
        }

        vm.label({ account: address(batchLockup), newLabel: "BatchLockup" });
        vm.label({ account: address(lockupDynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(lockupLinear), newLabel: "LockupLinear" });
        vm.label({ account: address(lockupTranched), newLabel: "LockupTranched" });
        vm.label({ account: address(merkleLockupFactory), newLabel: "MerkleLockupFactory" });
        vm.label({ account: address(nftDescriptor), newLabel: "NFTDescriptor" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - IERC20
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 asset, address to, uint256 value) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 asset, address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /// @dev Expects multiple calls to {IERC20.transfer}.
    function expectMultipleCallsToTransfer(uint64 count, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), count: count, data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects multiple calls to {IERC20.transferFrom}.
    function expectMultipleCallsToTransferFrom(uint64 count, address from, address to, uint256 value) internal {
        expectMultipleCallsToTransferFrom(dai, count, from, to, value);
    }

    /// @dev Expects multiple calls to {IERC20.transferFrom}.
    function expectMultipleCallsToTransferFrom(
        IERC20 asset,
        uint64 count,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        vm.expectCall({
            callee: address(asset),
            count: count,
            data: abi.encodeCall(IERC20.transferFrom, (from, to, value))
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects multiple calls to {ISablierV2LockupDynamic.createWithDurations}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithDurationsLD(
        uint64 count,
        LockupDynamic.CreateWithDurations memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupDynamic),
            count: count,
            data: abi.encodeCall(ISablierV2LockupDynamic.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupLinear.createWithDurations}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithDurationsLL(
        uint64 count,
        LockupLinear.CreateWithDurations memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupLinear),
            count: count,
            data: abi.encodeCall(ISablierV2LockupLinear.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupTranched.createWithDurations}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithDurationsLT(
        uint64 count,
        LockupTranched.CreateWithDurations memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupTranched),
            count: count,
            data: abi.encodeCall(ISablierV2LockupTranched.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupDynamic.createWithTimestamps}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLD(
        uint64 count,
        LockupDynamic.CreateWithTimestamps memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupDynamic),
            count: count,
            data: abi.encodeCall(ISablierV2LockupDynamic.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupLinear.createWithTimestamps}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLL(
        uint64 count,
        LockupLinear.CreateWithTimestamps memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupLinear),
            count: count,
            data: abi.encodeCall(ISablierV2LockupLinear.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupTranched.createWithTimestamps}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLT(
        uint64 count,
        LockupTranched.CreateWithTimestamps memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupTranched),
            count: count,
            data: abi.encodeCall(ISablierV2LockupTranched.createWithTimestamps, (params))
        });
    }
}
