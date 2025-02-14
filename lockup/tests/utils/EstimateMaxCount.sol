// solhint-disable no-console
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { console } from "forge-std/src/console.sol";
import { ERC20Mock } from "@sablier/evm-utils/tests/mocks/erc20/ERC20Mock.sol";

import { ISablierLockup } from "../../src/interfaces/ISablierLockup.sol";
import { Lockup, LockupDynamic } from "../../src/types/DataTypes.sol";
import { Defaults } from "./Defaults.sol";
import { DeployOptimized } from "./DeployOptimized.t.sol";
import { Users } from "./Types.sol";

/// @notice Structure to group the block gas limit and chain id.
struct ChainInfo {
    uint256 blockGasLimit;
    uint256 chainId;
}

/// @notice Estimate the maximum number of segments allowed in a Lockup Dynamic stream.
contract EstimateMaxCount is Defaults, DeployOptimized {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128 public constant AMOUNT_PER_SEGMENT = 1e18;

    // Buffer gas units to be deducted from the block gas limit so that the max count never exceeds the block limit.
    uint256 public constant BUFFER_GAS = 1_000_000;

    // Initial guess for the maximum number of segments/tranches.
    uint128 public constant INITIAL_GUESS = 240;

    /// @dev List of chains with their block gas limit.
    ChainInfo[] public chains;

    ISablierLockup public lockup;
    Users public users;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        // Initialize the variables.
        dai = new ERC20Mock("Dai stablecoin", "DAI", 18);
        setToken(dai);
        users.sender = users.recipient = payable(makeAddr("sender"));
        setUsers(users);

        // Deploy the optimized Lockup contract.
        (, lockup,) = deployOptimizedProtocol({ initialAdmin: users.sender, maxCount: MAX_COUNT });

        // Set up the caller.
        resetPrank(users.sender);
        deal({ token: address(dai), to: users.sender, give: type(uint256).max });
        dai.approve(address(lockup), type(uint256).max);

        // Create dummy streams to initialize contract storage.
        for (uint128 i = 0; i < 100; ++i) {
            lockup.createWithTimestampsLD(createWithTimestamps(), segments());
        }

        // Populate the chains array with respective block gas limit for each chain ID.
        chains.push(ChainInfo({ blockGasLimit: 32_000_000, chainId: 42_161 })); // Arbitrum
        chains.push(ChainInfo({ blockGasLimit: 15_000_000, chainId: 43_114 })); // Avalanche
        chains.push(ChainInfo({ blockGasLimit: 60_000_000, chainId: 8453 })); // Base
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 81_457 })); // Blast
        chains.push(ChainInfo({ blockGasLimit: 138_000_000, chainId: 56 })); // BSC
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 1 })); // Ethereum
        chains.push(ChainInfo({ blockGasLimit: 17_000_000, chainId: 100 })); // Gnosis
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 10 })); // Optimism
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 137 })); // Polygon
        chains.push(ChainInfo({ blockGasLimit: 10_000_000, chainId: 534_352 })); // Scroll
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 11_155_111 })); // Sepolia
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ESTIMATE-COUNT-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function test_EstimateSegments() public {
        // Estimate the maximum number of segments for each chain.
        for (uint256 i = 0; i < chains.length; ++i) {
            uint128 count = INITIAL_GUESS;

            // Subtract `BUFFER_GAS` from `blockGasLimit` as an additional precaution to account for the dynamic gas for
            // ether transfer on different chains.
            uint256 blockGasLimit = chains[i].blockGasLimit - BUFFER_GAS;

            uint256 gasConsumed = 0;
            uint256 lastGasConsumed = 0;
            while (blockGasLimit > gasConsumed) {
                count += 10;
                lastGasConsumed = gasConsumed;

                // Estimate the gas consumed by adding 10 segments.
                (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments) =
                    _createWithDurationParamsLD({ totalSegments: count + 10 });

                uint256 beforeGas = gasleft();
                lockup.createWithDurationsLD(params, segments);

                gasConsumed = beforeGas - gasleft();
            }

            console.log("count: %d and gasUsed: %d and chainId: %d", count, lastGasConsumed, chains[i].chainId);
        }
    }

    // Helper function to return the parameters of `createWithDurationsLD`.
    function _createWithDurationParamsLD(uint128 totalSegments)
        private
        view
        returns (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments_)
    {
        segments_ = new LockupDynamic.SegmentWithDuration[](totalSegments);

        // Populate segments.
        for (uint256 i = 0; i < totalSegments; ++i) {
            segments_[i] = (
                LockupDynamic.SegmentWithDuration({
                    amount: AMOUNT_PER_SEGMENT,
                    exponent: ud2x18(0.5e18),
                    duration: CLIFF_DURATION
                })
            );
        }

        params = createWithDurations();
        params.depositAmount = AMOUNT_PER_SEGMENT * totalSegments;
        return (params, segments_);
    }
}
