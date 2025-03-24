// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Flow } from "src/types/DataTypes.sol";
import { Integration_Test } from "./../Integration.t.sol";

abstract contract Shared_Integration_Concrete_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal defaultStreamId;
    uint256 internal nullStreamId = 420;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenBalanceNotZero() override {
        // Deposit into the stream.
        depositToDefaultStream();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        defaultStreamId = createDefaultStream();

        // Simulate one month of streaming.
        vm.warp({ newTimestamp: ONE_MONTH_SINCE_CREATE });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStream() internal returns (uint256) {
        return createDefaultStream(usdc);
    }

    function defaultStream() internal view returns (Flow.Stream memory) {
        return Flow.Stream({
            balance: 0,
            snapshotTime: getBlockTimestamp(),
            isStream: true,
            isTransferable: TRANSFERABLE,
            isVoided: false,
            ratePerSecond: RATE_PER_SECOND,
            snapshotDebtScaled: 0,
            sender: users.sender,
            token: usdc,
            tokenDecimals: DECIMALS
        });
    }

    function defaultStreamWithDeposit() internal view returns (Flow.Stream memory stream) {
        stream = defaultStream();
        stream.balance = DEPOSIT_AMOUNT_6D;
    }

    function depositToDefaultStream() internal {
        deposit(defaultStreamId, DEPOSIT_AMOUNT_6D);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function expectRevert_CallerMaliciousThirdParty(bytes memory callData) internal {
        setMsgSender(users.eve);
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "malicious call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.eve),
            "malicious call return data"
        );
    }

    function expectRevert_CallerRecipient(bytes memory callData) internal {
        setMsgSender(users.recipient);
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "recipient call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.recipient),
            "recipient call return data"
        );
    }

    function expectRevert_CallerSender(bytes memory callData) internal {
        setMsgSender(users.sender);
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "sender call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.sender),
            "sender call return data"
        );
    }

    function expectRevert_DelegateCall(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(flow).delegatecall(callData);
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(EvmUtilsErrors.DelegateCall.selector), "delegatecall return data");
    }

    function expectRevert_Null(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "null call success");
        assertEq(
            returnData, abi.encodeWithSelector(Errors.SablierFlow_Null.selector, nullStreamId), "null call return data"
        );
    }

    function expectRevert_Voided(bytes memory callData) internal {
        // Simulate the passage of time to accumulate uncovered debt for one month.
        vm.warp({ newTimestamp: WARP_SOLVENCY_PERIOD + ONE_MONTH });
        flow.void(defaultStreamId);

        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "voided call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_StreamVoided.selector, defaultStreamId),
            "voided call return data"
        );
    }

    function expectRevert_Paused(bytes memory callData) internal {
        flow.pause(defaultStreamId);
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "paused call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_StreamPaused.selector, defaultStreamId),
            "paused call return data"
        );
    }
}
