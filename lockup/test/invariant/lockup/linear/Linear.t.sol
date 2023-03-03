// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

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
            store_: lockupHandlerStorage
        });
        linearCreateHandler = new LockupLinearCreateHandler({
            asset_: DEFAULT_ASSET,
            linear_: linear,
            store_: lockupHandlerStorage
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

        // Exclude the linear handlers from being the `msg.sender`.
        excludeSender(address(flashLoanHandler));
        excludeSender(address(linearHandler));
        excludeSender(address(linearCreateHandler));

        // Label the handlers.
        vm.label({ account: address(linearHandler), newLabel: "LockupLinearHandler" });
        vm.label({ account: address(linearCreateHandler), newLabel: "LockupLinearProHandler" });
        vm.label({ account: address(flashLoanHandler), newLabel: "FlashLoanHandler" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    // prettier-ignore
    // solhint-disable max-line-length
    function invariant_NullStatus() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupLinear.Stream memory actualStream = linear.getStream(streamId);
            address actualRecipient = lockup.getRecipient(streamId);

            // If the stream is null, it should contain only zero values.
            if (lockup.getStatus(streamId) == Lockup.Status.NULL) {
                assertEq(actualStream.amounts.deposit, 0, "Invariant violated: stream null, deposit amount not zero");
                assertEq(actualStream.amounts.withdrawn, 0, "Invariant violated: stream null, withdrawn amount not zero");
                assertEq(address(actualStream.asset), address(0), "Invariant violated: stream null, asset not zero address");
                assertEq(actualStream.cliffTime, 0, "Invariant violated: stream null, cliff time not zero");
                assertEq(actualStream.endTime, 0, "Invariant violated: stream null, end time not zero");
                assertEq(actualStream.isCancelable, false, "Invariant violated: stream null, isCancelable not false");
                assertEq(actualStream.sender, address(0), "Invariant violated: stream null, sender not zero address");
                assertEq(actualStream.startTime, 0, "Invariant violated: stream null, start time not zero");
                assertEq(actualRecipient, address(0), "Invariant violated: stream null, recipient not zero address");
            }
            // If the stream is not null, it should contain a non-zero deposit amount.
            else {
                assertNotEq(actualStream.amounts.deposit, 0, "Invariant violated: stream non-null, deposit amount zero");
                assertNotEq(actualStream.endTime, 0, "Invariant violated: stream non-null, end time zero");
            }
        }
    }

    function invariant_CliffTimeGteStartTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                linear.getCliffTime(streamId),
                linear.getStartTime(streamId),
                "Invariant violated: cliff time < start time"
            );
        }
    }

    function invariant_EndTimeGtCliffTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGt(
                linear.getEndTime(streamId),
                linear.getCliffTime(streamId),
                "Invariant violated: end time < cliff time"
            );
        }
    }
}
