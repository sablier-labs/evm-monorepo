// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { console2 } from "forge-std/console2.sol";

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Invariant_Test } from "../Lockup.t.sol";
import { FlashLoanHandler } from "../../handlers/FlashLoanHandler.t.sol";
import { LockupLinearHandler } from "../../handlers/LockupLinearHandler.t.sol";
import { LockupLinearCreateHandler } from "../../handlers/LockupLinearCreateHandler.t.sol";

/// @title Linear_Invariant_Test
/// @dev Invariants for the {SablierV2LockupLinear} contract.
contract Linear_Invariant_Test is Lockup_Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinearHandler internal linearHandler;
    LockupLinearCreateHandler internal linearCreateHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Invariant_Test.setUp();

        // Deploy the linear contract handlers.
        linearHandler = new LockupLinearHandler({
            asset_: DEFAULT_ASSET,
            linear_: linear,
            _storage_: lockupHandlerStorage
        });
        linearCreateHandler = new LockupLinearCreateHandler({
            asset_: DEFAULT_ASSET,
            linear_: linear,
            _storage_: lockupHandlerStorage
        });

        // Cast the linear contract as {SablierV2Lockup} and the linear handler as {LockupHandler}.
        lockup = linear;
        lockupHandler = linearHandler;

        // Deploy the flash loan handler by casting the linear contract as {SablierV2FlashLoan}.
        flashLoanHandler = new FlashLoanHandler({
            asset_: DEFAULT_ASSET,
            comptroller_: comptroller,
            flashLoanContract_: SablierV2FlashLoan(address(linear)),
            receiver_: goodFlashLoanReceiver
        });

        // Target the flash loan handler and the linear handlers for invariant testing.
        targetContract(address(flashLoanHandler));
        targetContract(address(linearHandler));
        targetContract(address(linearCreateHandler));

        // Exclude the linear handlers for being the `msg.sender`.
        excludeSender(address(flashLoanHandler));
        excludeSender(address(linearHandler));
        excludeSender(address(linearCreateHandler));

        // Label the linear handler.
        vm.label({ account: address(linearHandler), newLabel: "LockupLinearHandler" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    // prettier-ignore
    // solhint-disable max-line-length
    function invariant_NullStatus() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId;) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupLinear.Stream memory actualStream = linear.getStream(streamId);
            address actualRecipient = lockup.getRecipient(streamId);

            // If the stream is null, it should contain only zero values.
            if (lockup.getStatus(streamId) == Lockup.Status.NULL) {
                assertEq(actualStream.amounts.deposit, 0, "Invariant violated: stream null, deposit amount not zero");
                assertEq(actualStream.amounts.withdrawn, 0, "Invariant violated: stream null, withdrawn amount not zero");
                assertEq(address(actualStream.asset), address(0), "Invariant violated: stream null, asset not zero address");
                assertEq(actualStream.isCancelable, false, "Invariant violated: stream null, isCancelable not false");
                assertEq(actualStream.range.cliff, 0, "Invariant violated: stream null, cliff time not zero");
                assertEq(actualStream.range.end, 0, "Invariant violated: stream null, end time not zero");
                assertEq(actualStream.range.start, 0, "Invariant violated: stream null, start time not zero");
                assertEq(actualStream.sender, address(0), "Invariant violated: stream null, sender not zero address");
                assertEq(actualRecipient, address(0), "Invariant violated: stream null, recipient not zero address");
            }
            // If the stream is not null, it should contain a non-zero deposit amount.
            else {
                assertNotEq(actualStream.amounts.deposit, 0, "Invariant violated: stream non-null, deposit amount zero");
                assertNotEq(actualStream.range.end, 0, "Invariant violated: stream non-null, end time zero");
            }
            unchecked {
                i += 1;
            }
        }
    }

    function invariant_CliffTimeGteStartTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                linear.getCliffTime(streamId),
                linear.getStartTime(streamId),
                "Invariant violated: cliff time < start time"
            );
            unchecked {
                i += 1;
            }
        }
    }

    function invariant_EndTimeGtCliffTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGt(
                linear.getEndTime(streamId),
                linear.getCliffTime(streamId),
                "Invariant violated: end time < cliff time"
            );
            unchecked {
                i += 1;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CALL SUMMARY
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Mark this function as `external` to enable call summaries.
    function invariant_CallSummary() external onlyInCI {
        console2.log("\nCall Summary\n");
        console2.log("Comptroller");
        console2.log("setFlashFee          ", comptrollerHandler.calls("setFlashFee"));
        console2.log("setProtocolFee       ", comptrollerHandler.calls("setProtocolFee"));
        console2.log("toggleFlashAsset     ", comptrollerHandler.calls("toggleFlashAsset"));
        console2.log("\n  ------------------------\n");

        console2.log("FlashLoan");
        console2.log("flashLoan            ", flashLoanHandler.calls("flashLoan"));
        console2.log("\n  ------------------------\n");

        console2.log("LockupLinear");
        console2.log("burn                 ", linearHandler.calls("burn"));
        console2.log("cancel               ", linearHandler.calls("cancel"));
        console2.log("claimProtocolRevenues", linearHandler.calls("claimProtocolRevenues"));
        console2.log("createWithRange      ", linearCreateHandler.calls("createWithRange"));
        console2.log("createWithDurations  ", linearCreateHandler.calls("createWithDurations"));
        console2.log("renounce             ", linearHandler.calls("renounce"));
        console2.log("transferNFT          ", linearHandler.calls("transferNFT"));
        console2.log("withdraw             ", linearHandler.calls("withdraw"));
        console2.log("withdrawMax          ", linearHandler.calls("withdrawMax"));
        console2.log("\n  -----------------------\n");

        console2.log(
            "Total calls:         ",
            comptrollerHandler.totalCalls() + flashLoanHandler.totalCalls() + linearHandler.totalCalls()
        );
    }
}
