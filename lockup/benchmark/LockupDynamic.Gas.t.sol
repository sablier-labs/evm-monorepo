// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Broker, LockupDynamic } from "../src/types/DataTypes.sol";
import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark LockupDynamic.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract LockupDynamic_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal _segments = [2, 10, 100];
    uint256[] internal _streamIdsForWithdraw = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/
    function setUp() public override {
        super.setUp();

        lockup = lockupDynamic;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierV2LockupDynamic.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat("# Benchmarks for LockupDynamic\n\n", "| Implementation | Gas Usage |\n", "| --- | --- |\n")
        });

        vm.warp({ newTimestamp: defaults.END_TIME() });
        gasBurn();

        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        gasCancel();

        gasRenounce();

        // Create streams with different number of segments.
        for (uint256 i; i < _segments.length; ++i) {
            gasCreateWithDurations({ totalSegments: _segments[i] });
            gasCreateWithTimestamps({ totalSegments: _segments[i] });

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

    // The following function is used in the estimations of `MAX_SEGMENT_COUNT`.
    function computeGas_CreateWithDurations(uint128 totalSegments) public returns (uint256 gasUsed) {
        LockupDynamic.CreateWithDurations memory params =
            _createWithDurationParams(totalSegments, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockupDynamic.createWithDurations(params);

        gasUsed = beforeGas - gasleft();
    }

    function gasCreateWithDurations(uint128 totalSegments) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        LockupDynamic.CreateWithDurations memory params =
            _createWithDurationParams(totalSegments, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockupDynamic.createWithDurations(params);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurations` (", vm.toString(totalSegments), " segments) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params = _createWithDurationParams(totalSegments, ud(0));

        beforeGas = gasleft();
        lockupDynamic.createWithDurations(params);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurations` (", vm.toString(totalSegments), " segments) (Broker fee not set) | ", gasUsed, " |"
        );

        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Store the last 2 streams IDs for withdraw gas benchmark.
        _streamIdsForWithdraw[0] = lockupDynamic.nextStreamId() - 2;
        _streamIdsForWithdraw[1] = lockupDynamic.nextStreamId() - 1;

        // Create 2 more streams for withdraw gas benchmark.
        _streamIdsForWithdraw[2] = lockupDynamic.createWithDurations(params);
        _streamIdsForWithdraw[3] = lockupDynamic.createWithDurations(params);
    }

    function gasCreateWithTimestamps(uint128 totalSegments) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time
        resetPrank({ msgSender: users.sender });

        LockupDynamic.CreateWithTimestamps memory params =
            _createWithTimestampParams(totalSegments, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockupDynamic.createWithTimestamps(params);

        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestamps` (", vm.toString(totalSegments), " segments) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the data to the file
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params = _createWithTimestampParams(totalSegments, ud(0));

        beforeGas = gasleft();
        lockupDynamic.createWithTimestamps(params);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestamps` (",
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

    function _createWithDurationParams(
        uint128 totalSegments,
        UD60x18 brokerFee
    )
        private
        view
        returns (LockupDynamic.CreateWithDurations memory)
    {
        LockupDynamic.SegmentWithDuration[] memory segments_ = new LockupDynamic.SegmentWithDuration[](totalSegments);

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

        return LockupDynamic.CreateWithDurations({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: _calculateTotalAmount(depositAmount, brokerFee),
            asset: dai,
            cancelable: true,
            transferable: true,
            segments: segments_,
            broker: Broker({ account: users.broker, fee: brokerFee })
        });
    }

    function _createWithTimestampParams(
        uint128 totalSegments,
        UD60x18 brokerFee
    )
        private
        view
        returns (LockupDynamic.CreateWithTimestamps memory)
    {
        LockupDynamic.Segment[] memory segments_ = new LockupDynamic.Segment[](totalSegments);

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

        return LockupDynamic.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: _calculateTotalAmount(depositAmount, brokerFee),
            asset: dai,
            cancelable: true,
            transferable: true,
            startTime: getBlockTimestamp(),
            segments: segments_,
            broker: Broker({ account: users.broker, fee: brokerFee })
        });
    }
}
