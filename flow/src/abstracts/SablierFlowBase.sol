// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { IFlowNFTDescriptor } from "./../interfaces/IFlowNFTDescriptor.sol";
import { ISablierFlowBase } from "./../interfaces/ISablierFlowBase.sol";
import { Errors } from "./../libraries/Errors.sol";
import { Flow } from "./../types/DataTypes.sol";
import { Adminable } from "./Adminable.sol";

/// @title SablierFlowBase
/// @notice See the documentation in {ISablierFlowBase}.
abstract contract SablierFlowBase is
    Adminable, // 1 inherited component
    ISablierFlowBase, // 5 inherited component
    ERC721 // 6 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlowBase
    UD60x18 public constant override MAX_FEE = UD60x18.wrap(0.1e18);

    /// @inheritdoc ISablierFlowBase
    mapping(IERC20 token => uint256 amount) public override aggregateBalance;

    /// @inheritdoc ISablierFlowBase
    uint256 public override nextStreamId;

    /// @inheritdoc ISablierFlowBase
    IFlowNFTDescriptor public override nftDescriptor;

    /// @inheritdoc ISablierFlowBase
    mapping(IERC20 token => UD60x18 fee) public override protocolFee;

    /// @inheritdoc ISablierFlowBase
    mapping(IERC20 token => uint128 revenue) public override protocolRevenue;

    /// @dev Sablier Flow streams mapped by unsigned integers.
    mapping(uint256 id => Flow.Stream stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(address initialAdmin, IFlowNFTDescriptor initialNFTDescriptor) {
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
        if (_streams[streamId].ratePerSecond.unwrap() == 0) {
            revert Errors.SablierFlow_StreamPaused(streamId);
        }
        _;
    }

    modifier notVoided(uint256 streamId) {
        if (_streams[streamId].isVoided) {
            revert Errors.SablierFlow_StreamVoided(streamId);
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

    /// @inheritdoc ISablierFlowBase
    function getBalance(uint256 streamId) external view override notNull(streamId) returns (uint128 balance) {
        balance = _streams[streamId].balance;
    }

    /// @inheritdoc ISablierFlowBase
    function getRatePerSecond(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (UD21x18 ratePerSecond)
    {
        ratePerSecond = _streams[streamId].ratePerSecond;
    }

    /// @inheritdoc ISablierFlowBase
    function getRecipient(uint256 streamId) external view override notNull(streamId) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierFlowBase
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierFlowBase
    function getSnapshotDebtScaled(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint256 snapshotDebtScaled)
    {
        snapshotDebtScaled = _streams[streamId].snapshotDebtScaled;
    }

    /// @inheritdoc ISablierFlowBase
    function getSnapshotTime(uint256 streamId) external view override notNull(streamId) returns (uint40 snapshotTime) {
        snapshotTime = _streams[streamId].snapshotTime;
    }

    /// @inheritdoc ISablierFlowBase
    function getStream(uint256 streamId) external view override notNull(streamId) returns (Flow.Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierFlowBase
    function getToken(uint256 streamId) external view override notNull(streamId) returns (IERC20 token) {
        token = _streams[streamId].token;
    }

    /// @inheritdoc ISablierFlowBase
    function getTokenDecimals(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = _streams[streamId].tokenDecimals;
    }

    /// @inheritdoc ISablierFlowBase
    function isPaused(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].ratePerSecond.unwrap() == 0;
    }

    /// @inheritdoc ISablierFlowBase
    function isStream(uint256 streamId) external view override returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierFlowBase
    function isTransferable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isTransferable;
    }

    /// @inheritdoc ISablierFlowBase
    function isVoided(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isVoided;
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

    /// @inheritdoc ISablierFlowBase
    function collectProtocolRevenue(IERC20 token, address to) external override onlyAdmin {
        uint128 revenue = protocolRevenue[token];

        // Check: there is protocol revenue to collect.
        if (revenue == 0) {
            revert Errors.SablierFlowBase_NoProtocolRevenue(address(token));
        }

        // Effect: reset the protocol revenue.
        protocolRevenue[token] = 0;

        unchecked {
            // Effect: update the aggregate balance.
            aggregateBalance[token] -= revenue;
        }

        // Interaction: transfer the protocol revenue to the provided address.
        token.safeTransfer({ to: to, value: revenue });

        emit ISablierFlowBase.CollectProtocolRevenue({ admin: msg.sender, token: token, to: to, revenue: revenue });
    }

    /// @inheritdoc ISablierFlowBase
    function recover(IERC20 token, address to) external override onlyAdmin {
        uint256 surplus = token.balanceOf(address(this)) - aggregateBalance[token];

        // Check: there is a surplus to recover.
        if (surplus == 0) {
            revert Errors.SablierFlowBase_SurplusZero(address(token));
        }

        // Interaction: transfer the surplus to the provided address.
        token.safeTransfer(to, surplus);

        emit Recover(msg.sender, token, to, surplus);
    }

    /// @inheritdoc ISablierFlowBase
    function setNFTDescriptor(IFlowNFTDescriptor newNFTDescriptor) external override onlyAdmin {
        // Effect: set the NFT descriptor.
        IFlowNFTDescriptor oldNftDescriptor = nftDescriptor;
        nftDescriptor = newNFTDescriptor;

        // Log the change of the NFT descriptor.
        emit ISablierFlowBase.SetNFTDescriptor({
            admin: msg.sender,
            oldNFTDescriptor: oldNftDescriptor,
            newNFTDescriptor: newNFTDescriptor
        });

        // Refresh the NFT metadata for all streams.
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: nextStreamId - 1 });
    }

    /// @inheritdoc ISablierFlowBase
    function setProtocolFee(IERC20 token, UD60x18 newProtocolFee) external override onlyAdmin {
        // Check: the new protocol fee is not greater than the maximum allowed.
        if (newProtocolFee > MAX_FEE) {
            revert Errors.SablierFlowBase_ProtocolFeeTooHigh(newProtocolFee, MAX_FEE);
        }

        UD60x18 oldProtocolFee = protocolFee[token];

        // Effects: set the new protocol fee.
        protocolFee[token] = newProtocolFee;

        // Log the change of the protocol fee.
        emit ISablierFlowBase.SetProtocolFee({
            admin: msg.sender,
            token: token,
            oldProtocolFee: oldProtocolFee,
            newProtocolFee: newProtocolFee
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
            revert Errors.SablierFlowBase_NotTransferable(streamId);
        }

        return super._update(to, streamId, auth);
    }
}
