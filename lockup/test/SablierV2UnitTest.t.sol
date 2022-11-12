// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20GodMode } from "@prb/contracts/token/erc20/ERC20GodMode.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { StdCheats, StdUtils } from "forge-std/Components.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title SablierV2UnitTest
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2UnitTest is PRBTest, StdCheats, StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, uint64[] value);

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint64 internal constant UINT64_MAX = type(uint64).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;

    uint256 internal constant STARTING_BLOCK_TIMESTAMP = 100 seconds;
    uint64 internal constant CLIFF_DURATION = 2_500 seconds;
    uint64 internal constant TOTAL_DURATION = 10_000 seconds;

    uint256 internal immutable DEPOSIT_AMOUNT_DAI;
    uint256 internal immutable DEPOSIT_AMOUNT_USDC;
    uint64 internal immutable CLIFF_TIME;
    uint64 internal immutable START_TIME;
    uint64 internal immutable STOP_TIME;

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        address payable alice;
        address payable eve;
        address payable operator;
        address payable recipient;
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Stablecoin", "USD", 18);
    ERC20GodMode internal dai = new ERC20GodMode("Dai Stablecoin", "DAI", 18);
    ERC20GodMode internal usdc = new ERC20GodMode("USD Coin", "USDC", 6);
    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        // By default the test EVM begins at time zero, but in some of our tests we need to warp back in time, so we
        // have to change the default to something else (100 seconds into the future).
        vm.warp(STARTING_BLOCK_TIMESTAMP);

        // Initialize the default stream values.
        CLIFF_TIME = uint64(block.timestamp) + CLIFF_DURATION;
        DEPOSIT_AMOUNT_DAI = 10_000e18;
        DEPOSIT_AMOUNT_USDC = 10_000e6;
        START_TIME = uint64(block.timestamp);
        STOP_TIME = uint64(block.timestamp) + TOTAL_DURATION;

        // Create 5 users for testing. Order matters.
        users = Users({
            sender: mkaddrFunded("Sender"),
            recipient: mkaddrFunded("Recipient"),
            operator: mkaddrFunded("Operator"),
            eve: mkaddrFunded("Eve"),
            alice: mkaddrFunded("Alice")
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to convert an int256 number to type `SD59x18`.
    function sd59x18(int256 number) internal pure returns (SD59x18 result) {
        result = SD59x18.wrap(number);
    }

    /// @dev Helper function to convert a uint256 number to type `UD60x18`.
    function ud60x18(uint256 number) internal pure returns (UD60x18 result) {
        result = UD60x18.wrap(number);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to approve `spender` the `UINT256_MAX` amount with `caller` as the `msg.sender`.
    function approveMax(address caller, address spender) internal {
        changePrank(caller);
        dai.approve(spender, UINT256_MAX);
        usdc.approve(spender, UINT256_MAX);
        nonCompliantToken.approve(spender, UINT256_MAX);
    }

    /// @dev Helper function to compare two `IERC20` addresses.
    function assertEq(IERC20 a, IERC20 b) internal {
        assertEq(address(a), address(b));
    }

    /// @dev Helper function to compare two `uint64` arrays.
    function assertEqUint64Array(uint64[] memory a, uint64[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint64[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
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

    /// @dev Helper function to create a dynamical `uint64` array with 1 element.
    function createDynamicUint64Array(uint64 element0) internal pure returns (uint64[] memory dynamicalArray) {
        dynamicalArray = new uint64[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `uint64` array with 2 elements.
    function createDynamicUint64Array(uint64 element0, uint64 element1)
        internal
        pure
        returns (uint64[] memory dynamicalArray)
    {
        dynamicalArray = new uint64[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint64` array with 3 elements.
    function createDynamicUint64Array(
        uint64 element0,
        uint64 element1,
        uint64 element2
    ) internal pure returns (uint64[] memory dynamicalArray) {
        dynamicalArray = new uint64[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Generates an address by hashing the name, labels the address and
    /// funds it with 100 ETH, 1M DAI, 1M USDC and 1M non-standard tokens.
    function mkaddrFunded(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label(addr, name);
        vm.deal(addr, 100 ether);
        dai.mint(addr, 1_000_000e18);
        usdc.mint(addr, 1_000_000e6);
        nonCompliantToken.mint(addr, 1_000_000e18);
    }
}
