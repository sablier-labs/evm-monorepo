// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC165, ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { ISablierLockupRecipient } from "../../src/interfaces/ISablierLockupRecipient.sol";
import { ISablierV2Lockup } from "../../src/interfaces/ISablierV2Lockup.sol";

contract RecipientGood is ISablierLockupRecipient, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ISablierLockupRecipient).interfaceId;
    }

    function onSablierLockupCancel(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        pure
        override
        returns (bytes4)
    {
        streamId;
        sender;
        senderAmount;
        recipientAmount;

        return ISablierLockupRecipient.onSablierLockupCancel.selector;
    }

    function onSablierLockupWithdraw(
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
        pure
        override
        returns (bytes4)
    {
        streamId;
        caller;
        to;
        amount;

        return ISablierLockupRecipient.onSablierLockupWithdraw.selector;
    }
}

contract RecipientInterfaceIDIncorrect is ISablierLockupRecipient, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == 0xffffffff;
    }

    function onSablierLockupCancel(uint256, address, uint128, uint128) external pure override returns (bytes4) {
        return ISablierLockupRecipient.onSablierLockupCancel.selector;
    }

    function onSablierLockupWithdraw(uint256, address, address, uint128) external pure override returns (bytes4) {
        return ISablierLockupRecipient.onSablierLockupWithdraw.selector;
    }
}

contract RecipientInterfaceIDMissing {
    function onSablierLockupCancel(uint256, address, uint128, uint128) external pure returns (bytes4) {
        return ISablierLockupRecipient.onSablierLockupCancel.selector;
    }

    function onSablierLockupWithdraw(uint256, address, address, uint128) external pure returns (bytes4) {
        return ISablierLockupRecipient.onSablierLockupWithdraw.selector;
    }
}

contract RecipientInvalidSelector is ISablierLockupRecipient, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ISablierLockupRecipient).interfaceId;
    }

    function onSablierLockupCancel(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        pure
        override
        returns (bytes4)
    {
        streamId;
        sender;
        senderAmount;
        recipientAmount;

        return 0x10000000;
    }

    function onSablierLockupWithdraw(
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
        pure
        override
        returns (bytes4)
    {
        streamId;
        caller;
        to;
        amount;

        return 0x12345678;
    }
}

contract RecipientReentrant is ISablierLockupRecipient, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ISablierLockupRecipient).interfaceId;
    }

    function onSablierLockupCancel(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        override
        returns (bytes4)
    {
        streamId;
        sender;
        senderAmount;
        recipientAmount;

        ISablierV2Lockup(msg.sender).withdraw(streamId, address(this), recipientAmount);

        return ISablierLockupRecipient.onSablierLockupCancel.selector;
    }

    function onSablierLockupWithdraw(
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
        override
        returns (bytes4)
    {
        streamId;
        caller;
        to;
        amount;

        ISablierV2Lockup(msg.sender).withdraw(streamId, address(this), amount);

        return ISablierLockupRecipient.onSablierLockupWithdraw.selector;
    }
}

contract RecipientReverting is ISablierLockupRecipient, ERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ISablierLockupRecipient).interfaceId;
    }

    function onSablierLockupCancel(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external
        pure
        override
        returns (bytes4)
    {
        streamId;
        sender;
        senderAmount;
        recipientAmount;
        revert("You shall not pass");
    }

    function onSablierLockupWithdraw(
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    )
        external
        pure
        override
        returns (bytes4)
    {
        streamId;
        caller;
        to;
        amount;
        revert("You shall not pass");
    }
}
