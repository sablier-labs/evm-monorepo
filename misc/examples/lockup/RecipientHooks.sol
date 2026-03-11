// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ISablierLockupRecipient } from "@sablier/lockup/src/interfaces/ISablierLockupRecipient.sol";

contract RecipientHooks is ISablierLockupRecipient {
    error CallerNotSablierContract(address caller, address sablierLockup);

    /// @dev The address of the lockup contract. It could be either LockupLinear, LockupDynamic or LockupTranched
    /// depending on which type of streams are supported in this hook.
    address public immutable SABLIER_LOCKUP;

    mapping(address account => uint256 amount) internal _balances;

    /// @dev Constructor will set the address of the lockup contract.
    constructor(address sablierLockup_) {
        SABLIER_LOCKUP = sablierLockup_;
    }

    // {IERC165-supportsInterface} implementation as required by `ISablierLockupRecipient` interface.
    function supportsInterface(bytes4 interfaceId) public pure override(IERC165) returns (bool) {
        return interfaceId == 0xf8ee98d3;
    }

    // This will be called by Sablier contract when a stream is canceled by the sender.
    function onSablierLockupCancel(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        view
        returns (bytes4 selector)
    {
        // Check: the caller is the lockup contract.
        if (msg.sender != SABLIER_LOCKUP) {
            revert CallerNotSablierContract(msg.sender, SABLIER_LOCKUP);
        }

        // Unstake the user's NFT.
        _unstake({ nftId: streamId });

        // Update data.
        _updateData(streamId, sender, senderAmount, recipientAmount);

        return ISablierLockupRecipient.onSablierLockupCancel.selector;
    }

    // This will be called by Sablier contract when withdraw is called on a stream.
    function onSablierLockupWithdraw(
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
        view
        returns (bytes4 selector)
    {
        // Check: the caller is the lockup contract.
        if (msg.sender != SABLIER_LOCKUP) {
            revert CallerNotSablierContract(msg.sender, SABLIER_LOCKUP);
        }

        // Transfer the withdrawn amount to the original user.
        _transfer(to, amount);

        // Update data.
        _updateData(streamId, caller, amount, 0);

        return ISablierLockupRecipient.onSablierLockupWithdraw.selector;
    }

    function _unstake(uint256 nftId) internal pure { }
    function _updateData(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        internal
        pure
    { }
    function _transfer(address to, uint128 amount) internal pure { }
}
