// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupLinear } from "@sablier/lockup/src/types/LockupLinear.sol";

/// @notice Examples of how to create Lockup Linear streams with different curve shapes.
/// @dev A visualization of the curve shapes can be found in the docs:
/// https://docs.sablier.com/concepts/lockup/stream-shapes#lockup-linear
/// Visualizing the curves while reviewing this code is recommended. The X axis will be assumed to represent "days".
contract LockupLinearCurvesCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ISablierLockup public constant LOCKUP = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream_Linear() public returns (uint256 streamId) {
        // Declare the total amount as 100 DAI
        uint128 depositAmount = 100e18;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not

        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 0, cliff: 0 });
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 0, // Setting a cliff of 0
            total: 100 days // Setting a total duration of 100 days
         });

        // Create the Lockup stream with Linear shape, no cliff and start time as `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream_CliffUnlock() public returns (uint256 streamId) {
        // Declare the total amount as 100 DAI
        uint128 depositAmount = 100e18;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not

        // Setting a cliff unlock amount of 25 DAI
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 0, cliff: 25e18 });
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 25 days, // Setting a cliff of 25 days
            total: 100 days // Setting a total duration of 100 days
         });

        // Create the Lockup stream with Linear shape, a cliff and start time as `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream_InitialUnlock() public returns (uint256 streamId) {
        // Declare the total amount as 100 DAI
        uint128 depositAmount = 100e18;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not

        // Setting an initial unlock amount of 25 DAI
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 25e18, cliff: 0 });
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 0, // Setting a cliff of 0
            total: 100 days // Setting a total duration of 100 days
         });

        // Create the Lockup stream with Linear shape, an initial unlock, no cliff and start time as `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream_InitialCliffUnlock() public returns (uint256 streamId) {
        // Declare the total amount as 100 DAI
        uint128 depositAmount = 100e18;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not

        // Setting an initial and a cliff unlock amount of 25 DAI
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 25e18, cliff: 25e18 });
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 50 days, // Setting a cliff of 50 days
            total: 100 days // Setting a total duration of 100 days
         });

        // Create the Lockup stream with Linear shape, an initial unlock, a cliff and start time as `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream_ConstantCliff() public returns (uint256 streamId) {
        // Declare the total amount as 100 DAI
        uint128 depositAmount = 100e18;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not

        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 0, cliff: 0 });
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 25 days, // Setting a cliff of 25 days
            total: 100 days // Setting a total duration of 100 days
         });

        // Create the Lockup stream with Linear shape, zero unlock until cliff and start time as `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream_InitialUnlockConstantCliff() public returns (uint256 streamId) {
        // Declare the total amount as 100 DAI
        uint128 depositAmount = 100e18;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithDurations memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not

        // Setting an initial unlock amount of 25 DAI
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({ start: 25e18, cliff: 0 });
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 25 days, // Setting a cliff of 25 days
            total: 100 days // Setting a total duration of 100 days
         });

        // Create the Lockup stream with Linear shape, an initial unlock followed by zero unlock until cliff and start
        // time as `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }
}
