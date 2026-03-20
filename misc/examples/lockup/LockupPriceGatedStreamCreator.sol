// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupPriceGated } from "@sablier/lockup/src/types/LockupPriceGated.sol";

/// @notice Example of how to create a Lockup Price Gated stream.
/// @dev This code is referenced in the docs:
/// https://docs.sablier.com/guides/lockup/examples/create-stream/lockup-price-gated
contract LockupPriceGatedStreamCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ISablierLockup public constant LOCKUP = ISablierLockup(0x93b37Bd5B6b278373217333Ac30D7E74c85fBDCB);

    // Chainlink ETH/USD price feed on Ethereum Mainnet
    AggregatorV3Interface public constant ETH_USD_ORACLE =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function createStream(uint128 depositAmount) public returns (uint256 streamId) {
        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend DAI
        DAI.approve(address(LOCKUP), depositAmount);

        // Declare the params struct
        Lockup.CreateWithTimestamps memory params;

        // Declare the function parameters
        params.sender = msg.sender; // The sender will be able to cancel the stream
        params.recipient = address(0xCAFE); // The recipient of the streamed tokens
        params.depositAmount = depositAmount; // The deposit amount into the stream
        params.token = DAI; // The streaming token
        params.cancelable = true; // Whether the stream will be cancelable or not
        params.transferable = true; // Whether the stream will be transferable or not
        params.timestamps.start = uint40(block.timestamp);
        params.timestamps.end = uint40(block.timestamp + 52 weeks);

        // Declare the unlock parameters. Tokens unlock when ETH price reaches $5,000.
        // Chainlink uses 8 decimals, so $5,000 = 5000e8.
        LockupPriceGated.UnlockParams memory unlockParams = LockupPriceGated.UnlockParams({
            oracle: ETH_USD_ORACLE,
            targetPrice: 5000e8 // $5,000
        });

        // Create the LockupPriceGated stream
        streamId = LOCKUP.createWithTimestampsLPG({ params: params, unlockParams: unlockParams });
    }
}
