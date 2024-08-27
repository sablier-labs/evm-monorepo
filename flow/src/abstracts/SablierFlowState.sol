// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierFlowNFTDescriptor } from "./../interfaces/ISablierFlowNFTDescriptor.sol";
import { ISablierFlowState } from "./../interfaces/ISablierFlowState.sol";
import { Errors } from "./../libraries/Errors.sol";
import { Flow } from "./../types/DataTypes.sol";
import { Adminable } from "./Adminable.sol";

/// @title SablierFlowState
/// @notice See the documentation in {ISablierFlowState}.
abstract contract SablierFlowState is
    Adminable, // 1 inherited component
    IERC4906, // 2 inherited components
    ISablierFlowState, // 3 inherited component
    ERC721 // 6 inherited components
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlowState
    UD60x18 public constant override MAX_BROKER_FEE = UD60x18.wrap(0.1e18);

    /// @inheritdoc ISablierFlowState
    uint256 public override nextStreamId;

    /// @inheritdoc ISablierFlowState
    ISablierFlowNFTDescriptor public override nftDescriptor;

    /// @dev Sablier Flow streams mapped by unsigned integers.
    mapping(uint256 id => Flow.Stream stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(address initialAdmin, ISablierFlowNFTDescriptor initialNFTDescriptor) {
        nextStreamId = 1;
        admin = initialAdmin;
        nftDescriptor = initialNFTDescriptor;
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!_streams[streamId].isStream) {
            revert Errors.SablierFlow_Null(streamId);
        }
        _;
    }

    /// @dev Checks that `streamId` does not reference a paused stream.
    modifier notPaused(uint256 streamId) {
        if (_streams[streamId].isPaused) {
            revert Errors.SablierFlow_StreamPaused(streamId);
        }
        _;
    }

    /// @dev Checks the `msg.sender` is the stream's sender.
    modifier onlySender(uint256 streamId) {
        if (msg.sender != _streams[streamId].sender) {
            revert Errors.SablierFlow_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// @dev Emits an ERC-4906 event to trigger an update of the NFT metadata.
    modifier updateMetadata(uint256 streamId) {
        _;
        emit MetadataUpdate({ _tokenId: streamId });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlowState
    function getBalance(uint256 streamId) external view override notNull(streamId) returns (uint128 balance) {
        balance = _streams[streamId].balance;
    }

    /// @inheritdoc ISablierFlowState
    function getRatePerSecond(
        uint256 streamId
    )
        external
        view
        override
        notNull(streamId)
        returns (uint128 ratePerSecond)
    {
        ratePerSecond = _streams[streamId].ratePerSecond;
    }

    /// @inheritdoc ISablierFlowState
    function getRecipient(uint256 streamId) external view override notNull(streamId) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierFlowState
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierFlowState
    function getSnapshotDebt(
        uint256 streamId
    )
        external
        view
        override
        notNull(streamId)
        returns (uint128 snapshotDebt)
    {
        snapshotDebt = _streams[streamId].snapshotDebt;
    }

    /// @inheritdoc ISablierFlowState
    function getSnapshotTime(uint256 streamId) external view override notNull(streamId) returns (uint40 snapshotTime) {
        snapshotTime = _streams[streamId].snapshotTime;
    }

    /// @inheritdoc ISablierFlowState
    function getStream(uint256 streamId) external view override notNull(streamId) returns (Flow.Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierFlowState
    function getToken(uint256 streamId) external view override notNull(streamId) returns (IERC20 token) {
        token = _streams[streamId].token;
    }

    /// @inheritdoc ISablierFlowState
    function getTokenDecimals(
        uint256 streamId
    )
        external
        view
        override
        notNull(streamId)
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = _streams[streamId].tokenDecimals;
    }

    /// @inheritdoc ISablierFlowState
    function isPaused(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isPaused;
    }

    /// @inheritdoc ISablierFlowState
    function isStream(uint256 streamId) external view override returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierFlowState
    function isTransferable(uint256 streamId) external view override returns (bool result) {
        result = _streams[streamId].isTransferable;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override(IERC721Metadata, ERC721) returns (string memory uri) {
        // Check: the stream NFT exists.
        _requireOwned({ tokenId: streamId });

        // Generate the URI describing the stream NFT.
        uri = nftDescriptor.tokenURI({ sablierFlow: this, streamId: streamId });
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlowState
    function setNFTDescriptor(ISablierFlowNFTDescriptor newNFTDescriptor) external override onlyAdmin {
        // Effect: set the NFT descriptor.
        ISablierFlowNFTDescriptor oldNftDescriptor = nftDescriptor;
        nftDescriptor = newNFTDescriptor;

        // Log the change of the NFT descriptor.
        emit ISablierFlowState.SetNFTDescriptor({
            admin: msg.sender,
            oldNFTDescriptor: oldNftDescriptor,
            newNFTDescriptor: newNFTDescriptor
        });

        // Refresh the NFT metadata for all streams.
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: nextStreamId - 1 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `msg.sender` is the stream's recipient or an approved third party.
    /// @param streamId The stream ID for the query.
    function _isCallerStreamRecipientOrApproved(uint256 streamId) internal view returns (bool) {
        address recipient = _ownerOf(streamId);
        return msg.sender == recipient || isApprovedForAll({ owner: recipient, operator: msg.sender })
            || getApproved(streamId) == msg.sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Overrides the {ERC-721._update} function to check that the stream is transferable.
    ///
    /// @dev The transferable flag is ignored if the current owner is 0, as the update in this case is a mint and
    /// is allowed. Transfers to the zero address are not allowed, preventing accidental burns.
    ///
    /// @param to The address of the new recipient of the stream.
    /// @param streamId ID of the stream to update.
    /// @param auth Optional parameter. If the value is not zero, the overridden implementation will check that
    /// `auth` is either the recipient of the stream, or an approved third party.
    ///
    /// @return The original recipient of the `streamId` before the update.
    function _update(
        address to,
        uint256 streamId,
        address auth
    )
        internal
        override
        updateMetadata(streamId)
        returns (address)
    {
        address from = _ownerOf(streamId);

        if (from != address(0) && !_streams[streamId].isTransferable) {
            revert Errors.SablierFlowState_NotTransferable(streamId);
        }

        return super._update(to, streamId, auth);
    }
}
