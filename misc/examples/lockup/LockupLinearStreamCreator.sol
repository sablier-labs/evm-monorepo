// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupLinear } from "@sablier/lockup/src/types/LockupLinear.sol";

/// @notice Example of how to create a Lockup Linear stream.
/// @dev This code is referenced in the docs:
/// https://docs.sablier.com/guides/lockup/examples/create-stream/lockup-linear
contract LockupLinearStreamCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ISablierLockup public constant LOCKUP = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream(uint128 depositAmount) public returns (uint256 streamId) {
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
            total: 52 weeks // Setting a total duration of ~1 year
         });

        // Create the LockupLinear stream using a function that sets the start time to `block.timestamp`
        streamId = LOCKUP.createWithDurationsLL(params, unlockAmounts, durations);
    }
}
