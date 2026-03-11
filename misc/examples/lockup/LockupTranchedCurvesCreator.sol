// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/LockupTranched.sol";

/// @notice Examples of how to create Lockup Linear streams with different curve shapes.
/// @dev A visualization of the curve shapes can be found in the docs:
/// https://docs.sablier.com/concepts/lockup/stream-shapes#lockup-tranched
/// Visualizing the curves while reviewing this code is recommended. The X axis will be assumed to represent "days".
contract LockupTranchedCurvesCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ISablierLockup public constant LOCKUP = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);

    function createStream_UnlockInSteps() external returns (uint256 streamId) {
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

        // Declare a four-size tranche to match the curve shape
        uint256 trancheSize = 4;
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](trancheSize);

        // The tranches are filled with the same amount and are spaced 25 days apart
        uint128 unlockAmount = uint128(depositAmount / trancheSize);
        for (uint256 i = 0; i < trancheSize; ++i) {
            tranches[i] = LockupTranched.TrancheWithDuration({ amount: unlockAmount, duration: 25 days });
        }

        // Create the Lockup stream using tranche model with periodic unlocks in step
        streamId = LOCKUP.createWithDurationsLT(params, tranches);
    }

    function createStream_MonthlyUnlocks() external returns (uint256 streamId) {
        // Declare the total amount as 120 DAI
        uint128 depositAmount = 120e18;

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

        // Declare a twenty four size tranche to match the curve shape
        uint256 trancheSize = 12;
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](trancheSize);

        // The tranches are spaced 30 days apart (~one month)
        uint128 unlockAmount = uint128(depositAmount / trancheSize);
        for (uint256 i = 0; i < trancheSize; ++i) {
            tranches[i] = LockupTranched.TrancheWithDuration({ amount: unlockAmount, duration: 30 days });
        }

        // Create the Lockup stream using tranche model with web2 style monthly unlocks
        streamId = LOCKUP.createWithDurationsLT(params, tranches);
    }

    function createStream_Timelock() external returns (uint256 streamId) {
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

        // Declare a two-size tranche to match the curve shape
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](1);
        tranches[0] = LockupTranched.TrancheWithDuration({ amount: 100e18, duration: 90 days });

        // Create the Lockup stream using tranche model with full unlock only at the end
        streamId = LOCKUP.createWithDurationsLT(params, tranches);
    }
}
