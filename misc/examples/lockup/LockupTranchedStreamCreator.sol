// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/LockupTranched.sol";

/// @notice Example of how to create a Lockup Tranched stream.
/// @dev This code is referenced in the docs:
/// https://docs.sablier.com/guides/lockup/examples/create-stream/lockup-tranched
contract LockupTranchedStreamCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ISablierLockup public constant LOCKUP = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream(uint128 amount0, uint128 amount1) public returns (uint256 streamId) {
        // Sum the tranche amounts
        uint128 depositAmount = amount0 + amount1;

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

        // Declare some dummy tranches
        LockupTranched.TrancheWithDuration[] memory tranches = new LockupTranched.TrancheWithDuration[](2);
        tranches[0] = LockupTranched.TrancheWithDuration({ amount: amount0, duration: uint40(4 weeks) });
        tranches[1] = (LockupTranched.TrancheWithDuration({ amount: amount1, duration: uint40(6 weeks) }));

        // Create the LockupTranched stream
        streamId = LOCKUP.createWithDurationsLT(params, tranches);
    }
}
