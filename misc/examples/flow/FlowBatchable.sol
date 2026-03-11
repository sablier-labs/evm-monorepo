// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "@sablier/flow/src/interfaces/ISablierFlow.sol";

/// @notice The `Batch` contract, inherited in SablierFlow, allows multiple function calls to be batched together. This
/// enables any possible combination of functions to be executed within a single transaction.
/// @dev For some functions to work, `msg.sender` must have approved this contract to spend USDC.
contract FlowBatchable {
    // Mainnet addresses
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ISablierFlow public constant FLOW = ISablierFlow(0x7a86d3e6894f9c5B5f25FFBDAaE658CFc7569623);

    /// @dev A function to adjust the rate per second and deposit into a stream in a single transaction.
    /// Note: The streamId's sender must be this contract, otherwise, the call will fail due to no authorization.
    function adjustRatePerSecondAndDeposit(uint256 streamId) external {
        UD21x18 newRatePerSecond = ud21x18(0.0002e18);
        uint128 depositAmount = 1000e6;

        // Transfer to this contract the amount to deposit in the stream.
        USDC.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend USDC.
        USDC.approve(address(FLOW), depositAmount);

        // Fetch the stream recipient.
        address recipient = FLOW.getRecipient(streamId);

        // The call data declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(FLOW.adjustRatePerSecond, (streamId, newRatePerSecond));
        calls[1] = abi.encodeCall(FLOW.deposit, (streamId, depositAmount, msg.sender, recipient));

        FLOW.batch(calls);
    }

    /// @dev A function to create a stream and deposit in a single transaction.
    function createAndDeposit() external returns (uint256 streamId) {
        address sender = msg.sender;
        address recipient = address(0xCAFE);
        UD21x18 ratePerSecond = ud21x18(0.0001e18);
        uint128 depositAmount = 1000e6;
        bool transferable = true;

        // Transfer to this contract the amount to deposit in the stream.
        USDC.transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Sablier contract to spend USDC.
        USDC.approve(address(FLOW), depositAmount);

        streamId = FLOW.nextStreamId();

        // The call data declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] =
            abi.encodeCall(FLOW.create, (sender, recipient, ratePerSecond, uint40(block.timestamp), USDC, transferable));
        calls[1] = abi.encodeCall(FLOW.deposit, (streamId, depositAmount, sender, recipient));

        // Execute multiple calls in a single transaction using the prepared call data.
        FLOW.batch(calls);
    }

    /// @dev A function to create multiple streams in a single transaction.
    function createMultiple() external returns (uint256[] memory streamIds) {
        address sender = msg.sender;
        address firstRecipient = address(0xCAFE);
        address secondRecipient = address(0xBEEF);
        UD21x18 firstRatePerSecond = ud21x18(0.0001e18);
        UD21x18 secondRatePerSecond = ud21x18(0.0002e18);
        bool transferable = true;

        // The call data declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(
            FLOW.create, (sender, firstRecipient, firstRatePerSecond, uint40(block.timestamp), USDC, transferable)
        );
        calls[1] = abi.encodeCall(
            FLOW.create, (sender, secondRecipient, secondRatePerSecond, uint40(block.timestamp), USDC, transferable)
        );

        // Prepare the `streamIds` array to return them
        uint256 nextStreamId = FLOW.nextStreamId();
        streamIds = new uint256[](2);
        streamIds[0] = nextStreamId;
        streamIds[1] = nextStreamId + 1;

        // Execute multiple calls in a single transaction using the prepared call data.
        FLOW.batch(calls);
    }

    /// @dev A function to create multiple streams and deposit into all the streams in a single transaction.
    function createMultipleAndDeposit() external returns (uint256[] memory streamIds) {
        address sender = msg.sender;
        address firstRecipient = address(0xCAFE);
        address secondRecipient = address(0xBEEF);
        UD21x18 ratePerSecond = ud21x18(0.0001e18);
        uint128 depositAmount = 1000e6;
        bool transferable = true;

        // Transfer the deposit amount of USDC tokens to this contract for both streams
        USDC.transferFrom(msg.sender, address(this), 2 * depositAmount);

        // Approve the Sablier contract to spend USDC.
        USDC.approve(address(FLOW), 2 * depositAmount);

        uint256 nextStreamId = FLOW.nextStreamId();
        streamIds = new uint256[](2);
        streamIds[0] = nextStreamId;
        streamIds[1] = nextStreamId + 1;

        // We need to have 4 different function calls, 2 for creating streams and 2 for depositing
        bytes[] memory calls = new bytes[](4);
        calls[0] = abi.encodeCall(
            FLOW.create, (sender, firstRecipient, ratePerSecond, uint40(block.timestamp), USDC, transferable)
        );
        calls[1] = abi.encodeCall(
            FLOW.create, (sender, secondRecipient, ratePerSecond, uint40(block.timestamp), USDC, transferable)
        );
        calls[2] = abi.encodeCall(FLOW.deposit, (streamIds[0], depositAmount, sender, firstRecipient));
        calls[3] = abi.encodeCall(FLOW.deposit, (streamIds[1], depositAmount, sender, secondRecipient));

        // Execute multiple calls in a single transaction using the prepared call data.
        FLOW.batch(calls);
    }

    /// @dev A function to pause a stream and withdraw the maximum available funds.
    /// Note: The streamId's sender must be this contract, otherwise, the call will fail due to no authorization.
    function pauseAndWithdrawMax(uint256 streamId) external payable {
        // The call data declared as bytes.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(FLOW.pause, (streamId));
        calls[1] = abi.encodeCall(FLOW.withdrawMax, (streamId, address(0xCAFE)));

        // Calculate the fee.
        uint256 fee = FLOW.calculateMinFeeWei(streamId);

        // Execute multiple calls in a single transaction using the prepared call data.
        FLOW.batch{ value: fee }(calls);
    }

    /// @dev A function to void a stream and withdraw what is left.
    /// Note: The streamId's sender must be this contract, otherwise, the call will fail due to no authorization.
    function voidAndWithdrawMax(uint256 streamId) external payable {
        // The call data declared as bytes
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(FLOW.void, (streamId));
        calls[1] = abi.encodeCall(FLOW.withdrawMax, (streamId, address(0xCAFE)));

        // Calculate the fee.
        uint256 fee = FLOW.calculateMinFeeWei(streamId);

        // Execute multiple calls in a single transaction using the prepared call data.
        FLOW.batch{ value: fee }(calls);
    }

    /// @dev A function to withdraw maximum available funds from multiple streams in a single transaction.
    function withdrawMaxMultiple(uint256[] calldata streamIds) external payable {
        uint256 count = streamIds.length;

        uint256 maxFeeRequired;

        // Iterate over the streamIds and prepare the call data for each stream.
        bytes[] memory calls = new bytes[](count);
        for (uint256 i = 0; i < count; ++i) {
            address recipient = FLOW.getRecipient(streamIds[i]);
            calls[i] = abi.encodeCall(FLOW.withdrawMax, (streamIds[i], recipient));

            // Calculate the fee required to withdraw the amount. It is the maximum of the fees required to withdraw
            // each stream.
            uint256 feeForStreamId = FLOW.calculateMinFeeWei(streamIds[i]);
            if (feeForStreamId > maxFeeRequired) {
                maxFeeRequired = feeForStreamId;
            }
        }

        // Execute multiple calls in a single transaction using the prepared call data.
        FLOW.batch{ value: maxFeeRequired }(calls);
    }
}
