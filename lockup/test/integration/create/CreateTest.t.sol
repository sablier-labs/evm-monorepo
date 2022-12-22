// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

abstract contract CreateTest is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // Make the token holder the caller in this test suite.
        vm.startPrank({ msgSender: holder() });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev it should create the linear stream.
    function testCreateLinear(
        address sender,
        address recipient,
        uint128 depositAmount,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime,
        bool cancelable
    ) external {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= IERC20(token()).balanceOf(holder()));
        vm.assume(startTime <= cliffTime);
        vm.assume(cliffTime <= stopTime);

        // Pull the next stream id.
        uint256 expectedStreamId = linear.nextStreamId();

        // Create the stream.
        uint256 actualStreamId = linear.create(
            sender,
            recipient,
            depositAmount,
            token(),
            cancelable,
            startTime,
            cliffTime,
            stopTime
        );

        // Declare the expected stream struct.
        DataTypes.LinearStream memory stream = DataTypes.LinearStream({
            cancelable: cancelable,
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            isEntity: true,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token(),
            withdrawnAmount: 0
        });

        // Run the tests.
        assertEq(actualStreamId, expectedStreamId);
        assertEq(linear.nextStreamId(), expectedStreamId + 1);
        assertEq(linear.getStream(actualStreamId), stream);
        assertEq(linear.getRecipient(actualStreamId), recipient);
    }

    /// @dev it should create the pro stream.
    function testCreatePro(
        address sender,
        address recipient,
        uint128 depositAmount,
        uint40 startTime,
        uint40 stopTime,
        SD1x18 exponent,
        bool cancelable
    ) external {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= IERC20(token()).balanceOf(holder()));
        vm.assume(startTime > 0); // needed for the segments to be ordered
        vm.assume(startTime <= stopTime);

        SD1x18[] memory segmentExponents = createDynamicArray(exponent);
        uint128[] memory segmentAmounts = createDynamicUint128Array(depositAmount);
        uint40[] memory segmentMilestones = createDynamicUint40Array(stopTime);

        // Pull the next stream id.
        uint256 expectedStreamId = sablierV2Pro.nextStreamId();

        // Create the stream.
        uint256 actualStreamId = sablierV2Pro.create(
            sender,
            recipient,
            depositAmount,
            token(),
            cancelable,
            startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones
        );

        // Declare the expected stream struct.
        DataTypes.ProStream memory expectedStream = DataTypes.ProStream({
            cancelable: cancelable,
            depositAmount: depositAmount,
            isEntity: true,
            segmentAmounts: segmentAmounts,
            segmentExponents: segmentExponents,
            segmentMilestones: segmentMilestones,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token(),
            withdrawnAmount: 0
        });

        // Run the tests.
        assertEq(actualStreamId, expectedStreamId);
        assertEq(sablierV2Pro.nextStreamId(), expectedStreamId + 1);
        assertEq(sablierV2Pro.getStream(actualStreamId), expectedStream);
        assertEq(sablierV2Pro.getRecipient(actualStreamId), recipient);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to approve the Sablier V2 contracts to spend tokens.
    function approveSablierV2() internal {
        IERC20(token()).approve({ spender: address(linear), value: UINT256_MAX });
        IERC20(token()).approve({ spender: address(sablierV2Pro), value: UINT256_MAX });
    }

    /// @dev Helper function to return the token holder's address.
    function holder() internal pure virtual returns (address);

    /// @dev Helper function to return the token address.
    function token() internal pure virtual returns (address);
}
