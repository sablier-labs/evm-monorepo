// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { stdError } from "forge-std/src/StdError.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupTranched } from "src/types/DataTypes.sol";

import {
    CreateWithTimestamps_Integration_Concrete_Test,
    Integration_Test
} from "../../lockup-base/create-with-timestamps/createWithTimestamps.t.sol";

contract CreateWithTimestampsLT_Integration_Concrete_Test is CreateWithTimestamps_Integration_Concrete_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
        lockupModel = Lockup.Model.LOCKUP_TRANCHED;
    }

    function test_RevertWhen_TrancheCountZero()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
    {
        LockupTranched.Tranche[] memory tranches;
        vm.expectRevert(Errors.SablierHelpers_TrancheCountZero.selector);
        lockup.createWithTimestampsLT(_defaultParams.createWithTimestamps, tranches);
    }

    function test_RevertWhen_TrancheCountExceedsMaxValue()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
    {
        uint256 trancheCount = defaults.MAX_COUNT() + 1;
        LockupTranched.Tranche[] memory tranches = new LockupTranched.Tranche[](trancheCount);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_TrancheCountTooHigh.selector, trancheCount));
        lockup.createWithTimestampsLT(_defaultParams.createWithTimestamps, tranches);
    }

    function test_RevertWhen_TrancheAmountsSumOverflows()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
    {
        _defaultParams.tranches[0].amount = MAX_UINT128;
        _defaultParams.tranches[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStream();
    }

    function test_RevertWhen_StartTimeGreaterThanFirstTimestamp()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
    {
        // Change the timestamp of the first tranche.
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].timestamp = defaults.START_TIME() - 1 seconds;

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                defaults.START_TIME(),
                tranches[0].timestamp
            )
        );

        // Create the stream.
        lockup.createWithTimestampsLT(_defaultParams.createWithTimestamps, tranches);
    }

    function test_RevertWhen_StartTimeEqualsFirstTimestamp()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
    {
        // Change the timestamp of the first tranche.
        _defaultParams.tranches[0].timestamp = defaults.START_TIME();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                defaults.START_TIME(),
                _defaultParams.tranches[0].timestamp
            )
        );
        createDefaultStream();
    }

    function test_RevertWhen_EndTimeNotEqualLastTimestamp()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
    {
        _defaultParams.createWithTimestamps.timestamps.end = defaults.END_TIME() + 1 seconds;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_EndTimeNotEqualToLastTrancheTimestamp.selector,
                _defaultParams.createWithTimestamps.timestamps.end,
                _defaultParams.createWithTimestamps.timestamps.end - 1
            )
        );
        createDefaultStream();
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
    {
        // Swap the tranche timestamps.
        // LockupTranched.Tranche[] memory tranches = defaults.tranches();
        (_defaultParams.tranches[0].timestamp, _defaultParams.tranches[1].timestamp) =
            (_defaultParams.tranches[1].timestamp, _defaultParams.tranches[0].timestamp);

        // Expect the relevant error to be thrown.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_TrancheTimestampsNotOrdered.selector,
                index,
                _defaultParams.tranches[0].timestamp,
                _defaultParams.tranches[1].timestamp
            )
        );
        _defaultParams.createWithTimestamps.timestamps.end = _defaultParams.tranches[1].timestamp;
        createDefaultStream();
    }

    function test_RevertWhen_DepositAmountNotEqualTrancheAmountsSum()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
        whenTimestampsStrictlyIncreasing
    {
        resetPrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + 100;
        _defaultParams.createWithTimestamps.depositAmount = depositAmount;

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_DepositAmountNotEqualToTrancheAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
            )
        );
        createDefaultStream();
    }

    function test_WhenTokenMissesERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
        whenTimestampsStrictlyIncreasing
        whenDepositAmountEqualsTrancheAmountsSum
    {
        IERC20 _usdt = IERC20(address(usdt));

        // Update the default parameters.
        _defaultParams.createWithTimestamps.depositAmount = defaults.DEPOSIT_AMOUNT_6D();
        _defaultParams.createWithTimestamps.token = _usdt;
        _defaultParams.tranches[0].amount = 2600e6;
        _defaultParams.tranches[1].amount = 7400e6;

        uint256 previousAggregateAmount = lockup.aggregateBalance(_usdt);
        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: _usdt,
            from: users.sender,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT_6D()
        });

        // It should emit {CreateLockupTranchedStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(_usdt, defaults.DEPOSIT_AMOUNT_6D()),
            tranches: _defaultParams.tranches
        });

        // It should create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId, _usdt);
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_TRANCHED);
        assertEq(
            lockup.aggregateBalance(_usdt), previousAggregateAmount + defaults.DEPOSIT_AMOUNT_6D(), "aggregateBalance"
        );
        assertEq(lockup.getTranches(streamId), _defaultParams.tranches);
    }

    function test_WhenTokenNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
        whenTimestampsStrictlyIncreasing
        whenDepositAmountEqualsTrancheAmountsSum
    {
        uint256 previousAggregateAmount = lockup.aggregateBalance(dai);
        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: dai,
            from: users.sender,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // It should emit {CreateLockupTranchedStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(dai, defaults.DEPOSIT_AMOUNT()),
            tranches: defaults.tranches()
        });

        // It should create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId, dai);
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_TRANCHED);
        assertEq(lockup.aggregateBalance(dai), previousAggregateAmount + defaults.DEPOSIT_AMOUNT(), "aggregateBalance");
        assertEq(lockup.getTranches(streamId), defaults.tranches());
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");
    }
}
