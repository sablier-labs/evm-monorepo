// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { CreateWithRange_Integration_Shared_Test } from "../../../shared/lockup-linear/createWithRange.t.sol";
import { LockupLinear_Integration_Concrete_Test } from "../LockupLinear.t.sol";

contract CreateWithRange_LockupLinear_Integration_Concrete_Test is
    LockupLinear_Integration_Concrete_Test,
    CreateWithRange_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Concrete_Test, CreateWithRange_Integration_Shared_Test)
    {
        LockupLinear_Integration_Concrete_Test.setUp();
        CreateWithRange_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierV2LockupLinear.createWithRange, defaults.createWithRange());
        (bool success, bytes memory returnData) = address(lockupLinear).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNotDelegateCalled {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    /// @dev It is not possible to obtain a zero deposit amount from a non-zero total amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function test_RevertWhen_DepositAmountZero() external whenNotDelegateCalled whenRecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        createDefaultStreamWithTotalAmount(0);
    }

    function test_RevertWhen_StartTimeGreaterThanCliffTime()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
    {
        uint40 startTime = defaults.CLIFF_TIME();
        uint40 cliffTime = defaults.START_TIME();
        uint40 endTime = defaults.END_TIME();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector, startTime, cliffTime
            )
        );
        createDefaultStreamWithRange(LockupLinear.Range({ start: startTime, cliff: cliffTime, end: endTime }));
    }

    function test_RevertWhen_CliffTimeNotLessThanEndTime()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
    {
        uint40 startTime = defaults.START_TIME();
        uint40 cliffTime = defaults.END_TIME();
        uint40 endTime = defaults.CLIFF_TIME();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime
            )
        );
        createDefaultStreamWithRange(LockupLinear.Range({ start: startTime, cliff: cliffTime, end: endTime }));
    }

    function test_RevertWhen_EndTimeNotInTheFuture()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
    {
        uint40 endTime = defaults.END_TIME();
        vm.warp({ timestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_EndTimeNotInTheFuture.selector, endTime, endTime));
        createDefaultStream();
    }

    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
    {
        UD60x18 protocolFee = MAX_FEE + ud(1);

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

    function test_RevertWhen_BrokerFeeTooHigh()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
        whenProtocolFeeNotTooHigh
    {
        UD60x18 brokerFee = MAX_FEE + ud(1);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, MAX_FEE));
        createDefaultStreamWithBroker(Broker({ account: users.broker, fee: brokerFee }));
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
    {
        address nonContract = address(8128);
        vm.expectRevert("Address: call to non-contract");
        createDefaultStreamWithAsset(IERC20(nonContract));
    }

    function test_CreateWithRange_AssetMissingReturnValue()
        external
        whenNotDelegateCalled
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenEndTimeInTheFuture
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
    {
        testCreateWithRange(address(usdt));
    }

    function test_CreateWithRange()
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
        testCreateWithRange(address(dai));
    }

    /// @dev Shared logic between {test_CreateWithRange_AssetMissingReturnValue} and {test_CreateWithRange}.
    function testCreateWithRange(address asset) internal {
        // Make the Sender the stream's funder.
        address funder = users.sender;

        // Expect the assets to be transferred from the funder to {SablierV2LockupLinear}.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: address(lockupLinear),
            amount: defaults.DEPOSIT_AMOUNT() + defaults.PROTOCOL_FEE_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            amount: defaults.BROKER_FEE_AMOUNT()
        });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockupLinear) });
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: IERC20(asset),
            cancelable: true,
            range: defaults.lockupLinearRange(),
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithAsset(IERC20(asset));

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = lockupLinear.getStream(streamId);
        LockupLinear.Stream memory expectedStream = defaults.lockupLinearStream();
        expectedStream.asset = IERC20(asset);
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "PENDING".
        Lockup.Status actualStatus = lockupLinear.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = lockupLinear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = lockupLinear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
