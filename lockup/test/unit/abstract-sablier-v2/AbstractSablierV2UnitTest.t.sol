// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { SablierV2 } from "@sablier/v2-core/SablierV2.sol";

import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

contract AbstractSablierV2 is SablierV2 {
    constructor() SablierV2() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external pure override returns (uint256 depositAmount) {
        streamId;
        depositAmount;
    }

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public pure override returns (address recipient) {
        streamId;
        recipient;
    }

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) external pure override returns (uint256 returnableAmount) {
        streamId;
        returnableAmount = 0;
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) public pure override returns (address sender) {
        streamId;
        sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external pure override returns (uint256 startTime) {
        streamId;
        startTime;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external pure override returns (uint256 stopTime) {
        streamId;
        stopTime;
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) external pure override returns (uint256 withdrawableAmount) {
        streamId;
        withdrawableAmount = 0;
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external pure override returns (uint256 withdrawnAmount) {
        streamId;
        withdrawnAmount;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public pure override returns (bool cancelable) {
        streamId;
        cancelable;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external pure override {
        streamId;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    function cancelInternal(uint256 streamId) internal pure override {
        streamId;
    }

    function withdrawInternal(
        uint256 streamId,
        address to,
        uint256 amount
    ) internal pure override {
        streamId;
        to;
        amount;
    }
}

/// @title AbstractSablierV2UnitTest
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract AbstractSablierV2UnitTest is SablierV2UnitTest {
    /// TESTING VARIABLES ///

    AbstractSablierV2 internal abstractSablierV2 = new AbstractSablierV2();

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }
}
