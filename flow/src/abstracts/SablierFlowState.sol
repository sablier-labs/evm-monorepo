// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierFlowState } from "../interfaces/ISablierFlowState.sol";
import { Flow } from "../types/DataTypes.sol";
import { Errors } from "../libraries/Errors.sol";

/// @title SablierFlowState
/// @notice See the documentation in {ISablierFlowState}.
abstract contract SablierFlowState is
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

    /// @dev Sablier Flow streams mapped by unsigned integers.
    mapping(uint256 id => Flow.Stream stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        nextStreamId = 1;
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
    function getAsset(uint256 streamId) external view override notNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierFlowState
    function getAssetDecimals(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint8 assetDecimals)
    {
        assetDecimals = _streams[streamId].assetDecimals;
    }

    /// @inheritdoc ISablierFlowState
    function getBalance(uint256 streamId) external view override notNull(streamId) returns (uint128 balance) {
        balance = _streams[streamId].balance;
    }

    /// @inheritdoc ISablierFlowState
    function getLastTimeUpdate(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint40 lastTimeUpdate)
    {
        lastTimeUpdate = _streams[streamId].lastTimeUpdate;
    }

    /// @inheritdoc ISablierFlowState
    function getRatePerSecond(uint256 streamId)
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
    function getRemainingAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 remainingAmount)
    {
        remainingAmount = _streams[streamId].remainingAmount;
    }

    /// @inheritdoc ISablierFlowState
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierFlowState
    function getStream(uint256 streamId) external view override notNull(streamId) returns (Flow.Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierFlowState
    function isPaused(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isPaused;
    }

    /// @inheritdoc ISablierFlowState
    function isStream(uint256 streamId) external view override returns (bool result) {
        result = _streams[streamId].isStream;
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
    /// @dev The transferable flag is ignored if the current owner is 0, as the update in this case is a mint and
    /// is allowed. Transfers to the zero address are not allowed, preventing accidental burns.
    ///
    /// @param to The address of the new recipient of the stream.
    /// @param streamId ID of the stream to update.
    /// @param auth Optional parameter. If the value is not zero, the overridden implementation will check that
    /// `auth` is either the recipient of the stream, or an approved third party.
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
