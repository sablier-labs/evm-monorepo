// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import {
    CreateWithTimestamps_Integration_Concrete_Test,
    Integration_Test
} from "../../lockup-base/create-with-timestamps/createWithTimestamps.t.sol";

contract CreateWithTimestampsLL_Integration_Concrete_Test is CreateWithTimestamps_Integration_Concrete_Test {
    function setUp() public override {
        Integration_Test.setUp();
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
    }

    function test_RevertWhen_StartTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenCliffTimeZero
    {
        uint40 startTime = defaults.END_TIME();
        uint40 cliffTime = 0;
        uint40 endTime = defaults.START_TIME();
        _defaultParams.createWithTimestamps.timestamps.start = startTime;
        _defaultParams.createWithTimestamps.timestamps.end = endTime;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_StartTimeNotLessThanEndTime.selector, startTime, endTime)
        );
        lockup.createWithTimestampsLL(_defaultParams.createWithTimestamps, cliffTime);
    }

    function test_WhenStartTimeLessThanEndTime()
        external
        whenNoDelegateCall
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenCliffTimeZero
    {
        uint40 cliffTime = 0;
        _testCreateWithTimestampsLL(address(dai), cliffTime);
    }

    function test_RevertWhen_StartTimeNotLessThanCliffTime()
        external
        whenNoDelegateCall
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenCliffTimeNotZero
    {
        uint40 startTime = defaults.CLIFF_TIME();
        uint40 endTime = defaults.END_TIME();
        uint40 cliffTime = defaults.START_TIME();

        _defaultParams.createWithTimestamps.timestamps.start = startTime;
        _defaultParams.createWithTimestamps.timestamps.end = endTime;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_StartTimeNotLessThanCliffTime.selector, startTime, cliffTime)
        );
        lockup.createWithTimestampsLL(_defaultParams.createWithTimestamps, cliffTime);
    }

    function test_RevertWhen_CliffTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
    {
        _defaultParams.cliffTime = defaults.END_TIME() + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_CliffTimeNotLessThanEndTime.selector,
                _defaultParams.cliffTime,
                _defaultParams.createWithTimestamps.timestamps.end
            )
        );
        createDefaultStream();
    }

    function test_WhenAssetMissesERC20ReturnValue()
        external
        whenNoDelegateCall
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
    {
        _testCreateWithTimestampsLL(address(usdt), _defaultParams.cliffTime);
    }

    function test_WhenAssetNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
    {
        _testCreateWithTimestampsLL(address(dai), _defaultParams.cliffTime);
    }

    /// @dev Shared logic between {test_WhenStartTimeLessThanEndTime}, {test_WhenAssetMissesERC20ReturnValue} and
    /// {test_WhenAssetNotMissERC20ReturnValue}.
    function _testCreateWithTimestampsLL(address asset, uint40 cliffTime) private {
        // Make the Sender the stream's funder.
        address funder = users.sender;
        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            value: defaults.BROKER_FEE_AMOUNT()
        });

        // It should emit {MetadataUpdate} and {CreateLockupLinearStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: expectedStreamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: IERC20(asset),
            cancelable: true,
            transferable: true,
            timestamps: defaults.lockupTimestamps(),
            cliffTime: cliffTime,
            broker: users.broker
        });

        // Create the stream.
        _defaultParams.createWithTimestamps.asset = IERC20(asset);
        _defaultParams.cliffTime = cliffTime;
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId);
        assertEq(lockup.getAsset(streamId), IERC20(asset), "asset");
        assertEq(lockup.getCliffTime(streamId), cliffTime, "cliffTime");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_LINEAR);
    }
}
