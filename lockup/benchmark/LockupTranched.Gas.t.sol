// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Lockup, LockupTranched } from "../src/types/DataTypes.sol";

import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark Lockup streams created using Tranched model.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract Lockup_Tranched_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal _tranches = [2, 10, 100];
    uint256[] internal _streamIdsForWithdraw = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierLockup_Tranched.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat(
                "# Benchmarks for the Lockup Tranched model\n\n", "| Implementation | Gas Usage |\n", "| --- | --- |\n"
            )
        });

        vm.warp({ newTimestamp: defaults.END_TIME() });
        gasBurn();

        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        gasCancel();

        gasRenounce();

        // Create streams with different number of tranches.
        for (uint256 i; i < _tranches.length; ++i) {
            gasCreateWithDurationsLT({ totalTranches: _tranches[i] });
            gasCreateWithTimestampsLT({ totalTranches: _tranches[i] });

            gasWithdraw_ByRecipient(
                _streamIdsForWithdraw[0],
                _streamIdsForWithdraw[1],
                string.concat("(", vm.toString(_tranches[i]), " tranches)")
            );
            gasWithdraw_ByAnyone(
                _streamIdsForWithdraw[2],
                _streamIdsForWithdraw[3],
                string.concat("(", vm.toString(_tranches[i]), " tranches)")
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                        GAS BENCHMARKS FOR CREATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // The following function is used in the estimation of `MAX_COUNT`
    function computeGas_CreateWithDurationsLT(uint128 totalTranches) public returns (uint256 gasUsed) {
        (Lockup.CreateWithDurations memory params, LockupTranched.TrancheWithDuration[] memory tranches) =
            _createWithDurationParamsLT(totalTranches, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLT(params, tranches);

        gasUsed = beforeGas - gasleft();
    }

    function gasCreateWithDurationsLT(uint128 totalTranches) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        (Lockup.CreateWithDurations memory params, LockupTranched.TrancheWithDuration[] memory tranches) =
            _createWithDurationParamsLT(totalTranches, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockup.createWithDurationsLT(params, tranches);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLT` (", vm.toString(totalTranches), " tranches) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        (params, tranches) = _createWithDurationParamsLT(totalTranches, ud(0));

        beforeGas = gasleft();
        lockup.createWithDurationsLT(params, tranches);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurationsLT` (",
            vm.toString(totalTranches),
            " tranches) (Broker fee not set) | ",
            gasUsed,
            " |"
        );

        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Store the last 2 streams IDs for withdraw gas benchmark.
        _streamIdsForWithdraw[0] = lockup.nextStreamId() - 2;
        _streamIdsForWithdraw[1] = lockup.nextStreamId() - 1;

        // Create 2 more streams for withdraw gas benchmark.
        _streamIdsForWithdraw[2] = lockup.createWithDurationsLT(params, tranches);
        _streamIdsForWithdraw[3] = lockup.createWithDurationsLT(params, tranches);
    }

    function gasCreateWithTimestampsLT(uint128 totalTranches) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        (Lockup.CreateWithTimestamps memory params, LockupTranched.Tranche[] memory tranches) =
            _createWithTimestampParamsLT(totalTranches, defaults.BROKER_FEE());
        uint256 beforeGas = gasleft();
        lockup.createWithTimestampsLT(params, tranches);

        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLT` (", vm.toString(totalTranches), " tranches) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        (params, tranches) = _createWithTimestampParamsLT(totalTranches, ud(0));
        beforeGas = gasleft();
        lockup.createWithTimestampsLT(params, tranches);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestampsLT` (",
            vm.toString(totalTranches),
            " tranches) (Broker fee not set) | ",
            gasUsed,
            " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function _createWithDurationParamsLT(
        uint128 totalTranches,
        UD60x18 brokerFee
    )
        private
        view
        returns (Lockup.CreateWithDurations memory params, LockupTranched.TrancheWithDuration[] memory tranches_)
    {
        tranches_ = new LockupTranched.TrancheWithDuration[](totalTranches);

        // Populate tranches
        for (uint256 i = 0; i < totalTranches; ++i) {
            tranches_[i] = (
                LockupTranched.TrancheWithDuration({ amount: AMOUNT_PER_TRANCHE, duration: defaults.CLIFF_DURATION() })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * totalTranches;

        params = defaults.createWithDurations();
        params.broker.fee = brokerFee;
        params.totalAmount = _calculateTotalAmount(depositAmount, brokerFee);
        return (params, tranches_);
    }

    function _createWithTimestampParamsLT(
        uint128 totalTranches,
        UD60x18 brokerFee
    )
        private
        view
        returns (Lockup.CreateWithTimestamps memory params, LockupTranched.Tranche[] memory tranches_)
    {
        tranches_ = new LockupTranched.Tranche[](totalTranches);

        // Populate tranches.
        for (uint256 i = 0; i < totalTranches; ++i) {
            tranches_[i] = (
                LockupTranched.Tranche({
                    amount: AMOUNT_PER_TRANCHE,
                    timestamp: getBlockTimestamp() + uint40(defaults.CLIFF_DURATION() * (1 + i))
                })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * totalTranches;

        params = defaults.createWithTimestamps();
        params.broker.fee = brokerFee;
        params.timestamps.start = getBlockTimestamp();
        params.timestamps.end = tranches_[totalTranches - 1].timestamp;
        params.totalAmount = _calculateTotalAmount(depositAmount, brokerFee);
        return (params, tranches_);
    }
}
