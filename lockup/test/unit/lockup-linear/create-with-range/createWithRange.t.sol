// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { CreateWithRange_Linear_Shared_Test } from
    "../../../shared/lockup-linear/create-with-range/createWithRange.t.sol";
import { Linear_Unit_Test } from "../Linear.t.sol";

contract CreateWithRange_Linear_Unit_Test is Linear_Unit_Test, CreateWithRange_Linear_Shared_Test {
    function setUp() public virtual override(Linear_Unit_Test, CreateWithRange_Linear_Shared_Test) {
        Linear_Unit_Test.setUp();
        CreateWithRange_Linear_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2LockupLinear.createWithRange, defaults.createWithRange());
        (bool success, bytes memory returnData) = address(linear).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNoDelegateCall {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    /// @dev It is not possible to obtain a zero deposit amount from a non-zero total amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function test_RevertWhen_DepositAmountZero() external whenNoDelegateCall whenRecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        createDefaultStreamWithTotalAmount(0);
    }

    function test_RevertWhen_StartTimeGreaterThanCliffTime()
        external
        whenNoDelegateCall
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
        whenNoDelegateCall
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
        whenNoDelegateCall
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

    modifier whenEndTimeInTheFuture() {
        _;
    }

    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        whenNoDelegateCall
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
        whenNoDelegateCall
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
        whenNoDelegateCall
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
        whenNoDelegateCall
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
        whenNoDelegateCall
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
        // Make the sender the stream's funder.
        address funder = users.sender;

        // Expect the assets to be transferred from the funder to {SablierV2LockupLinear}.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: address(linear),
            amount: defaults.DEPOSIT_AMOUNT() + defaults.PROTOCOL_FEE_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            amount: defaults.BROKER_FEE_AMOUNT()
        });

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vm.expectEmit({ emitter: address(linear) });
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: IERC20(asset),
            cancelable: true,
            range: defaults.linearRange(),
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithAsset(IERC20(asset));

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        LockupLinear.Stream memory expectedStream = defaults.linearStream();
        expectedStream.asset = IERC20(asset);
        assertEq(actualStream, expectedStream);

        // Assert that the stream's status is "STREAMING".
        Lockup.Status actualStatus = linear.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
