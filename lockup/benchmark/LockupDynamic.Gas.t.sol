// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Lockup, LockupDynamic } from "../src/types/DataTypes.sol";

import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark Lockup streams created using Dynamic model.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract Lockup_Dynamic_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal _segments = [2, 10, 100];
    uint256[] internal _streamIdsForWithdraw = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                        SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Benchmark_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierLockup_Dynamic.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat(
                "# Benchmarks for the Lockup Dynamic model\n\n", "| Implementation | Gas Usage |\n", "| --- | --- |\n"
            )
        });

        vm.warp({ newTimestamp: defaults.END_TIME() });
        gasBurn();

        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        gasCancel();

        gasRenounce();

        // Create streams with different number of segments.
        for (uint256 i; i < _segments.length; ++i) {
            gasCreateWithDurationsLD({ totalSegments: _segments[i] });
            gasCreateWithTimestampsLD({ totalSegments: _segments[i] });

            gasWithdraw_ByRecipient(
                _streamIdsForWithdraw[0],
                _streamIdsForWithdraw[1],
                string.concat("(", vm.toString(_segments[i]), " segments)")
            );
            gasWithdraw_ByAnyone(
                _streamIdsForWithdraw[2],
                _streamIdsForWithdraw[3],
                string.concat("(", vm.toString(_segments[i]), " segments)")
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                        GAS BENCHMARKS FOR CREATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // The following function is used in the estimations of `MAX_COUNT`.
    function computeGas_CreateWithDurationsLD(uint128 totalSegments) public returns (uint256 gasUsed) {
        (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments) =
            _createWithDurationParamsLD(totalSegments, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLD(params, segments);

        gasUsed = beforeGas - gasleft();
    }

    function gasCreateWithDurationsLD(uint128 totalSegments) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        (Lockup.CreateWithDurations memory params, LockupDynamic.SegmentWithDuration[] memory segments) =
            _createWithDurationParamsLD(totalSegments, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLD(params, segments);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLD` (", vm.toString(totalSegments), " segments) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        (params, segments) = _createWithDurationParamsLD(totalSegments, ud(0));

        beforeGas = gasleft();
        lockup.createWithDurationsLD(params, segments);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLD` (",
            vm.toString(totalSegments),
            " segments) (Broker fee not set) | ",
            gasUsed,
            " |"
        );

        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Store the last 2 streams IDs for withdraw gas benchmark.
        _streamIdsForWithdraw[0] = lockup.nextStreamId() - 2;
        _streamIdsForWithdraw[1] = lockup.nextStreamId() - 1;

        // Create 2 more streams for withdraw gas benchmark.
        _streamIdsForWithdraw[2] = lockup.createWithDurationsLD(params, segments);
        _streamIdsForWithdraw[3] = lockup.createWithDurationsLD(params, segments);
    }

    function gasCreateWithTimestampsLD(uint128 totalSegments) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time
        resetPrank({ msgSender: users.sender });

        (Lockup.CreateWithTimestamps memory params, LockupDynamic.Segment[] memory segments) =
            _createWithTimestampParamsLD(totalSegments, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockup.createWithTimestampsLD(params, segments);

        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLD` (", vm.toString(totalSegments), " segments) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        (params, segments) = _createWithTimestampParamsLD(totalSegments, ud(0));

        beforeGas = gasleft();
        lockup.createWithTimestampsLD(params, segments);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLD` (",
            vm.toString(totalSegments),
            " segments) (Broker fee not set) | ",
            gasUsed,
            " |"
        );

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function _createWithDurationParamsLD(
        uint128 totalSegments,
        UD60x18 brokerFee
    )
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
                    duration: defaults.CLIFF_DURATION()
                })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * totalSegments;

        params = defaults.createWithDurations();
        params.totalAmount = _calculateTotalAmount(depositAmount, brokerFee);
        params.broker.fee = brokerFee;
        return (params, segments_);
    }

    function _createWithTimestampParamsLD(
        uint128 totalSegments,
        UD60x18 brokerFee
    )
        private
        view
        returns (Lockup.CreateWithTimestamps memory params, LockupDynamic.Segment[] memory segments_)
    {
        segments_ = new LockupDynamic.Segment[](totalSegments);

        // Populate segments.
        for (uint256 i = 0; i < totalSegments; ++i) {
            segments_[i] = (
                LockupDynamic.Segment({
                    amount: AMOUNT_PER_SEGMENT,
                    exponent: ud2x18(0.5e18),
                    timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
                })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * totalSegments;

        params = defaults.createWithTimestamps();
        params.totalAmount = _calculateTotalAmount(depositAmount, brokerFee);
        params.timestamps.start = getBlockTimestamp();
        params.timestamps.end = segments_[totalSegments - 1].timestamp;
        params.broker.fee = brokerFee;
        return (params, segments_);
    }
}
