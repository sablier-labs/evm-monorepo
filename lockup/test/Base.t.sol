// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILockupNFTDescriptor } from "src/core/interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockupDynamic } from "src/core/interfaces/ISablierLockupDynamic.sol";
import { ISablierLockupLinear } from "src/core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "src/core/interfaces/ISablierLockupTranched.sol";
import { LockupNFTDescriptor } from "src/core/LockupNFTDescriptor.sol";
import { SablierLockupDynamic } from "src/core/SablierLockupDynamic.sol";
import { SablierLockupLinear } from "src/core/SablierLockupLinear.sol";
import { SablierLockupTranched } from "src/core/SablierLockupTranched.sol";
import { LockupDynamic, LockupLinear, LockupTranched } from "src/core/types/DataTypes.sol";
import { ISablierBatchLockup } from "src/periphery/interfaces/ISablierBatchLockup.sol";
import { ISablierMerkleFactory } from "src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "src/periphery/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";
import { SablierBatchLockup } from "src/periphery/SablierBatchLockup.sol";
import { SablierMerkleFactory } from "src/periphery/SablierMerkleFactory.sol";
import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { RecipientGood } from "./mocks/Hooks.sol";
import { Noop } from "./mocks/Noop.sol";
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

    ISablierBatchLockup internal batchLockup;
    ERC20Mock internal dai;
    Defaults internal defaults;
    ISablierLockupDynamic internal lockupDynamic;
    ISablierLockupLinear internal lockupLinear;
    ISablierLockupTranched internal lockupTranched;
    ISablierMerkleFactory internal merkleFactory;
    ISablierMerkleInstant internal merkleInstant;
    ISablierMerkleLL internal merkleLL;
    ISablierMerkleLT internal merkleLT;
    ILockupNFTDescriptor internal nftDescriptor;
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
        dai.approve({ spender: address(merkleFactory), value: MAX_UINT256 });
        usdt.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupTranched), value: MAX_UINT256 });
        usdt.approve({ spender: address(merkleFactory), value: MAX_UINT256 });
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
            batchLockup = new SablierBatchLockup();
            nftDescriptor = new LockupNFTDescriptor();
            lockupDynamic = new SablierLockupDynamic(users.admin, nftDescriptor, defaults.MAX_SEGMENT_COUNT());
            lockupLinear = new SablierLockupLinear(users.admin, nftDescriptor);
            lockupTranched = new SablierLockupTranched(users.admin, nftDescriptor, defaults.MAX_TRANCHE_COUNT());
            merkleFactory = new SablierMerkleFactory();
        } else {
            (nftDescriptor, lockupDynamic, lockupLinear, lockupTranched, batchLockup, merkleFactory) =
                deployOptimizedProtocol(users.admin, defaults.MAX_SEGMENT_COUNT(), defaults.MAX_TRANCHE_COUNT());
        }

        vm.label({ account: address(batchLockup), newLabel: "BatchLockup" });
        vm.label({ account: address(lockupDynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(lockupLinear), newLabel: "LockupLinear" });
        vm.label({ account: address(lockupTranched), newLabel: "LockupTranched" });
        vm.label({ account: address(merkleFactory), newLabel: "MerkleFactory" });
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

    /// @dev Expects multiple calls to {ISablierLockupDynamic.createWithDurations}, each with the specified
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
            data: abi.encodeCall(ISablierLockupDynamic.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockupLinear.createWithDurations}, each with the specified
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
            data: abi.encodeCall(ISablierLockupLinear.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockupTranched.createWithDurations}, each with the specified
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
            data: abi.encodeCall(ISablierLockupTranched.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockupDynamic.createWithTimestamps}, each with the specified
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
            data: abi.encodeCall(ISablierLockupDynamic.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockupLinear.createWithTimestamps}, each with the specified
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
            data: abi.encodeCall(ISablierLockupLinear.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockupTranched.createWithTimestamps}, each with the specified
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
            data: abi.encodeCall(ISablierLockupTranched.createWithTimestamps, (params))
        });
    }
}
