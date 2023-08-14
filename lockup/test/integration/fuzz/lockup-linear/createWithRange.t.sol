// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { MAX_UD60x18, UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { CreateWithRange_Integration_Shared_Test } from "../../shared/lockup-linear/createWithRange.t.sol";
import { LockupLinear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract CreateWithRange_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    CreateWithRange_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Fuzz_Test, CreateWithRange_Integration_Shared_Test)
    {
        LockupLinear_Integration_Fuzz_Test.setUp();
        CreateWithRange_Integration_Shared_Test.setUp();
    }

    function testFuzz_RevertWhen_StartTimeGreaterThanCliffTime(uint40 startTime)
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
    {
        startTime = boundUint40(startTime, defaults.CLIFF_TIME() + 1 seconds, MAX_UNIX_TIMESTAMP);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector, startTime, defaults.CLIFF_TIME()
            )
        );
        createDefaultStreamWithStartTime(startTime);
    }

    function testFuzz_RevertWhen_CliffTimeNotLessThanEndTime(
        uint40 cliffTime,
        uint40 endTime
    )
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
    {
        uint40 startTime = defaults.START_TIME();
        endTime = boundUint40(endTime, startTime, startTime + 2 weeks);
        cliffTime = boundUint40(cliffTime, endTime, MAX_UNIX_TIMESTAMP);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime
            )
        );
        createDefaultStreamWithRange(LockupLinear.Range({ start: startTime, cliff: cliffTime, end: endTime }));
    }

    function testFuzz_RevertWhen_ProtocolFeeTooHigh(UD60x18 protocolFee)
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
    {
        protocolFee = _bound(protocolFee, MAX_FEE + ud(1), MAX_UD60x18);

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: protocolFee });
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, MAX_FEE)
        );
        createDefaultStream();
    }

    function testFuzz_RevertWhen_BrokerFeeTooHigh(Broker memory broker)
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
        whenProtocolFeeNotTooHigh
    {
        vm.assume(broker.account != address(0));
        broker.fee = _bound(broker.fee, MAX_FEE + ud(1), MAX_UD60x18);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, broker.fee, MAX_FEE));
        createDefaultStreamWithBroker(broker);
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.Status actualStatus;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        Lockup.Status expectedStatus;
        uint128 initialProtocolRevenues;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker
    /// - Multiple values for the total amount
    /// - Cancelable and not cancelable
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time lower than and equal to cliff time
    /// - Multiple values for the cliff time and the end time
    /// - Multiple values for the broker fee, including zero
    /// - Multiple values for the protocol fee, including zero
    function testFuzz_CreateWithRange(
        address funder,
        LockupLinear.CreateWithRange memory params,
        UD60x18 protocolFee
    )
        external
        whenNotDelegateCalled
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
        whenAssetERC20
    {
        vm.assume(funder != address(0) && params.recipient != address(0) && params.broker.account != address(0));
        vm.assume(params.totalAmount != 0);
        params.range.start =
            boundUint40(params.range.start, defaults.START_TIME(), defaults.START_TIME() + 10_000 seconds);
        params.range.cliff = boundUint40(params.range.cliff, params.range.start, params.range.start + 52 weeks);
        params.range.end = boundUint40(params.range.end, params.range.cliff + 1 seconds, MAX_UNIX_TIMESTAMP);
        params.broker.fee = _bound(params.broker.fee, 0, MAX_FEE);
        protocolFee = _bound(protocolFee, 0, MAX_FEE);

        // Calculate the fee amounts and the deposit amount.
        Vars memory vars;
        vars.createAmounts.protocolFee = ud(params.totalAmount).mul(protocolFee).intoUint128();
        vars.createAmounts.brokerFee = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.createAmounts.deposit = params.totalAmount - vars.createAmounts.protocolFee - vars.createAmounts.brokerFee;

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: protocolFee });

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough assets to the funder.
        deal({ token: address(dai), to: funder, give: params.totalAmount });

        // Approve {SablierV2LockupLinear} to transfer the assets from the fuzzed funder.
        dai.approve({ spender: address(lockupLinear), amount: MAX_UINT256 });

        // Expect the assets to be transferred from the funder to {SablierV2LockupLinear}.
        expectCallToTransferFrom({
            from: funder,
            to: address(lockupLinear),
            amount: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectCallToTransferFrom({ from: funder, to: params.broker.account, amount: vars.createAmounts.brokerFee });
        }

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockupLinear) });
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: dai,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker.account
        });

        // Create the stream.
        lockupLinear.createWithRange(
            LockupLinear.CreateWithRange({
                asset: dai,
                broker: params.broker,
                cancelable: params.cancelable,
                range: params.range,
                recipient: params.recipient,
                sender: params.sender,
                totalAmount: params.totalAmount
            })
        );

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = lockupLinear.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts(vars.createAmounts.deposit, 0, 0));
        assertEq(actualStream.asset, dai, "asset");
        assertEq(actualStream.cliffTime, params.range.cliff, "cliffTime");
        assertEq(actualStream.endTime, params.range.end, "endTime");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.isDepleted, false, "isStream");
        assertEq(actualStream.isStream, true, "isStream");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, params.range.start, "startTime");
        assertEq(actualStream.wasCanceled, false, "wasCanceled");

        // Assert that the stream's status is correct.
        vars.actualStatus = lockupLinear.statusOf(streamId);
        vars.expectedStatus = params.range.start > getBlockTimestamp() ? Lockup.Status.PENDING : Lockup.Status.STREAMING;
        assertEq(vars.actualStatus, vars.expectedStatus);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = lockupLinear.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = lockupLinear.protocolRevenues(dai);
        vars.expectedProtocolRevenues = vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = lockupLinear.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
