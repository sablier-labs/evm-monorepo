// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockupLinear } from "../../src/core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../../src/core/interfaces/ISablierLockupTranched.sol";
import { Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../../src/core/types/DataTypes.sol";
import { ISablierMerkleInstant } from "../../src/periphery/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "../../src/periphery/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "../../src/periphery/interfaces/ISablierMerkleLT.sol";
import { MerkleBase, MerkleLL, MerkleLT } from "../../src/periphery/types/DataTypes.sol";

/// @notice Abstract contract containing all the events emitted by the protocol.
abstract contract Events {
    /*//////////////////////////////////////////////////////////////////////////
                                      ERC-721
    //////////////////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////////////////
                                      ERC-4906
    //////////////////////////////////////////////////////////////////////////*/

    event MetadataUpdate(uint256 _tokenId);

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    event TransferAdmin(address indexed oldAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////////////////
                                        CORE
    //////////////////////////////////////////////////////////////////////////*/

    event AllowToHook(address indexed admin, address recipient);

    event CancelLockupStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        IERC20 indexed asset,
        uint128 senderAmount,
        uint128 recipientAmount
    );
    event RenounceLockupStream(uint256 indexed streamId);

    event SetNFTDescriptor(
        address indexed admin, ILockupNFTDescriptor oldNFTDescriptor, ILockupNFTDescriptor newNFTDescriptor
    );

    event WithdrawFromLockupStream(uint256 indexed streamId, address indexed to, IERC20 indexed asset, uint128 amount);

    event CreateLockupDynamicStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        LockupDynamic.Segment[] segments,
        LockupDynamic.Timestamps timestamps,
        address broker
    );

    event CreateLockupLinearStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        LockupLinear.Timestamps timestamps,
        address broker
    );

    event CreateLockupTranchedStream(
        uint256 streamId,
        address funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 indexed asset,
        bool cancelable,
        bool transferable,
        LockupTranched.Tranche[] tranches,
        LockupTranched.Timestamps timestamps,
        address broker
    );

    /*//////////////////////////////////////////////////////////////////////////
                                     PERIPHERY
    //////////////////////////////////////////////////////////////////////////*/

    event Claim(uint256 index, address indexed recipient, uint128 amount);

    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId);

    event Clawback(address indexed admin, address indexed to, uint128 amount);

    event CreateMerkleInstant(
        ISablierMerkleInstant indexed merkleInstant,
        MerkleBase.ConstructorParams baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockupLinear lockupLinear,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule schedule,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    event CreateMerkleLT(
        ISablierMerkleLT indexed merkleLT,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockupTranched lockupTranched,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] tranchesWithPercentages,
        uint256 totalDuration,
        uint256 aggregateAmount,
        uint256 recipientCount
    );
}
