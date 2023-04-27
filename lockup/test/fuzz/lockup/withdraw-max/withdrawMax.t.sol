// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../Fuzz.t.sol";

abstract contract WithdrawMax_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        defaultStreamId = createDefaultStream();
        changePrank({ msgSender: users.recipient });
    }

    function testFuzz_WithdrawMax_EndTimeInThePast(uint256 timeWarp) external {
        timeWarp = bound(timeWarp, DEFAULT_TOTAL_DURATION + 1 seconds, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: users.recipient, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Make the max withdrawal.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the stream's status is "DEPLETED".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the NFT has not been burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    modifier whenEndTimeInTheFuture() {
        _;
    }

    function testFuzz_WithdrawMax(uint256 timeWarp) external whenEndTimeInTheFuture {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Get the withdraw amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the assets to be transferred to the recipient.
        expectTransferCall({ to: users.recipient, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Make the max withdrawal.
        lockup.withdrawMax(defaultStreamId, users.recipient);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
