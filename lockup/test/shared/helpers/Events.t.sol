// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { Lockup, LockupLinear, LockupPro } from "src/types/DataTypes.sol";

/// @title Events
/// @notice Abstract contract with all the events emitted by the protocol.
abstract contract Events {
    /*//////////////////////////////////////////////////////////////////////////
                                SABLIER-V2-ADMINABLE
    //////////////////////////////////////////////////////////////////////////*/

    event TransferAdmin(address indexed oldAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////////////////
                                     SABLIER-V2-CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    event ClaimProtocolRevenues(address indexed admin, IERC20 indexed asset, uint128 protocolRevenues);

    event SetComptroller(
        address indexed admin,
        ISablierV2Comptroller oldComptroller,
        ISablierV2Comptroller newComptroller
    );

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-COMPTROLLER
    //////////////////////////////////////////////////////////////////////////*/

    event SetFlashFee(address indexed admin, UD60x18 oldFlashFee, UD60x18 newFlashFee);

    event SetProtocolFee(address indexed admin, IERC20 indexed asset, UD60x18 oldProtocolFee, UD60x18 newProtocolFee);

    event ToggleFlashAsset(address indexed admin, IERC20 indexed asset, bool newFlag);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    event FlashLoan(
        address indexed initiator,
        IERC3156FlashBorrower indexed receiver,
        IERC20 indexed asset,
        uint256 amount,
        uint256 feeAmount,
        bytes data
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    event CancelLockupStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    );

    event CreateLockupLinearStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 asset,
        bool cancelable,
        LockupLinear.Range range,
        address broker
    );

    event CreateLockupProStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 asset,
        bool cancelable,
        LockupPro.Segment[] segments,
        LockupPro.Range range,
        address broker
    );

    event RenounceLockupStream(uint256 indexed streamId);

    event WithdrawFromLockupStream(uint256 indexed streamId, address indexed to, uint128 amount);
}
