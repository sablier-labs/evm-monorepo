// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILockupNFTDescriptor } from "src/interfaces/ILockupNFTDescriptor.sol";
import { ISablierBatchLockup } from "src/interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "src/LockupNFTDescriptor.sol";
import { SablierBatchLockup } from "src/SablierBatchLockup.sol";
import { SablierLockup } from "src/SablierLockup.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "src/types/DataTypes.sol";

import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { RecipientGood } from "./mocks/Hooks.sol";
import { NFTDescriptorMock } from "./mocks/NFTDescriptorMock.sol";
import { Noop } from "./mocks/Noop.sol";
import { ContractWithoutReceive, ContractWithReceive } from "./mocks/Receive.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.t.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Calculations, DeployOptimized, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBatchLockup internal batchLockup;
    ContractWithoutReceive internal contractWithoutReceive;
    ContractWithReceive internal contractWithReceive;
    ERC20Mock internal dai;
    Defaults internal defaults;
    ISablierLockup internal lockup;
    ILockupNFTDescriptor internal nftDescriptor;
    NFTDescriptorMock internal nftDescriptorMock;
    Noop internal noop;
    RecipientGood internal recipientGood;
    ERC20MissingReturn internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        contractWithoutReceive = new ContractWithoutReceive();
        contractWithReceive = new ContractWithReceive();
        dai = new ERC20Mock("Dai Stablecoin", "DAI");
        noop = new Noop();
        recipientGood = new RecipientGood();
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);

        // Label the base test contracts.
        vm.label({ account: address(contractWithoutReceive), newLabel: "Contract without Receive" });
        vm.label({ account: address(contractWithReceive), newLabel: "Contract with Receive" });
        vm.label({ account: address(dai), newLabel: "DAI" });
        vm.label({ account: address(recipientGood), newLabel: "Good Recipient" });
        vm.label({ account: address(noop), newLabel: "Noop" });
        vm.label({ account: address(usdt), newLabel: "USDT" });

        // Create the protocol admin.
        users.admin = payable(makeAddr({ name: "Admin" }));
        vm.deal({ account: users.admin, newBalance: 100 ether });
        vm.startPrank({ msgSender: users.admin });

        // Deploy the defaults contract.
        defaults = new Defaults();
        defaults.setToken(dai);

        // Deploy the protocol.
        deployProtocolConditionally();

        // Deploy the NFT descriptor mock.
        nftDescriptorMock = new NFTDescriptorMock();

        // Create users for testing. Note that due to ERC-20 approvals, this has to go after the protocol deployment.
        users.alice = createUser("Alice");
        users.broker = createUser("Broker");
        users.eve = createUser("Eve");
        users.operator = createUser("Operator");
        users.recipient = createUser("Recipient");
        users.sender = createUser("Sender");

        defaults.setUsers(users);

        // Set the variables in the Modifiers contract.
        setVariables(defaults, users);

        // Approve `users.operator` to operate over lockup on behalf of the `users.recipient`.
        resetPrank({ msgSender: users.recipient });
        lockup.setApprovalForAll(users.operator, true);

        // Set sender as the default caller for the tests.
        resetPrank({ msgSender: users.sender });

        // Warp to July 1, 2024 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: JULY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve `spender` to spend tokens from `from`.
    function approveContract(IERC20 token_, address from, address spender) internal {
        resetPrank({ msgSender: from });
        (bool success,) = address(token_).call(abi.encodeCall(IERC20.approve, (spender, MAX_UINT256)));
        success;
    }

    /// @dev Approves all contracts to spend tokens from the address passed.
    function approveProtocol(address from) internal {
        resetPrank({ msgSender: from });
        dai.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        dai.approve({ spender: address(lockup), value: MAX_UINT256 });
        usdt.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockup), value: MAX_UINT256 });
    }

    /// @dev Generates a user, labels its address, funds it with test tokens, and approves the protocol contracts.
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
            lockup = new SablierLockup(users.admin, nftDescriptor, defaults.MAX_COUNT());
        } else {
            (nftDescriptor, lockup, batchLockup) = deployOptimizedProtocol(users.admin, defaults.MAX_COUNT());
        }
        vm.label({ account: address(batchLockup), newLabel: "BatchLockup" });
        vm.label({ account: address(lockup), newLabel: "Lockup" });
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
    function expectCallToTransfer(IERC20 token, address to, uint256 value) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
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
        IERC20 token,
        uint64 count,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        vm.expectCall({
            callee: address(token),
            count: count,
            data: abi.encodeCall(IERC20.transferFrom, (from, to, value))
        });
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
