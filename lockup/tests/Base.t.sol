// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BaseTest as CommonBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { ILockupNFTDescriptor } from "src/interfaces/ILockupNFTDescriptor.sol";
import { ISablierBatchLockup } from "src/interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "src/LockupNFTDescriptor.sol";
import { SablierBatchLockup } from "src/SablierBatchLockup.sol";
import { SablierLockup } from "src/SablierLockup.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "src/types/DataTypes.sol";

import { RecipientGood } from "./mocks/Hooks.sol";
import { NFTDescriptorMock } from "./mocks/NFTDescriptorMock.sol";
import { Noop } from "./mocks/Noop.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.t.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { StreamIds, Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Calculations, DeployOptimized, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    StreamIds internal ids;
    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBatchLockup internal batchLockup;
    Defaults internal defaults;
    ISablierLockup internal lockup;
    ILockupNFTDescriptor internal nftDescriptor;
    NFTDescriptorMock internal nftDescriptorMock;
    Noop internal noop;
    RecipientGood internal recipientGood;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Set up the common base.
        CommonBase.setUp();

        // Deploy the base test contracts.
        noop = new Noop();
        recipientGood = new RecipientGood();

        // Label the base test contracts.
        vm.label({ account: address(recipientGood), newLabel: "Good Recipient" });
        vm.label({ account: address(noop), newLabel: "Noop" });

        // Deploy the defaults contract.
        defaults = new Defaults();
        defaults.setToken(dai);

        // Deploy the protocol.
        deployProtocolConditionally();

        // Deploy the NFT descriptor mock.
        nftDescriptorMock = new NFTDescriptorMock();

        // Create users for testing.
        createTestUsers();

        defaults.setUsers(users);

        // Set the variables in the Modifiers contract.
        setVariables(defaults, users);

        // Approve `users.operator` to operate over lockup on behalf of the `users.recipient`.
        setMsgSender(users.recipient);
        lockup.setApprovalForAll(users.operator, true);

        // Set sender as the default caller for the tests.
        setMsgSender(users.sender);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: defaults.FEB_1_2025() });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create users for testing and assign roles if applicable.
    function createTestUsers() internal {
        // Create users for testing. Note that due to ERC-20 approvals, this has to go after the protocol deployment.
        address[] memory spenders = new address[](2);
        spenders[0] = address(batchLockup);
        spenders[1] = address(lockup);

        // Create test users.
        users.alice = createUser("Alice", spenders);
        users.eve = createUser("Eve", spenders);
        users.operator = createUser("Operator", spenders);
        users.recipient = createUser("Recipient", spenders);
        users.sender = createUser("Sender", spenders);
    }

    /// @dev Conditionally deploys the protocol normally or from an optimized source compiled with `--via-ir`.
    /// We cannot use the {DeployProtocol} script because some tests rely on hard coded addresses for the
    /// deployed contracts. Since the script itself would have to be deployed, using it would bump the
    /// deployer's nonce, which would in turn lead to different addresses (recall that the addresses
    /// for contracts deployed via `CREATE` are based on the caller-and-nonce-hash).
    function deployProtocolConditionally() internal {
        if (!isTestOptimizedProfile()) {
            batchLockup = new SablierBatchLockup();
            nftDescriptor = new LockupNFTDescriptor();
            lockup = new SablierLockup(address(comptroller), address(nftDescriptor));
        } else {
            (nftDescriptor, lockup, batchLockup) = deployOptimizedProtocol(address(comptroller));
        }
        vm.label({ account: address(batchLockup), newLabel: "BatchLockup" });
        vm.label({ account: address(lockup), newLabel: "Lockup" });
        vm.label({ account: address(nftDescriptor), newLabel: "NFTDescriptor" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects multiple calls to {ISablierLockup.createWithDurationsLD}.
    function expectMultipleCallsToCreateWithDurationsLD(
        uint64 count,
        Lockup.CreateWithDurations memory params,
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDuration
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithDurationsLD, (params, segmentsWithDuration))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithDurationsLL}.
    function expectMultipleCallsToCreateWithDurationsLL(
        uint64 count,
        Lockup.CreateWithDurations memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        LockupLinear.Durations memory durations
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithDurationsLL, (params, unlockAmounts, durations))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithDurationsLT}.
    function expectMultipleCallsToCreateWithDurationsLT(
        uint64 count,
        Lockup.CreateWithDurations memory params,
        LockupTranched.TrancheWithDuration[] memory tranches
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithDurationsLT, (params, tranches))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithTimestampsLD}.
    function expectMultipleCallsToCreateWithTimestampsLD(
        uint64 count,
        Lockup.CreateWithTimestamps memory params,
        LockupDynamic.Segment[] memory segments
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithTimestampsLD, (params, segments))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithTimestampsLL}.
    function expectMultipleCallsToCreateWithTimestampsLL(
        uint64 count,
        Lockup.CreateWithTimestamps memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint40 cliffTime
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithTimestampsLL, (params, unlockAmounts, cliffTime))
        });
    }

    /// @dev Expects multiple calls to {ISablierLockup.createWithTimestampsLT}.
    function expectMultipleCallsToCreateWithTimestampsLT(
        uint64 count,
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches
    )
        internal
    {
        vm.expectCall({
            callee: address(lockup),
            count: count,
            data: abi.encodeCall(ISablierLockup.createWithTimestampsLT, (params, tranches))
        });
    }
}
