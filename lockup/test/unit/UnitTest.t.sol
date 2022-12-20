// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

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

    uint128 internal constant DEFAULT_GROSS_DEPOSIT_AMOUNT = 10_000e18;
    uint128 internal constant DEFAULT_NET_DEPOSIT_AMOUNT = DEFAULT_GROSS_DEPOSIT_AMOUNT - DEFAULT_OPERATOR_FEE_AMOUNT;
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    UD60x18 internal constant DEFAULT_OPERATOR_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10e18;
    uint128 internal constant DEFAULT_OPERATOR_FEE_AMOUNT = 30e18;
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18); // 10%

    /*//////////////////////////////////////////////////////////////////////////
                                     IMMUTABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal immutable DEFAULT_CLIFF_TIME;
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal immutable DEFAULT_STOP_TIME;

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
    ERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);
    ERC20 internal usdc = new ERC20("USD Coin", "USDC", 6);
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
        // have to change the starting block timestamp to be 100 seconds into the future.
        vm.warp(100 seconds);

        // Initialize the default stream values.
        DEFAULT_CLIFF_TIME = uint40(block.timestamp) + 2_500 seconds;
        DEFAULT_START_TIME = uint40(block.timestamp);
        DEFAULT_STOP_TIME = uint40(block.timestamp) + 10_000 seconds;

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

    /// @dev Deploys a token with the provided decimals and funds the user with the provided token amount.
    function deployAndDealToken(
        uint8 decimals,
        address user,
        uint256 give
    ) internal returns (address token) {
        token = address(new ERC20("Test Token", "TKN", decimals));
        deal({ token: token, to: user, give: give, adjust: true });
    }
}
