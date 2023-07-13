// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";

import { WithdrawMaxAndTransfer_Integration_Shared_Test } from "../../../shared/lockup/withdrawMaxAndTransfer.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract WithdrawMaxAndTransfer_Integration_Concrete_Test is
    Integration_Test,
    WithdrawMaxAndTransfer_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, WithdrawMaxAndTransfer_Integration_Shared_Test) {
        WithdrawMaxAndTransfer_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.withdrawMaxAndTransfer, (defaultStreamId, users.alice));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdrawMaxAndTransfer({ streamId: nullStreamId, newRecipient: users.recipient });
    }

    function test_RevertWhen_CallerNotCurrentRecipient() external whenNotDelegateCalled whenNotNull {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.eve });
    }

    function test_RevertWhen_NFTBurned() external whenNotDelegateCalled whenNotNull whenCallerCurrentRecipient {
        // Deplete the stream.
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Burn the NFT.
        lockup.burn({ streamId: defaultStreamId });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });
    }

    function test_WithdrawMaxAndTransfer_WithdrawableAmountZero()
        external
        whenNotDelegateCalled
        whenNotNull
        whenCallerCurrentRecipient
        whenNFTNotBurned
    {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });
    }

    function test_WithdrawMaxAndTransfer()
        external
        whenNotDelegateCalled
        whenNotNull
        whenCallerCurrentRecipient
        whenNFTNotBurned
        whenWithdrawableAmountNotZero
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Get the withdraw amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the assets to be transferred to the Recipient.
        expectCallToTransfer({ to: users.recipient, amount: withdrawAmount });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit Transfer({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        // Make the max withdrawal and transfer the NFT.
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that Alice is the new stream recipient (and NFT owner).
        address actualRecipient = lockup.getRecipient(defaultStreamId);
        address expectedRecipient = users.alice;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
