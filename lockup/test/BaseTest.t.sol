// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { sd1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Amounts, Range, Segment } from "src/types/Structs.sol";

import { Assertions } from "./helpers/Assertions.t.sol";
import { Utils } from "./helpers/Utils.t.sol";

abstract contract BaseTest is Assertions, StdCheats, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal constant DEFAULT_CLIFF_DURATION = 2_500 seconds;
    uint128 internal constant DEFAULT_GROSS_DEPOSIT_AMOUNT = 10_040.160642570281124497e18; // net deposit / (1 - fee)
    UD60x18 internal constant DEFAULT_MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint256 internal constant DEFAULT_MAX_SEGMENT_COUNT = 200;
    uint128 internal constant DEFAULT_NET_DEPOSIT_AMOUNT = 10_000e18;
    UD60x18 internal constant DEFAULT_OPERATOR_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 internal constant DEFAULT_OPERATOR_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of gross deposit
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of gross deposit
    uint40 internal constant DEFAULT_TIME_WARP = 2_600 seconds;
    uint40 internal constant DEFAULT_TOTAL_DURATION = 10_000 seconds;
    uint128 internal constant DEFAULT_WITHDRAW_AMOUNT = 2_600e18;
    uint256 internal constant UINT256_MAX = type(uint256).max;
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint40 internal constant UINT40_MAX = type(uint40).max;

    /*//////////////////////////////////////////////////////////////////////////
                                     IMMUTABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal immutable DEFAULT_CLIFF_TIME;
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal immutable DEFAULT_STOP_TIME;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Amounts internal DEFAULT_AMOUNTS = Amounts({ deposit: DEFAULT_NET_DEPOSIT_AMOUNT, withdrawn: 0 });
    Range internal DEFAULT_RANGE;
    Segment[] internal DEFAULT_SEGMENTS;
    uint40[] internal DEFAULT_SEGMENT_DELTAS = [2_500 seconds, 7_500 seconds];

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_STOP_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;

        DEFAULT_RANGE = Range({ start: DEFAULT_START_TIME, cliff: DEFAULT_CLIFF_TIME, stop: DEFAULT_STOP_TIME });

        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 2_500e18,
                exponent: sd1x18(3.14e18),
                milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
            })
        );

        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 7_500e18,
                exponent: sd1x18(0.5e18),
                milestone: DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Adjust the amounts in the default segments as two fractions of the provided net deposit amount,
    /// one 20%, the other 80%.
    function adjustSegmentAmounts(Segment[] memory segments, uint128 netDepositAmount) internal pure {
        segments[0].amount = uint128(UD60x18.unwrap(ud(netDepositAmount).mul(ud(0.2e18))));
        segments[1].amount = netDepositAmount - segments[0].amount;
    }

    /// @dev Helper function to retrieve the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }
}
