// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract Getters_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    GET-BALANCE
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetBalance_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getBalance, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetBalance_GivenZero() external view givenNotNull {
        assertEq(flow.getBalance(defaultStreamId), 0, "balance");
    }

    function test_GetBalance_GivenNotZero() external givenNotNull {
        depositToDefaultStream();
        assertEq(flow.getBalance(defaultStreamId), DEPOSIT_AMOUNT_6D, "balance");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                GET-RATE-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetRatePerSecond_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getRatePerSecond, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetRatePerSecond_GivenZero() external givenNotNull {
        flow.pause(defaultStreamId);
        assertEq(flow.getRatePerSecond(defaultStreamId), ud21x18(0), "rate per second");
    }

    function test_GetRatePerSecond_GivenNotZero() external view givenNotNull {
        assertEq(flow.getRatePerSecond(defaultStreamId), RATE_PER_SECOND, "rate per second");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   GET-RECIPIENT
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetRecipient_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getRecipient, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetRecipient_GivenNotNull() external view {
        assertEq(flow.getRecipient(defaultStreamId), users.recipient, "recipient");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GET-SENDER
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSender_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getSender, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetSender_GivenNotNull() external view {
        assertEq(flow.getSender(defaultStreamId), users.sender, "sender");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              GET-SNAPSHOT-DEBT-SCALED
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSnapshotDebtScaled_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getSnapshotDebtScaled, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetSnapshotDebtScaled_GivenZero() external view givenNotNull {
        assertEq(flow.getSnapshotDebtScaled(defaultStreamId), 0, "snapshot debt scaled");
    }

    function test_GetSnapshotDebtScaled_GivenNotZero() external givenNotNull {
        vm.warp(ONE_MONTH_SINCE_CREATE);
        flow.adjustRatePerSecond(defaultStreamId, ud21x18(1));
        assertEq(flow.getSnapshotDebtScaled(defaultStreamId), ONE_MONTH_DEBT_18D, "snapshot debt scaled");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 GET-SNAPSHOT-TIME
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetSnapshotTime_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getSnapshotTime, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetSnapshotTime_GivenNotNull() external view {
        assertEq(flow.getSnapshotTime(defaultStreamId), FEB_1_2025, "snapshot time");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     GET-STREAM
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetStream_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getStream, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetStream_GivenNotNull() external view {
        Flow.Stream memory stream = defaultStream();
        stream.snapshotTime = FEB_1_2025;
        assertEq(abi.encode(flow.getStream(defaultStreamId)), abi.encode(stream), "stream");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 GET-TOKEN-DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetTokenDecimals_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.getTokenDecimals, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_GetTokenDecimals_GivenNotNull() external view {
        assertEq(flow.getTokenDecimals(defaultStreamId), DECIMALS, "token decimals");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     IS-STREAM
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsStream_GivenNull() external view {
        assertFalse(flow.isStream(nullStreamId), "is stream");
    }

    function test_IsStream_GivenNotNull() external view {
        assertTrue(flow.isStream(defaultStreamId), "is stream");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  IS-TRANSFERABLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsTransferable_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.isTransferable, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_IsTransferable_GivenTrue() external view givenNotNull {
        assertTrue(flow.isTransferable(defaultStreamId), "transferable");
    }

    function test_IsTransferable_GivenFalse() external givenNotNull {
        uint256 streamId = flow.create(users.sender, users.recipient, RATE_PER_SECOND, ZERO, usdc, false);
        assertFalse(flow.isTransferable(streamId), "transferable");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     IS-VOIDED
    //////////////////////////////////////////////////////////////////////////*/

    function test_IsVoided_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.isVoided, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_IsVoided_GivenTrue() external givenNotNull {
        flow.void(defaultStreamId);
        assertEq(flow.isVoided(defaultStreamId), true, "voided");
    }

    function test_IsVoided_GivenFalse() external view givenNotNull {
        assertFalse(flow.isVoided(defaultStreamId), "voided");
    }
}
