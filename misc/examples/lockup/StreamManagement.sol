// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

/// @notice Examples of how to manage Sablier streams after they have been created.
/// @dev This code is referenced in the docs: https://docs.sablier.com/guides/lockup/examples/stream-management/setup
contract StreamManagement {
    ISablierLockup public immutable sablier;

    constructor(ISablierLockup sablier_) {
        sablier = sablier_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    02-WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    // This function can be called by the sender, recipient, or an approved NFT operator
    function withdraw(uint256 streamId) external payable {
        uint256 fee = sablier.calculateMinFeeWei(streamId);
        sablier.withdraw{ value: fee }({ streamId: streamId, to: address(0xCAFE), amount: 1337e18 });
    }

    // This function can be called by the sender, recipient, or an approved NFT operator
    function withdrawMax(uint256 streamId) external payable {
        uint256 fee = sablier.calculateMinFeeWei(streamId);
        sablier.withdrawMax{ value: fee }({ streamId: streamId, to: address(0xCAFE) });
    }

    // This function can be called by either the recipient or an approved NFT operator
    function withdrawMultiple(uint256[] calldata streamIds, uint128[] calldata amounts) external payable {
        uint256 maxFeeRequired;

        // The fee required to call withdraw multiple is the maximum of the fees required to withdraw each stream.
        for (uint256 i = 0; i < streamIds.length; i++) {
            uint256 feeForStreamId = sablier.calculateMinFeeWei(streamIds[i]);
            if (feeForStreamId > maxFeeRequired) {
                maxFeeRequired = feeForStreamId;
            }
        }

        sablier.withdrawMultiple{ value: maxFeeRequired }({ streamIds: streamIds, amounts: amounts });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     03-CANCEL
    //////////////////////////////////////////////////////////////////////////*/

    // This function can be called only by the sender
    function cancel(uint256 streamId) external {
        sablier.cancel(streamId);
    }

    // This function can be called only by the sender
    function cancelMultiple(uint256[] calldata streamIds) external {
        sablier.cancelMultiple(streamIds);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    04-RENOUNCE
    //////////////////////////////////////////////////////////////////////////*/

    // This function can be called only by the sender
    function renounce(uint256 streamId) external {
        sablier.renounce(streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    05-TRANSFER
    //////////////////////////////////////////////////////////////////////////*/

    // This function can be called by either the recipient or an approved NFT operator
    function safeTransferFrom(uint256 streamId) external {
        sablier.safeTransferFrom({ from: address(this), to: address(0xCAFE), tokenId: streamId });
    }

    // This function can be called by either the recipient or an approved NFT operator
    function transferFrom(uint256 streamId) external {
        sablier.transferFrom({ from: address(this), to: address(0xCAFE), tokenId: streamId });
    }

    // This function can be called only by the recipient
    function withdrawMaxAndTransfer(uint256 streamId) external payable {
        // Calculate the minimum fee to withdraw the amount.
        uint256 fee = sablier.calculateMinFeeWei(streamId);

        sablier.withdrawMaxAndTransfer{ value: fee }({ streamId: streamId, newRecipient: address(0xCAFE) });
    }
}
