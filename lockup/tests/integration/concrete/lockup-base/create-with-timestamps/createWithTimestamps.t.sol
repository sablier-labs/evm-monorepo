// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract CreateWithTimestamps_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helpers function to assert the common storaged values of a stream between all Lockup models.
    function assertEqStream(uint256 streamId) internal view {
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getStartTime(streamId), defaults.START_TIME(), "startTime");
        assertEq(lockup.getEndTime(streamId), defaults.END_TIME(), "endTime");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isCancelable(streamId), "isCancelable");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");

        // Assert that the stream's status is "PENDING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    COMMON-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData;

        if (lockupModel == Lockup.Model.LOCKUP_DYNAMIC) {
            callData = abi.encodeCall(
                lockup.createWithTimestampsLD, (_defaultParams.createWithTimestamps, _defaultParams.segments)
            );
        } else if (lockupModel == Lockup.Model.LOCKUP_LINEAR) {
            callData = abi.encodeCall(
                lockup.createWithTimestampsLL,
                (_defaultParams.createWithTimestamps, _defaultParams.unlockAmounts, _defaultParams.cliffTime)
            );
        } else if (lockupModel == Lockup.Model.LOCKUP_TRANCHED) {
            callData = abi.encodeCall(
                lockup.createWithTimestampsLT, (_defaultParams.createWithTimestamps, _defaultParams.tranches)
            );
        }

        expectRevert_DelegateCall(callData);
    }

    function test_RevertWhen_ShapeExceeds32Bytes() external whenNoDelegateCall {
        _defaultParams.createWithTimestamps.shape = "this name is longer than 32 bytes";
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_ShapeExceeds32Bytes.selector, 33));
        createDefaultStream();
    }

    function test_RevertWhen_BrokerFeeExceedsMaxValue() external whenNoDelegateCall whenShapeNotExceed32Bytes {
        UD60x18 brokerFee = MAX_BROKER_FEE + ud(1);
        _defaultParams.createWithTimestamps.broker.fee = brokerFee;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_BrokerFeeTooHigh.selector, brokerFee, MAX_BROKER_FEE)
        );
        createDefaultStream();
    }

    function test_RevertWhen_SenderZeroAddress()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
    {
        _defaultParams.createWithTimestamps.sender = address(0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_SenderZeroAddress.selector));
        createDefaultStream();
    }

    function test_RevertWhen_RecipientZeroAddress()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
    {
        _defaultParams.createWithTimestamps.recipient = address(0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        createDefaultStream();
    }

    function test_RevertWhen_DepositAmountZero()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
    {
        _defaultParams.createWithTimestamps.totalAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_DepositAmountZero.selector));
        createDefaultStream();
    }

    function test_RevertWhen_StartTimeZero()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        _defaultParams.createWithTimestamps.timestamps.start = 0;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_StartTimeZero.selector));
        createDefaultStream();
    }

    function test_RevertWhen_TokenNotContract()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
    {
        address nonContract = address(8128);
        _defaultParams.createWithTimestamps.token = IERC20(nonContract);
        vm.expectRevert(abi.encodeWithSelector(Address.AddressEmptyCode.selector, nonContract));
        createDefaultStream();
    }
}
