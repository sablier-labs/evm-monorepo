// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract Getters_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    GET-BALANCE
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetBalanceRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getBalance, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetBalanceGivenZero() external view givenNotNull {
        assertEq(flow.getBalance(defaultStreamId), 0, "balance");
    }

    function test_GetBalanceGivenNotZero() external givenNotNull {
        depositToDefaultStream();
        assertEq(flow.getBalance(defaultStreamId), DEPOSIT_AMOUNT_6D, "balance");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                GET-RATE-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetRatePerSecondRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getRatePerSecond, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetRatePerSecondGivenZero() external givenNotNull {
        flow.pause(defaultStreamId);
        assertEq(flow.getRatePerSecond(defaultStreamId), ud21x18(0), "rate per second");
    }

    function test_GetRatePerSecondGivenNotZero() external view givenNotNull {
        assertEq(flow.getRatePerSecond(defaultStreamId), RATE_PER_SECOND, "rate per second");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   GET-RECIPIENT
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetRecipientRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getRecipient, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetRecipientGivenNotNull() external view {
        assertEq(flow.getRecipient(defaultStreamId), users.recipient, "recipient");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GET-SENDER
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSenderRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getSender, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetSenderGivenNotNull() external view {
        assertEq(flow.getSender(defaultStreamId), users.sender, "sender");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              GET-SNAPSHOT-DEBT-SCALED
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSnapshotDebtScaledRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getSnapshotDebtScaled, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetSnapshotDebtScaledGivenZero() external view givenNotNull {
        assertEq(flow.getSnapshotDebtScaled(defaultStreamId), 0, "snapshot debt scaled");
    }

    function test_GetSnapshotDebtScaledGivenNotZero() external givenNotNull {
        vm.warp(ONE_MONTH_SINCE_START);
        flow.adjustRatePerSecond(defaultStreamId, ud21x18(1));
        assertEq(flow.getSnapshotDebtScaled(defaultStreamId), ONE_MONTH_DEBT_18D, "snapshot debt scaled");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 GET-SNAPSHOT-TIME
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSnapshotTimeRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getSnapshotTime, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetSnapshotTimeGivenNotNull() external view {
        assertEq(flow.getSnapshotTime(defaultStreamId), FEB_1_2025, "snapshot time");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     GET-STREAM
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetStreamRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getStream, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetStreamGivenNotNull() external view {
        Flow.Stream memory stream = defaultStream();
        stream.snapshotTime = FEB_1_2025;
        assertEq(abi.encode(flow.getStream(defaultStreamId)), abi.encode(stream), "stream");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 GET-TOKEN-DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetTokenDecimalsRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getTokenDecimals, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetTokenDecimalsGivenNotNull() external view {
        assertEq(flow.getTokenDecimals(defaultStreamId), DECIMALS, "token decimals");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     IS-PAUSED
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsPausedRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.isPaused, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_IsPausedGivenTrue() external givenNotNull {
        flow.pause(defaultStreamId);
        assertTrue(flow.isPaused(defaultStreamId), "paused");
    }

    function test_IsPausedGivenNotTrue() external view givenNotNull {
        assertFalse(flow.isPaused(defaultStreamId), "paused");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     IS-STREAM
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsStreamGivenNull() external view {
        assertFalse(flow.isStream(nullStreamId), "is stream");
    }

    function test_IsStreamGivenNotNull() external view {
        assertTrue(flow.isStream(defaultStreamId), "is stream");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  IS-TRANSFERABLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsTransferableRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.isTransferable, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_IsTransferableGivenTrue() external view givenNotNull {
        assertTrue(flow.isTransferable(defaultStreamId), "transferable");
    }

    function test_IsTransferableGivenFalse() external givenNotNull {
        uint256 streamId = flow.create(users.sender, users.recipient, RATE_PER_SECOND, usdc, false);
        assertFalse(flow.isTransferable(streamId), "transferable");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     IS-VOIDED
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsVoidedRevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.isVoided, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_IsVoidedGivenTrue() external givenNotNull {
        flow.void(defaultStreamId);
        assertEq(flow.isVoided(defaultStreamId), true, "voided");
    }

    function test_IsVoidedGivenFalse() external view givenNotNull {
        assertFalse(flow.isVoided(defaultStreamId), "voided");
    }
}
