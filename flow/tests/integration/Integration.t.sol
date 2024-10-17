// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Broker, Flow } from "src/types/DataTypes.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Broker internal defaultBroker;
    uint256 internal defaultStreamId;
    uint256 internal nullStreamId = 420;

    /*//////////////////////////////////////////////////////////////////////////
                                        SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        defaultBroker = broker();
        defaultStreamId = createDefaultStream();

        // Simulate one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenBalanceNotZero() override {
        // Deposit into the stream.
        depositToDefaultStream();
        _;
    }

    modifier whenCallerAdmin() override {
        resetPrank({ msgSender: users.admin });
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function broker() public view returns (Broker memory) {
        return Broker({ account: users.broker, fee: BROKER_FEE });
    }

    function createDefaultStream() internal returns (uint256) {
        return createDefaultStream(usdc);
    }

    function createDefaultStream(IERC20 token_) internal returns (uint256) {
        return createDefaultStream(RATE_PER_SECOND, token_);
    }

    function createDefaultStream(UD21x18 ratePerSecond, IERC20 token_) internal returns (uint256) {
        return flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: ratePerSecond,
            token: token_,
            transferable: TRANSFERABLE
        });
    }

    /// @dev Helper function to create an token with the `decimals` and then a stream using the newly created token.
    function createTokenAndStream(uint8 decimals) internal returns (IERC20 token, uint256 streamId) {
        token = createToken(decimals);

        // Hash the next stream ID and the decimal to generate a seed.
        UD21x18 ratePerSecond =
            boundRatePerSecond(ud21x18(uint128(uint256(keccak256(abi.encodePacked(flow.nextStreamId(), decimals))))));

        // Create stream.
        streamId = createDefaultStream(ratePerSecond, token);
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

    function deposit(uint256 streamId, uint128 amount) internal {
        IERC20 token = flow.getToken(streamId);

        deal({ token: address(token), to: users.sender, give: UINT128_MAX });
        token.approve(address(flow), UINT128_MAX);

        flow.deposit(streamId, amount, users.sender, users.recipient);
    }

    function depositDefaultAmount(uint256 streamId) internal {
        uint8 decimals = flow.getTokenDecimals(streamId);
        uint128 depositAmount = getDefaultDepositAmount(decimals);

        deposit(streamId, depositAmount);
    }

    function depositToDefaultStream() internal {
        deposit(defaultStreamId, DEPOSIT_AMOUNT_6D);
    }

    /// @dev Update the snapshot using `adjustRatePerSecond` and then warp block timestamp to it.
    function updateSnapshotTimeAndWarp(uint256 streamId) internal {
        resetPrank(users.sender);
        UD21x18 ratePerSecond = flow.getRatePerSecond(streamId);

        // Updates the snapshot time via `adjustRatePerSecond`.
        flow.adjustRatePerSecond(streamId, ud21x18(1));

        // Restores the rate per second.
        flow.adjustRatePerSecond(streamId, ratePerSecond);

        // Warp to the snapshot time.
        vm.warp({ newTimestamp: flow.getSnapshotTime(streamId) });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function expectRevert_CallerMaliciousThirdParty(bytes memory callData) internal {
        resetPrank({ msgSender: users.eve });
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "malicious call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.eve),
            "malicious call return data"
        );
    }

    function expectRevert_CallerRecipient(bytes memory callData) internal {
        resetPrank({ msgSender: users.recipient });
        (bool success, bytes memory returnData) = address(flow).call(callData);
        assertFalse(success, "recipient call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.recipient),
            "recipient call return data"
        );
    }

    function expectRevert_CallerSender(bytes memory callData) internal {
        resetPrank({ msgSender: users.sender });
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
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
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
