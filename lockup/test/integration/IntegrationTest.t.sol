// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20GodMode } from "@prb/contracts/token/erc20/ERC20GodMode.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";

import { BaseTest } from "../BaseTest.t.sol";

/// @title IntegrationTest
/// @notice Common contract members needed across Sablier V2 integration test contracts.
/// @dev Strictly for test purposes.
abstract contract IntegrationTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant STARTING_BLOCK_TIMESTAMP = 100 seconds;
    uint64 internal constant CLIFF_DURATION = 2_500 seconds;
    uint64 internal constant TOTAL_DURATION = 10_000 seconds;

    uint64 internal immutable CLIFF_TIME;
    uint256 internal immutable DEPOSIT_AMOUNT_DAI;
    uint256 internal immutable DEPOSIT_AMOUNT_USDC;
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
            sender: createUser("Sender"),
            recipient: createUser("Recipient"),
            operator: createUser("Operator"),
            eve: createUser("Eve"),
            alice: createUser("Alice")
        });
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

    /// @dev Generates an address by hashing the name, labels the address and
    /// funds it with 100 ETH, 1M DAI, 1M USDC and 1M non-standard tokens.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label(addr, name);
        vm.deal(addr, 100 ether);
        dai.mint(addr, 1_000_000e18);
        usdc.mint(addr, 1_000_000e6);
        nonCompliantToken.mint(addr, 1_000_000e18);
    }
}
