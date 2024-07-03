// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Broker, LockupTranched } from "../src/types/DataTypes.sol";

import { Benchmark_Test } from "./Benchmark.t.sol";

/// @notice Tests used to benchmark LockupTranched.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract LockupTranched_Gas_Test is Benchmark_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal _tranches = [2, 10, 100];
    uint256[] internal _streamIdsForWithdraw = new uint256[](4);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        lockup = lockupTranched;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testGas_Implementations() external {
        // Set the file path.
        benchmarkResultsFile = string.concat(benchmarkResults, "SablierV2LockupTranched.md");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: benchmarkResultsFile,
            data: string.concat(
                "# Benchmarks for LockupTranched\n\n", "| Implementation | Gas Usage |\n", "| --- | --- |\n"
            )
        });

        vm.warp({ newTimestamp: defaults.END_TIME() });
        gasBurn();

        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        gasCancel();

        gasRenounce();

        // Create streams with different number of tranches.
        for (uint256 i; i < _tranches.length; ++i) {
            gasCreateWithDurations({ totalTranches: _tranches[i] });
            gasCreateWithTimestamps({ totalTranches: _tranches[i] });

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

    // The following function is used in the estimation of `MAX_TRANCHE_COUNT`
    function computeGas_CreateWithDurations(uint128 totalTranches) public returns (uint256 gasUsed) {
        LockupTranched.CreateWithDurations memory params =
            _createWithDurationParams(totalTranches, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockupTranched.createWithDurations(params);

        gasUsed = beforeGas - gasleft();
    }

    function gasCreateWithDurations(uint128 totalTranches) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        LockupTranched.CreateWithDurations memory params =
            _createWithDurationParams(totalTranches, defaults.BROKER_FEE());

        uint256 beforeGas = gasleft();
        lockupTranched.createWithDurations(params);
        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurations` (", vm.toString(totalTranches), " tranches) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Calculate gas usage without broker fee.
        params = _createWithDurationParams(totalTranches, ud(0));

        beforeGas = gasleft();
        lockupTranched.createWithDurations(params);
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithDurations` (", vm.toString(totalTranches), " tranches) (Broker fee not set) | ", gasUsed, " |"
        );

        _appendToFile(benchmarkResultsFile, contentToAppend);

        // Store the last 2 streams IDs for withdraw gas benchmark.
        _streamIdsForWithdraw[0] = lockupTranched.nextStreamId() - 2;
        _streamIdsForWithdraw[1] = lockupTranched.nextStreamId() - 1;

        // Create 2 more streams for withdraw gas benchmark.
        _streamIdsForWithdraw[2] = lockupTranched.createWithDurations(params);
        _streamIdsForWithdraw[3] = lockupTranched.createWithDurations(params);
    }

    function gasCreateWithTimestamps(uint128 totalTranches) internal {
        // Set the caller to the Sender for the next calls and change timestamp to before end time.
        resetPrank({ msgSender: users.sender });

        uint256 beforeGas = gasleft();
        lockupTranched.createWithTimestamps({ params: _createWithTimestampParams(totalTranches, defaults.BROKER_FEE()) });

        string memory gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestamps` (", vm.toString(totalTranches), " tranches) (Broker fee set) | ", gasUsed, " |"
        );

        // Append the content to the file.
        _appendToFile(benchmarkResultsFile, contentToAppend);

        beforeGas = gasleft();
        lockupTranched.createWithTimestamps({ params: _createWithTimestampParams(totalTranches, ud(0)) });
        gasUsed = vm.toString(beforeGas - gasleft());

        contentToAppend = string.concat(
            "| `createWithTimestamps` (",
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

    function _createWithDurationParams(
        uint128 totalTranches,
        UD60x18 brokerFee
    )
        private
        view
        returns (LockupTranched.CreateWithDurations memory)
    {
        LockupTranched.TrancheWithDuration[] memory tranches_ = new LockupTranched.TrancheWithDuration[](totalTranches);

        // Populate tranches
        for (uint256 i = 0; i < totalTranches; ++i) {
            tranches_[i] = (
                LockupTranched.TrancheWithDuration({ amount: AMOUNT_PER_TRANCHE, duration: defaults.CLIFF_DURATION() })
            );
        }

        uint128 depositAmount = AMOUNT_PER_SEGMENT * totalTranches;

        return LockupTranched.CreateWithDurations({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: _calculateTotalAmount(depositAmount, brokerFee),
            asset: dai,
            cancelable: true,
            transferable: true,
            tranches: tranches_,
            broker: Broker({ account: users.broker, fee: brokerFee })
        });
    }

    function _createWithTimestampParams(
        uint128 totalTranches,
        UD60x18 brokerFee
    )
        private
        view
        returns (LockupTranched.CreateWithTimestamps memory)
    {
        LockupTranched.Tranche[] memory tranches_ = new LockupTranched.Tranche[](totalTranches);

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

        return LockupTranched.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: _calculateTotalAmount(depositAmount, brokerFee),
            asset: dai,
            cancelable: true,
            transferable: true,
            startTime: getBlockTimestamp(),
            tranches: tranches_,
            broker: Broker({ account: users.broker, fee: brokerFee })
        });
    }
}
