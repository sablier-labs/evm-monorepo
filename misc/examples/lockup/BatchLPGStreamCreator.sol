// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierBatchLockup } from "@sablier/lockup/src/interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { BatchLockup } from "@sablier/lockup/src/types/BatchLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupPriceGated } from "@sablier/lockup/src/types/LockupPriceGated.sol";

contract BatchLPGStreamCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // See https://docs.sablier.com/guides/lockup/deployments for all deployments
    ISablierLockup public constant LOCKUP = ISablierLockup(0x93b37Bd5B6b278373217333Ac30D7E74c85fBDCB);
    ISablierBatchLockup public constant BATCH_LOCKUP = ISablierBatchLockup(0x4f3be262D1358A82b468CF81bfc5A9cC32Cf9875);

    // Chainlink ETH/USD price feed on Ethereum Mainnet
    AggregatorV3Interface public constant ETH_USD_ORACLE =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function batchCreateStreams(uint128 perStreamAmount) public returns (uint256[] memory streamIds) {
        // Create a batch of two streams
        uint256 batchSize = 2;

        // Calculate the combined amount of DAI tokens to transfer to this contract
        uint256 transferAmount = perStreamAmount * batchSize;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), transferAmount);

        // Approve the Batch contract to spend DAI
        DAI.approve({ spender: address(BATCH_LOCKUP), value: transferAmount });

        // Declare the first stream in the batch
        BatchLockup.CreateWithTimestampsLPG memory stream0;
        stream0.sender = address(0xABCD); // The sender to stream the tokens, he will be able to cancel the stream
        stream0.recipient = address(0xCAFE); // The recipient of the streamed tokens
        stream0.depositAmount = perStreamAmount; // The deposit amount of each stream
        stream0.cancelable = true; // Whether the stream will be cancelable or not
        stream0.transferable = false; // Whether the recipient can transfer the NFT or not
        stream0.timestamps =
            Lockup.Timestamps({ start: uint40(block.timestamp), end: uint40(block.timestamp + 52 weeks) });
        stream0.unlockParams = LockupPriceGated.UnlockParams({
            oracle: ETH_USD_ORACLE,
            targetPrice: 5000e8 // Tokens unlock when ETH reaches $5,000
        });

        // Declare the second stream in the batch
        BatchLockup.CreateWithTimestampsLPG memory stream1;
        stream1.sender = address(0xABCD); // The sender to stream the tokens, he will be able to cancel the stream
        stream1.recipient = address(0xBEEF); // The recipient of the streamed tokens
        stream1.depositAmount = perStreamAmount; // The deposit amount of each stream
        stream1.cancelable = false; // Whether the stream will be cancelable or not
        stream1.transferable = false; // Whether the recipient can transfer the NFT or not
        stream1.timestamps =
            Lockup.Timestamps({ start: uint40(block.timestamp), end: uint40(block.timestamp + 104 weeks) });
        stream1.unlockParams = LockupPriceGated.UnlockParams({
            oracle: ETH_USD_ORACLE,
            targetPrice: 10_000e8 // Tokens unlock when ETH reaches $10,000
        });

        // Fill the batch array
        BatchLockup.CreateWithTimestampsLPG[] memory batch = new BatchLockup.CreateWithTimestampsLPG[](batchSize);
        batch[0] = stream0;
        batch[1] = stream1;

        streamIds = BATCH_LOCKUP.createWithTimestampsLPG(LOCKUP, DAI, batch);
    }
}
