// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "../../../Integration.t.sol";

contract WithdrawMaxAndTransfer_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({
            callData: abi.encodeCall(lockup.withdrawMaxAndTransfer, (defaultStreamId, users.alice))
        });
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        expectRevert_Null({ callData: abi.encodeCall(lockup.withdrawMaxAndTransfer, (nullStreamId, users.alice)) });
    }

    function test_RevertGiven_NonTransferableStream() external whenCallerRecipient whenNoDelegateCall givenNotNull {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_NotTransferable.selector, notTransferableStreamId)
        );
        lockup.withdrawMaxAndTransfer({ streamId: notTransferableStreamId, newRecipient: users.recipient });
    }

    function test_RevertGiven_BurnedNFT()
        external
        whenCallerRecipient
        whenNoDelegateCall
        givenNotNull
        givenTransferableStream
    {
        // Deplete the stream.
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Burn the NFT.
        lockup.burn({ streamId: defaultStreamId });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, defaultStreamId));
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });
    }

    function test_GivenZeroWithdrawableAmount()
        external
        whenNoDelegateCall
        givenNotNull
        givenTransferableStream
        givenNotBurnedNFT
        whenCallerRecipient
    {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // It should not expect a transfer call on token.
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (users.recipient, 0)), count: 0 });

        // It should emit {Transfer} event on NFT.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC721.Transfer({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });
    }

    function test_RevertWhen_CallerNotCurrentRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenTransferableStream
        givenNotBurnedNFT
        givenNonZeroWithdrawableAmount
    {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.eve });
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenTransferableStream
        givenNotBurnedNFT
        givenNonZeroWithdrawableAmount
    {
        // Make the operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Get the withdraw amount.
        uint128 expectedWithdrawnAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the tokens to be transferred to the Recipient.
        expectCallToTransfer({ to: users.recipient, value: expectedWithdrawnAmount });

        // It should emit {Transfer} and {WithdrawFromLockupStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: expectedWithdrawnAmount,
            token: dai
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC721.Transfer({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        // Make the max withdrawal and transfer the NFT.
        uint128 actualWithdrawnAmount =
            lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });

        // Assert that the withdrawn amount has been updated.
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the operator is the new stream recipient (and NFT owner).
        address actualRecipient = lockup.getRecipient(defaultStreamId);
        address expectedRecipient = users.alice;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }

    function test_WhenCallerCurrentRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenTransferableStream
        givenNotBurnedNFT
        givenNonZeroWithdrawableAmount
    {
        resetPrank(users.recipient);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Get the withdraw amount.
        uint128 expectedWithdrawnAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the tokens to be transferred to the Recipient.
        expectCallToTransfer({ to: users.recipient, value: expectedWithdrawnAmount });

        // It should emit {Transfer}, {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: expectedWithdrawnAmount,
            token: dai
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC721.Transfer({ from: users.recipient, to: users.alice, tokenId: defaultStreamId });

        // Make the max withdrawal and transfer the NFT.
        uint128 actualWithdrawnAmount =
            lockup.withdrawMaxAndTransfer({ streamId: defaultStreamId, newRecipient: users.alice });

        // it should update the withdrawn amount.abi
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // It should transfer the NFT.
        address actualRecipient = lockup.getRecipient(defaultStreamId);
        address expectedRecipient = users.alice;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
