// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { BaseTest } from "../BaseTest.t.sol";
import { Empty } from "../shared/Empty.t.sol";
import { NonRevertingRecipient } from "../shared/NonRevertingRecipient.t.sol";
import { NonRevertingSender } from "../shared/NonRevertingSender.t.sol";
import { ReentrantRecipient } from "../shared/ReentrantRecipient.t.sol";
import { ReentrantSender } from "../shared/ReentrantSender.t.sol";
import { RevertingRecipient } from "../shared/RevertingRecipient.t.sol";
import { RevertingSender } from "../shared/RevertingSender.t.sol";

/// @title UnitTest
/// @notice Common contract members needed across Sablier V2 unit tests.
abstract contract UnitTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant STARTING_BLOCK_TIMESTAMP = 100 seconds;
    uint40 internal constant CLIFF_DURATION = 2_500 seconds;
    uint40 internal constant TOTAL_DURATION = 10_000 seconds;

    uint40 internal immutable CLIFF_TIME;
    uint128 internal immutable DEPOSIT_AMOUNT_DAI;
    uint128 internal immutable DEPOSIT_AMOUNT_USDC;
    uint40 internal immutable START_TIME;
    uint40 internal immutable STOP_TIME;

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        address payable alice;
        address payable eve;
        address payable operator;
        address payable owner;
        address payable recipient;
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    Empty internal empty = new Empty();
    ERC20GodMode internal dai = new ERC20GodMode("Dai Stablecoin", "DAI", 18);
    ERC20GodMode internal usdc = new ERC20GodMode("USD Coin", "USDC", 6);
    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Non-Compliant Token", "NCT", 18);
    NonRevertingRecipient internal nonRevertingRecipient = new NonRevertingRecipient();
    NonRevertingSender internal nonRevertingSender = new NonRevertingSender();
    ReentrantRecipient internal reentrantRecipient = new ReentrantRecipient();
    ReentrantSender internal reentrantSender = new ReentrantSender();
    RevertingRecipient internal revertingRecipient = new RevertingRecipient();
    RevertingSender internal revertingSender = new RevertingSender();
    SablierV2Comptroller internal sablierV2Comptroller;
    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        // By default the test EVM begins at time zero, but we need to warp back in time in some of our tests, so we
        // have to change the default to something else (100 seconds into the future).
        vm.warp(STARTING_BLOCK_TIMESTAMP);

        // Initialize the default stream values.
        CLIFF_TIME = uint40(block.timestamp) + CLIFF_DURATION;
        DEPOSIT_AMOUNT_DAI = 10_000e18;
        DEPOSIT_AMOUNT_USDC = 10_000e6;
        START_TIME = uint40(block.timestamp);
        STOP_TIME = uint40(block.timestamp) + TOTAL_DURATION;

        // Create users for testing.
        users = Users({
            alice: createUser("Alice"),
            eve: createUser("Eve"),
            operator: createUser("Operator"),
            owner: createUser("Owner"),
            recipient: createUser("Recipient"),
            sender: createUser("Sender")
        });

        // Deploy the comptroller, since it's needed in all test suites.
        vm.startPrank({ msgSender: users.owner });
        sablierV2Comptroller = new SablierV2Comptroller();
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to approve `spender` the `UINT256_MAX` amount with `caller` as the `msg.sender`.
    function approveMax(address caller, address spender) internal {
        changePrank(caller);
        dai.approve({ spender: spender, value: UINT256_MAX });
        usdc.approve({ spender: spender, value: UINT256_MAX });
        nonCompliantToken.approve({ spender: spender, value: UINT256_MAX });
    }

    /// @dev Generates an address by hashing the name, labels the address and
    /// funds it with 100 ETH, 1M DAI, 1M USDC and 1M non-standard tokens.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label(addr, name);
        vm.deal(addr, 100 ether);
        deal({ token: address(dai), to: addr, give: 1_000_000e18, adjust: true });
        deal({ token: address(usdc), to: addr, give: 1_000_000e6, adjust: true });
        deal({ token: address(nonCompliantToken), to: addr, give: 1_000_000e18, adjust: true });
    }
}
