// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Create__RecipientZeroAddress is SablierV2LinearUnitTest {
    /// @dev it should revert.
    function testCannotCreate() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Linear.create(
            daiStream.sender,
            recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }
}

contract RecipientNonZeroAddress {}

contract SablierV2Linear__Create__DepositAmountZero is SablierV2LinearUnitTest, RecipientNonZeroAddress {
    /// @dev it should revert.
    function testCannotCreate() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }
}

contract DepositAmountNotZero {}

contract SablierV2Linear__Create__StartTimeGreaterThanStopTime is
    SablierV2LinearUnitTest,
    RecipientNonZeroAddress,
    DepositAmountNotZero
{
    /// @dev it should revert.
    function testCannotCreate() external {
        uint256 startTime = daiStream.stopTime;
        uint256 stopTime = daiStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            daiStream.cliffTime,
            stopTime,
            daiStream.cancelable
        );
    }
}

contract SablierV2Linear__Create__StartTimeEqualToStopTime is
    SablierV2LinearUnitTest,
    RecipientNonZeroAddress,
    DepositAmountNotZero
{
    /// @dev it should create the stream.
    function testCreate() external {
        uint256 cliffTime = daiStream.startTime;
        uint256 stopTime = daiStream.startTime;
        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}

contract StartTimeLessThanStopTime {}

contract SablierV2Linear__Create__StartTimeGreaterThanCliffTime is
    SablierV2LinearUnitTest,
    RecipientNonZeroAddress,
    DepositAmountNotZero,
    StartTimeLessThanStopTime
{
    /// @dev it should revert.
    function testCannotCreate__StartTimeGreaterThanCliffTime() external {
        uint256 startTime = daiStream.cliffTime;
        uint256 cliffTime = daiStream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Linear.SablierV2Linear__StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }
}

contract SablierV2Linear__Create__StartTimeEqualToCliffTime is
    SablierV2LinearUnitTest,
    RecipientNonZeroAddress,
    DepositAmountNotZero,
    StartTimeLessThanStopTime
{
    /// @dev it should create the stream.
    function testCreate__CliffTimeEqualToStopTime() external {
        uint256 cliffTime = daiStream.startTime;
        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeGreaterThanStopTime is
    SablierV2LinearUnitTest
{
    /// @dev it should revert.
    function testCannotCreate__CliffTimeGreaterThanStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 stopTime = daiStream.cliffTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Linear.SablierV2Linear__CliffTimeGreaterThanStopTime.selector,
                cliffTime,
                stopTime
            )
        );
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            stopTime,
            daiStream.cancelable
        );
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeEqualToStopTime is
    SablierV2LinearUnitTest
{
    /// @dev it should create the stream.
    function testCreate__CliffTimeEqualToStopTime() external {
        uint256 cliffTime = daiStream.stopTime;
        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeLessThanStopTime__TokenNotContract is
    SablierV2LinearUnitTest
{
    /// @dev it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeLessThanStopTime__TokenMissingReturnValue is
    SablierV2LinearUnitTest
{
    /// @dev it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(address(actualStream.token), address(nonStandardToken));
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.cliffTime, daiStream.cliffTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeLessThanStopTime__TokenERC20Compliant__Token6Decimals is
    SablierV2LinearUnitTest
{
    /// @dev  it should create the stream.
    function testCreate() external {
        uint256 usdcStreamId = createDefaultUsdcStream();
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(usdcStreamId);
        ISablierV2Linear.Stream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateStream event.
    function testCreate__Event() external {
        uint256 usdcStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = usdcStream.sender;
        emit CreateStream(
            usdcStreamId,
            funder,
            usdcStream.sender,
            usdcStream.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.cliffTime,
            usdcStream.stopTime,
            usdcStream.cancelable
        );
        createDefaultUsdcStream();
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeLessThanStopTime__TokenERC20Compliant__Token18Decimals__CallerSender is
    SablierV2LinearUnitTest
{
    /// @dev it should create the stream.
    function testCreate() external {
        uint256 daiStreamId = createDefaultDaiStream();
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(daiStreamId);
        assertEq(daiStream, createdStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateStream event.
    function testCreate__Event() external {
        uint256 daiStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = daiStream.sender;
        emit CreateStream(
            daiStreamId,
            funder,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        createDefaultDaiStream();
    }
}

contract SablierV2Linear__Create__RecipientNonZeroAddress__DepositAmountNotZero__StartTimeLessThanStopTime__CliffTimeLessThanStopTime__TokenERC20Compliant__Token18Decimals__CallerNotSender is
    SablierV2LinearUnitTest
{
    /// @dev it should create the stream.
    function testCreate__18Decimals__CallerNotSender() external {
        // Make Alice the funder of the stream.
        changePrank(users.alice);
        uint256 daiStreamId = createDefaultDaiStream();

        // Run the test.
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__18Decimals__CallerNotSender__NextStreamId() external {
        uint256 nextStreamId = sablierV2Linear.nextStreamId();

        // Make Alice the funder of the stream.
        changePrank(users.alice);
        createDefaultDaiStream();

        // Run the test.
        uint256 actualNextStreamId = sablierV2Linear.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev  it should emit a CreateStream event.
    function testCreate__18Decimals__CallerNotSender__Event() external {
        // Make Alice the funder of the stream.
        changePrank(users.alice);

        // Run the test.
        uint256 daiStreamId = sablierV2Linear.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = users.alice;
        emit CreateStream(
            daiStreamId,
            funder,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
        createDefaultDaiStream();
    }
}
