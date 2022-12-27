// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import { DataTypes } from "src/types/DataTypes.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { Empty } from "./shared/Empty.t.sol";
import { GoodRecipient } from "./shared/GoodRecipient.t.sol";
import { GoodSender } from "./shared/GoodSender.t.sol";
import { ReentrantRecipient } from "./shared/ReentrantRecipient.t.sol";
import { ReentrantSender } from "./shared/ReentrantSender.t.sol";
import { RevertingRecipient } from "./shared/RevertingRecipient.t.sol";
import { RevertingSender } from "./shared/RevertingSender.t.sol";

abstract contract BaseTest is PRBTest, StdCheats, StdUtils, PRBMathAssertions, PRBMathUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, SD1x18[] value);

    event LogNamedArray(string key, uint40[] value);

    event LogNamedArray(string key, uint128[] value);

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal constant DEFAULT_CLIFF_DURATION = 2_500 seconds;
    uint128 internal constant DEFAULT_GROSS_DEPOSIT_AMOUNT = 10_040.160642570281124497e18; // net deposit / (1 - fee)
    uint128 internal constant DEFAULT_NET_DEPOSIT_AMOUNT = 10_000e18;
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    UD60x18 internal constant DEFAULT_OPERATOR_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of gross deposit
    uint128 internal constant DEFAULT_OPERATOR_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of gross deposit
    uint40 internal constant DEFAULT_TOTAL_DURATION = 10_000 seconds;
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint40 internal constant UINT40_MAX = type(uint40).max;
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;

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
        // Recipient of the default stream.
        address payable recipient;
        // Sender of the default stream.
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Comptroller internal comptroller;
    SablierV2Linear internal linear;
    SablierV2Pro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    Empty internal empty = new Empty();
    ERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();
    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Non-Compliant Token", "NCT", 18);
    ReentrantRecipient internal reentrantRecipient = new ReentrantRecipient();
    ReentrantSender internal reentrantSender = new ReentrantSender();
    RevertingRecipient internal revertingRecipient = new RevertingRecipient();
    RevertingSender internal revertingSender = new RevertingSender();

    /*//////////////////////////////////////////////////////////////////////////
                                      STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    constructor() {
        // Initialize the immutables.
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_STOP_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create users for testing.
        users = Users({
            alice: createUser("Alice"),
            eve: createUser("Eve"),
            operator: createUser("Operator"),
            owner: createUser("Owner"),
            recipient: createUser("Recipient"),
            sender: createUser("Sender")
        });

        // Deploy all contracts.
        deployContracts();

        // Label all contracts.
        labelContracts();

        // Approve all contracts.
        approveContracts();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to bound a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal view returns (uint40 result) {
        result = uint40(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Helper function to bound a `uint40` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal view returns (uint128 result) {
        result = uint128(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Calculates the protocol fee amount, the operator fee amount, and the net deposit amount.
    function calculateFeeAmounts(
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        UD60x18 operatorFee
    ) internal pure returns (uint128 protocolFeeAmount, uint128 operatorFeeAmount, uint128 netDepositAmount) {
        protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(protocolFee)));
        operatorFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(operatorFee)));
        netDepositAmount = grossDepositAmount - protocolFeeAmount - operatorFeeAmount;
    }

    /// @dev Helper function to retrieve the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve all Sablier contracts to spend tokens from the sender, recipient, Alice and Eve.
    function approveContracts() internal {
        approveMax({ caller: users.sender, spender: address(linear) });
        approveMax({ caller: users.recipient, spender: address(linear) });
        approveMax({ caller: users.alice, spender: address(linear) });
        approveMax({ caller: users.eve, spender: address(linear) });
        approveMax({ caller: users.sender, spender: address(pro) });
        approveMax({ caller: users.recipient, spender: address(pro) });
        approveMax({ caller: users.alice, spender: address(pro) });
        approveMax({ caller: users.eve, spender: address(pro) });
        changePrank(users.owner);
    }

    /// @dev Helper function to approve `spender` the `UINT256_MAX` amount with `caller` as the `msg.sender`.
    function approveMax(address caller, address spender) internal {
        changePrank(caller);
        dai.approve({ spender: spender, value: UINT256_MAX });
        nonCompliantToken.approve({ spender: spender, value: UINT256_MAX });
    }

    /// @dev Helper function to compare two `LinearStream` structs.
    function assertEq(DataTypes.LinearStream memory a, DataTypes.LinearStream memory b) internal {
        assertEq(uint256(a.cliffTime), uint256(b.cliffTime));
        assertEq(uint256(a.depositAmount), uint256(b.depositAmount));
        assertEq(a.isCancelable, b.isCancelable);
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEq(a.token, b.token);
        assertEq(uint256(a.withdrawnAmount), uint256(b.withdrawnAmount));
    }

    /// @dev Helper function to compare two `ProStream` structs.
    function assertEq(DataTypes.ProStream memory a, DataTypes.ProStream memory b) internal {
        assertEq(uint256(a.depositAmount), uint256(b.depositAmount));
        assertEq(a.isCancelable, b.isCancelable);
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEqUint128Array(a.segmentAmounts, b.segmentAmounts);
        assertEq(a.segmentExponents, b.segmentExponents);
        assertEqUint40Array(a.segmentMilestones, b.segmentMilestones);
        assertEq(a.token, b.token);
        assertEq(uint256(a.withdrawnAmount), uint256(b.withdrawnAmount));
    }

    /// @dev Helper function to compare two `uint128` arrays.
    function assertEqUint128Array(uint128[] memory a, uint128[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint128[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Helper function to compare two `uint40` arrays.
    function assertEqUint40Array(uint40[] memory a, uint40[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint40[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    ///  and 1 million non-compliant tokens.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label({ account: addr, newLabel: name });
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(nonCompliantToken), to: addr, give: 1_000_000e18 });
    }

    /// @dev Deploy all contracts with the owner as the caller.
    function deployContracts() internal {
        vm.startPrank({ msgSender: users.owner });
        comptroller = new SablierV2Comptroller();
        linear = new SablierV2Linear({ initialComptroller: comptroller, maxFee: MAX_FEE });
        pro = new SablierV2Pro({
            initialComptroller: comptroller,
            maxFee: MAX_FEE,
            maxSegmentCount: MAX_SEGMENT_COUNT
        });
    }

    /// @dev Label all contracts, which helps during debugging.
    function labelContracts() internal {
        // Label the Sablier contracts.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(linear), newLabel: "SablierV2Linear" });
        vm.label({ account: address(pro), newLabel: "SablierV2Pro" });

        // Label the test contracts.
        vm.label({ account: address(empty), newLabel: "Empty" });
        vm.label({ account: address(dai), newLabel: "Dai" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(goodSender), newLabel: "Good Sender" });
        vm.label({ account: address(nonCompliantToken), newLabel: "Non-Compliant Token" });
        vm.label({ account: address(reentrantRecipient), newLabel: "Reentrant Recipient" });
        vm.label({ account: address(reentrantSender), newLabel: "Reentrant Sender" });
        vm.label({ account: address(revertingRecipient), newLabel: "Reverting Recipient" });
        vm.label({ account: address(revertingSender), newLabel: "Reverting Sender" });
    }
}
