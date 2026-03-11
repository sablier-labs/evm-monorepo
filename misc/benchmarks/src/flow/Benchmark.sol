// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ERC20Mock } from "@sablier/evm-utils/src/mocks/erc20/ERC20Mock.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { BaseTest } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { ISablierFlow } from "@sablier/flow/src/interfaces/ISablierFlow.sol";
import { Constants } from "@sablier/flow/tests/utils/Constants.sol";
import { Users } from "@sablier/flow/tests/utils/Types.sol";

/// @notice Contract to benchmark Flow streams.
/// @dev This contract creates a Markdown file with the gas usage of each function.
contract FlowBenchmark is BaseTest, Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant USDC_DECIMALS = 6;

    string internal IMM_RESULTS_FILE = "results/flow/flow.md";

    uint256[8] internal streamIds;
    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                      CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierFlow internal flow;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        logBlue("Setting up Flow benchmarks...");

        // Fork Ethereum Mainnet at the latest block.
        setUpForkEthereum();
        logGreen("Forked Ethereum Mainnet");

        // Load deployed addresses from Ethereum mainnet.
        // See https://docs.sablier.com/guides/flow/deployments
        flow = ISablierFlow(0x7a86d3e6894f9c5B5f25FFBDAaE658CFc7569623);
        logGreen("Loaded SablierFlow contract");

        // Load USDC token.
        usdc = ERC20Mock(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        tokens.push(usdc);
        logGreen("Loaded USDC token contract");

        // Create test users and deal USDC to them.
        address[] memory spenders = new address[](1);
        spenders[0] = address(flow);
        users.recipient = createUser("recipient", spenders);
        users.sender = createUser("sender", spenders);
        logGreen("Created test users, funded USDC and approved contracts");

        setMsgSender(users.sender);

        // Create test streams.
        for (uint256 i = 0; i < 8; ++i) {
            streamIds[i] = _createAndFundStream();
        }
        logGreen("Created 7 test streams");

        // Create the file if it doesn't exist, otherwise overwrite it.
        vm.writeFile({
            path: IMM_RESULTS_FILE,
            data: string.concat(
                "With USDC as the streaming token.\n\n",
                "| Function | Stream Solvency | Gas Usage |\n",
                "| :------- | :-------------- | :-------- |\n"
            )
        });
        logBlue("Setup complete! Ready to run benchmarks.");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     BENCHMARK
    //////////////////////////////////////////////////////////////////////////*/

    function test_FlowBenchmark() external {
        logBlue("\nStarting Flow benchmarks...");

        /* -------------------------------- STREAM 1 -------------------------------- */

        instrument(
            "adjustRatePerSecond",
            "N/A",
            abi.encodeCall(flow.adjustRatePerSecond, (streamIds[1], ud21x18(RATE_PER_SECOND_U128 + 1)))
        );

        instrument(
            "create",
            "N/A",
            abi.encodeCall(
                flow.create, (users.sender, users.recipient, RATE_PER_SECOND, getBlockTimestamp(), usdc, TRANSFERABLE)
            )
        );
        instrument(
            "deposit",
            "N/A",
            abi.encodeCall(flow.deposit, (streamIds[1], DEPOSIT_AMOUNT_6D, users.sender, users.recipient))
        );

        instrument("pause", "N/A", abi.encodeCall(flow.pause, (streamIds[1])));

        /* -------------------------------- STREAM 2 -------------------------------- */

        instrument("refund", "Solvent", abi.encodeCall(flow.refund, (streamIds[2], REFUND_AMOUNT_6D)));

        /* -------------------------------- STREAM 3 -------------------------------- */

        instrument("refundMax", "Solvent", abi.encodeCall(flow.refundMax, (streamIds[3])));

        // pause in order to instrument restart.
        flow.pause(streamIds[3]);

        instrument("restart", "N/A", abi.encodeCall(flow.restart, (streamIds[3], RATE_PER_SECOND)));

        instrument("void", "Solvent", abi.encodeCall(flow.void, (streamIds[3])));

        /* -------------------------------- STREAM 4 -------------------------------- */

        // warp time to accrue uncovered debt.
        vm.warp(flow.depletionTimeOf(streamIds[4]) + 3 days);
        instrument("void", "Insolvent", abi.encodeCall(flow.void, (streamIds[4])));

        /* -------------------------------- STREAM 5 -------------------------------- */

        // withdraw from an insolvent stream.
        instrument(
            "withdraw", "Insolvent", abi.encodeCall(flow.withdraw, (streamIds[5], users.recipient, WITHDRAW_AMOUNT_6D))
        );

        /* -------------------------------- STREAM 6 -------------------------------- */

        uint128 depositAmount = uint128(flow.uncoveredDebtOf(streamIds[6])) + DEPOSIT_AMOUNT_6D;
        flow.deposit(streamIds[6], depositAmount, users.sender, users.recipient);

        // withdraw from a solvent stream.
        instrument(
            "withdraw", "Solvent", abi.encodeCall(flow.withdraw, (streamIds[6], users.recipient, WITHDRAW_AMOUNT_6D))
        );

        /* -------------------------------- STREAM 7 -------------------------------- */

        instrument("withdrawMax", "Solvent", abi.encodeCall(flow.withdrawMax, (streamIds[7], users.recipient)));

        logBlue("\nCompleted all benchmarks");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Appends a row to the benchmark results file.
    function appendRow(string memory name, string memory solvency, uint256 gasUsed) internal {
        string memory row = string.concat("| `", name, "` | ", solvency, " | ", vm.toString(gasUsed), " |");
        vm.writeLine({ path: IMM_RESULTS_FILE, data: row });
    }

    /// @dev Instrument a function call and log the gas usage to the benchmark results file.
    function instrument(string memory name, string memory solvency, bytes memory payload) internal {
        // Simulate the passage of time.
        vm.warp(getBlockTimestamp() + 2 days);

        // For `withdraw` and `withdrawMax`, include fee in the call.
        uint256 minFeeWei;
        if (Strings.equal(name, "withdraw") || Strings.equal(name, "withdrawMax")) {
            minFeeWei = flow.comptroller().calculateMinFeeWei({ protocol: ISablierComptroller.Protocol.Flow });
        }

        // Run the function and instrument the gas usage.
        logBlue(string.concat("Benchmarking: ", name));
        uint256 initialGas = gasleft();
        (bool status, bytes memory revertData) = address(flow).call{ value: minFeeWei }(payload);

        uint256 gasUsed = initialGas - gasleft();

        // If the function call reverted, load and bubble up the revert data.
        if (!status) {
            _bubbleUpRevert(revertData);
        }
        logGreen(string.concat("Gas used: ", vm.toString(gasUsed)));

        // Append the row to the benchmark results file.
        appendRow(name, solvency, gasUsed);
    }

    function _bubbleUpRevert(bytes memory revertData) private pure {
        // solhint-disable no-inline-assembly
        assembly {
            // Get the length of the result stored in the first 32 bytes.
            let resultSize := mload(revertData)

            // Forward the pointer by 32 bytes to skip the length argument, and revert with the result.
            revert(add(32, revertData), resultSize)
        }
    }

    function _createAndFundStream() private returns (uint256) {
        // Create the stream.
        uint256 streamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            startTime: getBlockTimestamp(),
            token: usdc,
            transferable: TRANSFERABLE
        });

        // Fund the stream.
        flow.deposit(streamId, DEPOSIT_AMOUNT_6D, users.sender, users.recipient);

        // Return the stream ID.
        return streamId;
    }
}
