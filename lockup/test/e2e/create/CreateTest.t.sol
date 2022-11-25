// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";

import { E2eTest } from "../E2eTest.t.sol";

abstract contract CreateTest is E2eTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    SD59x18[] internal segmentExponents = createDynamicArray(sd59x18(3.14e18));

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // Make the token holder the `msg.sender` in this test suite.
        vm.startPrank(holder());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev it should create the linear stream.
    function testCreateLinear(
        address sender,
        address recipient,
        uint256 depositAmount,
        uint64 startTime,
        uint64 cliffTime,
        uint64 stopTime,
        bool cancelable
    ) external {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= token().balanceOf(holder()));
        vm.assume(startTime <= cliffTime && cliffTime <= stopTime);

        // Pull the next stream id.
        uint256 expectedStreamId = sablierV2Linear.nextStreamId();

        // Create the stream.
        uint256 actualStreamId = sablierV2Linear.create(
            sender,
            recipient,
            depositAmount,
            token(),
            startTime,
            cliffTime,
            stopTime,
            cancelable
        );

        // Declare the expected stream struct.
        DataTypes.LinearStream memory stream = DataTypes.LinearStream({
            cancelable: cancelable,
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token(),
            withdrawnAmount: 0
        });

        // Run the tests.
        assertEq(actualStreamId, expectedStreamId);
        assertEq(sablierV2Linear.nextStreamId(), expectedStreamId + 1);
        assertEq(sablierV2Linear.getStream(actualStreamId), stream);
        assertEq(sablierV2Linear.getRecipient(actualStreamId), recipient);
    }

    /// @dev it should create the pro stream.
    function testCreatePro(
        address sender,
        address recipient,
        uint256 depositAmount,
        uint64 startTime,
        uint64 stopTime,
        bool cancelable
    ) external {
        vm.assume(sender != address(0));
        vm.assume(recipient != address(0));
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= token().balanceOf(holder()));
        vm.assume(startTime > 0); // needed for the segments to be ordered
        vm.assume(startTime <= stopTime);

        uint256[] memory segmentAmounts = createDynamicArray(depositAmount);
        uint64[] memory segmentMilestones = createDynamicUint64Array(stopTime);

        // Pull the next stream id.
        uint256 expectedStreamId = sablierV2Pro.nextStreamId();

        // Create the stream.
        uint256 actualStreamId = sablierV2Pro.create(
            sender,
            recipient,
            depositAmount,
            token(),
            startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            cancelable
        );

        // Declare the expected stream struct.
        DataTypes.ProStream memory expectedStream = DataTypes.ProStream({
            cancelable: cancelable,
            depositAmount: depositAmount,
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
        token().approve(address(sablierV2Linear), UINT256_MAX);
        token().approve(address(sablierV2Pro), UINT256_MAX);
    }

    /// @dev Helper function to return the token holder's address.
    function holder() internal pure virtual returns (address);

    /// @dev Helper function to return the token address.
    function token() internal pure virtual returns (IERC20);
}
