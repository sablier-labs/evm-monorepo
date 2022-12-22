// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { UD60x18, UNIT } from "@prb/math/UD60x18.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { BaseTest } from "../BaseTest.t.sol";
import { Empty } from "../shared/Empty.t.sol";
import { GoodRecipient } from "../shared/GoodRecipient.t.sol";
import { GoodSender } from "../shared/GoodSender.t.sol";
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

    uint40 internal constant DEFAULT_CLIFF_DURATION = 2_500 seconds;
    uint128 internal constant DEFAULT_GROSS_DEPOSIT_AMOUNT = 10_040.160642570281124497e18; // net deposit * (1 - fee)
    uint128 internal constant DEFAULT_NET_DEPOSIT_AMOUNT = 10_000e18;
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    UD60x18 internal constant DEFAULT_OPERATOR_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of gross deposit
    uint128 internal constant DEFAULT_OPERATOR_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of gross deposit
    uint40 internal constant DEFAULT_TOTAL_DURATION = 10_000 seconds;
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
        // Neutral user.
        address payable alice;
        // Malicious user.
        address payable eve;
        // Default NFT operator.
        address payable operator;
        // Default owner of all Sablier V2 contracts.
        address payable owner;
        // Default recipient of the stream.
        address payable recipient;
        // Default sender of the stream.
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    Empty internal empty = new Empty();
    ERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);
    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Non-Compliant Token", "NCT", 18);
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();
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
        DEFAULT_CLIFF_TIME = getBlockTimestamp() + DEFAULT_CLIFF_DURATION;
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_STOP_TIME = getBlockTimestamp() + DEFAULT_TOTAL_DURATION;

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
        nonCompliantToken.approve({ spender: spender, value: UINT256_MAX });
    }

    /// @dev Generates an address by hashing the name, labels the address and
    /// funds it with 100 ETH, 1M DAI, 1M USDC and 1M non-standard tokens.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label(addr, name);
        vm.deal(addr, 100 ether);
        deal({ token: address(dai), to: addr, give: 1_000_000e18, adjust: true });
        deal({ token: address(nonCompliantToken), to: addr, give: 1_000_000e18, adjust: true });
    }

    /// @dev Deploys a token with the provided decimals and funds the user with the provided token amount.
    function deployAndDealToken(uint8 decimals, address user, uint256 give) internal returns (address token) {
        token = address(new ERC20("Test Token", "TKN", decimals));
        deal({ token: token, to: user, give: give, adjust: true });
    }
}
