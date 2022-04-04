/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { NonStandardERC20 } from "@prb/contracts/token/erc20/NonStandardERC20.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

import { DSTest } from "ds-test/test.sol";
import { console } from "forge-std/console.sol";
import { Vm } from "forge-std/Vm.sol";

import { GodModeERC20 } from "../shared/GodModeERC20.t.sol";

/// @title GodModeERC20
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2UnitTest is DSTest {
    /// EVENTS ///

    event Cancel(uint256 indexed streamId, address indexed recipient, uint256 withdrawAmount, uint256 returnAmount);

    event CreateLinearStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    );

    event LetGo(uint256 indexed streamId);

    event Withdraw(uint256 indexed streamId, address indexed recipient, uint256 amount);

    /// CONSTANTS ///

    uint256 internal immutable DEFAULT_DEPOSIT;
    uint256 internal constant DEFAULT_DURATION = 3600 seconds;
    uint256 internal immutable DEFAULT_START_TIME;
    uint256 internal immutable DEFAULT_STOP_TIME;
    uint256 internal immutable DEFAULT_WITHDRAW_AMOUNT;
    uint256 internal constant DEFAULT_TIME_OFFSET = 36 seconds;
    uint256 internal constant STARTING_BLOCK_TIMESTAMP = 314 seconds;

    /// STRUCTS ///

    struct Users {
        address payable eve;
        address payable funder;
        address payable recipient;
        address payable sender;
    }

    /// STORAGE ///

    // Generic testing variables
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));
    NonStandardERC20 internal nonStandardToken = new NonStandardERC20("Stablecoin", "USD", 18);
    GodModeERC20 internal usd = new GodModeERC20("Stablecoin", "USD", 18);
    Vm internal vm = Vm(HEVM_ADDRESS);
    Users internal users;

    // Sablier-specific testing variables
    SablierV2Linear internal sablierV2Linear = new SablierV2Linear();
    ISablierV2Linear.LinearStream internal linearStream;

    /// CONSTRUCTOR ///

    constructor() {
        // By default the test EVM begins at time zero, but some of our tests need to warp back in time, so we
        // change the default to something else (314 seconds into the future).
        vm.warp(STARTING_BLOCK_TIMESTAMP);

        // Initialize the default stream values.
        DEFAULT_DEPOSIT = bn(3600);
        DEFAULT_START_TIME = block.timestamp;
        DEFAULT_STOP_TIME = block.timestamp + DEFAULT_DURATION;
        DEFAULT_WITHDRAW_AMOUNT = bn(36);

        // Create 4 users for testing. Order matters.
        users = Users({ sender: getNextUser(), recipient: getNextUser(), funder: getNextUser(), eve: getNextUser() });
        fundUser(users.sender);
        vm.label(users.sender, "Sender");

        fundUser(users.recipient);
        vm.label(users.recipient, "Recipient");

        fundUser(users.funder);
        vm.label(users.funder, "Funder");

        fundUser(users.eve);
        vm.label(users.eve, "Eve");
    }

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default linear stream to be used across many tests.
        linearStream = ISablierV2Linear.LinearStream({
            cancelable: true,
            depositAmount: DEFAULT_DEPOSIT,
            recipient: users.recipient,
            sender: users.sender,
            startTime: DEFAULT_START_TIME,
            stopTime: DEFAULT_STOP_TIME,
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Linear contract to spend $USD from the `sender` and the `funder`'s accounts.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Linear), type(uint256).max);

        vm.prank(users.funder);
        usd.approve(address(sablierV2Linear), type(uint256).max);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }

    /// CONSTANT FUNCTIONS ///

    /// @dev Helper function that multiplies the `amount` by `10^18`.
    function bn(uint256 amount) internal pure returns (uint256 result) {
        result = bn(amount, 18);
    }

    /// @dev Helper function that multiplies the `amount` by `10^decimals`.
    function bn(uint256 amount, uint256 decimals) internal pure returns (uint256 result) {
        result = amount * 10**decimals;
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to compare two booleans,
    function assertEq(bool a, bool b) internal {
        assertTrue(a == b);
    }

    /// @dev Helper function to compare two `IERC20` addresses.
    function assertEq(IERC20 a, IERC20 b) internal {
        assertEq(address(a), address(b));
    }

    /// @dev Helper function to compare two `LinearStream` structs.
    function assertEq(ISablierV2Linear.LinearStream memory a, ISablierV2Linear.LinearStream memory b) internal {
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.recipient, b.recipient);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.stopTime, b.stopTime);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev ...
    function createDefaultLinearStream() internal returns (uint256 streamId) {
        streamId = sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );
    }

    /// @dev Give user 100 ETH and 1M USD.
    function fundUser(address payable user) internal {
        vm.deal(user, 100 ether);
        usd.mint(user, bn(1_000_000));
    }

    /// @dev Converts bytes32 to address.
    function getNextUser() internal returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }
}
