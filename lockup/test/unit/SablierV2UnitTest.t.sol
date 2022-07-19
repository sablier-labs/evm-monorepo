// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20GodMode } from "@prb/contracts/token/erc20/ERC20GodMode.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Test } from "forge-std/Test.sol";

/// @title SablierV2UnitTest
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2UnitTest is Test {
    /// EVENTS ///

    event Cancel(uint256 indexed streamId, address indexed recipient, uint256 withdrawAmount, uint256 returnAmount);

    event Renounce(uint256 indexed streamId);

    event Withdraw(uint256 indexed streamId, address indexed recipient, uint256 amount);

    /// CONSTANTS ///

    uint256 internal constant CLIFF_DURATION = 2_500 seconds;
    uint256 internal constant STARTING_BLOCK_TIMESTAMP = 100 seconds;
    uint256 internal constant TOTAL_DURATION = 10_000 seconds;

    uint256 internal immutable CLIFF_TIME;
    uint256 internal immutable DEPOSIT_AMOUNT_DAI;
    uint256 internal immutable DEPOSIT_AMOUNT_USDC;
    uint256 internal immutable START_TIME;
    uint256 internal immutable STOP_TIME;

    /// STRUCTS ///

    struct Users {
        address payable alice;
        address payable eve;
        address payable recipient;
        address payable sender;
    }

    /// STORAGE ///

    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));
    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Stablecoin", "USD", 18);
    ERC20GodMode internal dai = new ERC20GodMode("Dai Stablecoin", "DAI", 18);
    ERC20GodMode internal usdc = new ERC20GodMode("USD Coin", "USDC", 6);
    Users internal users;

    /// CONSTRUCTOR ///

    constructor() {
        // By default the test EVM begins at time zero, but in some of our tests we need to warp back in time, so we
        // have to change the default to something else (100 seconds into the future).
        vm.warp(STARTING_BLOCK_TIMESTAMP);

        // Initialize the default stream values.
        CLIFF_TIME = block.timestamp + CLIFF_DURATION;
        DEPOSIT_AMOUNT_DAI = bn(10_000, 18);
        DEPOSIT_AMOUNT_USDC = bn(10_000, 6);
        START_TIME = block.timestamp;
        STOP_TIME = block.timestamp + TOTAL_DURATION;

        // Create 5 users for testing. Order matters.
        users = Users({ sender: getNextUser(), recipient: getNextUser(), eve: getNextUser(), alice: getNextUser() });
        fundUser(users.sender);
        vm.label(users.sender, "Sender");

        fundUser(users.recipient);
        vm.label(users.recipient, "Recipient");

        fundUser(users.eve);
        vm.label(users.eve, "Eve");

        fundUser(users.alice);
        vm.label(users.alice, "Alice");
    }

    /// CONSTANT FUNCTIONS ///

    /// @dev Helper function that multiplies the `amount` by `10^decimals` and returns a `uint256.`
    function bn(uint256 amount, uint256 decimals) internal pure returns (uint256 result) {
        result = amount * 10**decimals;
    }

    /// @dev Helper function to convert an int256 number to type `SD59x18`.
    function sd59x18(int256 number) internal pure returns (SD59x18 result) {
        result = SD59x18.wrap(number);
    }

    /// @dev Helper function to convert a uint256 number to type `UD60x18`.
    function ud60x18(uint256 number) internal pure returns (UD60x18 result) {
        result = UD60x18.wrap(number);
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to compare two `IERC20` addresses.
    function assertEq(IERC20 a, IERC20 b) internal {
        assertEq(address(a), address(b));
    }

    /// @dev Helper function to create a dynamical `uint256` array with 1 element.
    function createDynamicArray(uint256 element0) internal pure returns (uint256[] memory dynamicalArray) {
        dynamicalArray = new uint256[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `SD59x18` array with 1 element.
    function createDynamicArray(SD59x18 element0) internal pure returns (SD59x18[] memory dynamicalArray) {
        dynamicalArray = new SD59x18[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `SD59x18` array with 2 elements.
    function createDynamicArray(SD59x18 element0, SD59x18 element1)
        internal
        pure
        returns (SD59x18[] memory dynamicalArray)
    {
        dynamicalArray = new SD59x18[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint256` array with 2 elements.
    function createDynamicArray(uint256 element0, uint256 element1)
        internal
        pure
        returns (uint256[] memory dynamicalArray)
    {
        dynamicalArray = new uint256[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint256` array with 3 elements.
    function createDynamicArray(
        uint256 element0,
        uint256 element1,
        uint256 element2
    ) internal pure returns (uint256[] memory dynamicalArray) {
        dynamicalArray = new uint256[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Helper function to create a dynamical `SD59x18` array with 3 elements.
    function createDynamicArray(
        SD59x18 element0,
        SD59x18 element1,
        SD59x18 element2
    ) internal pure returns (SD59x18[] memory dynamicalArray) {
        dynamicalArray = new SD59x18[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Give each user 100 ETH, 1M DAI, 1M USDC and 1M non-standard tokens.
    function fundUser(address payable user) internal {
        vm.deal(user, 100 ether);
        dai.mint(user, bn(1_000_000, 18));
        usdc.mint(user, bn(1_000_000, 6));
        nonCompliantToken.mint(user, bn(1_000_000, 18));
    }

    /// @dev Converts bytes32 to address.
    function getNextUser() internal returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }
}
