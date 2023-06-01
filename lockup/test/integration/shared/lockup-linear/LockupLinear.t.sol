// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Broker, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Integration_Shared_Test } from "../lockup/Lockup.t.sol";

/// @notice Common testing logic needed by all {SablierV2LockupLinear} integration tests.
abstract contract LockupLinear_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    struct Params {
        LockupLinear.CreateWithDurations createWithDurations;
        LockupLinear.CreateWithRange createWithRange;
    }

    /// @dev These have to be pre-declared so that `vm.expectRevert` does not expect a revert in `defaults`.
    /// See https://github.com/foundry-rs/foundry/issues/4762.
    Params private _params;

    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();
        _params.createWithDurations = defaults.createWithDurations();
        _params.createWithRange = defaults.createWithRange();
    }

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = lockupLinear.createWithRange(_params.createWithRange);
    }

    /// @dev Creates the default stream with the provided address.
    function createDefaultStreamWithAsset(IERC20 asset) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.asset = asset;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided broker.
    function createDefaultStreamWithBroker(Broker memory broker) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.broker = broker;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurations() internal returns (uint256 streamId) {
        streamId = lockupLinear.createWithDurations(_params.createWithDurations);
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurations(LockupLinear.Durations memory durations)
        internal
        returns (uint256 streamId)
    {
        LockupLinear.CreateWithDurations memory params = _params.createWithDurations;
        params.durations = durations;
        streamId = lockupLinear.createWithDurations(params);
    }

    /// @dev Creates the default stream that is not cancelable.
    function createDefaultStreamNotCancelable() internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.cancelable = false;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.range.end = endTime;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided createWithRange.
    function createDefaultStreamWithRange(LockupLinear.Range memory createWithRange)
        internal
        returns (uint256 streamId)
    {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.range = createWithRange;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.recipient = recipient;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.sender = sender;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided start time.
    function createDefaultStreamWithStartTime(uint40 startTime) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.range.start = startTime;
        streamId = lockupLinear.createWithRange(params);
    }

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal override returns (uint256 streamId) {
        LockupLinear.CreateWithRange memory params = _params.createWithRange;
        params.totalAmount = totalAmount;
        streamId = lockupLinear.createWithRange(params);
    }
}
