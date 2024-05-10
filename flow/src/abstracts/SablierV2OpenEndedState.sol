// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEndedState } from "../interfaces/ISablierV2OpenEndedState.sol";
import { OpenEnded } from "../types/DataTypes.sol";
import { Errors } from "../libraries/Errors.sol";

/// @title SablierV2OpenEndedState
/// @notice See the documentation in {ISablierV2OpenEndedState}.
abstract contract SablierV2OpenEndedState is ISablierV2OpenEndedState {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEndedState
    uint256 public override nextStreamId;

    /// @dev Sablier V2 OpenEnded streams mapped by unsigned integers.
    mapping(uint256 id => OpenEnded.Stream stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a canceled stream.
    modifier notCanceled(uint256 streamId) {
        if (_streams[streamId].isCanceled) {
            revert Errors.SablierV2OpenEnded_StreamCanceled(streamId);
        }
        _;
    }

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!_streams[streamId].isStream) {
            revert Errors.SablierV2OpenEnded_Null(streamId);
        }
        _;
    }

    /// @dev Checks the `msg.sender` is the stream's sender.
    modifier onlySender(uint256 streamId) {
        if (msg.sender != _streams[streamId].sender) {
            revert Errors.SablierV2OpenEnded_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEndedState
    function getRatePerSecond(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 ratePerSecond)
    {
        ratePerSecond = _streams[streamId].ratePerSecond;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getAsset(uint256 streamId) external view override notNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getAssetDecimals(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint8 assetDecimals)
    {
        assetDecimals = _streams[streamId].assetDecimals;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getBalance(uint256 streamId) external view override notNull(streamId) returns (uint128 balance) {
        balance = _streams[streamId].balance;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getLastTimeUpdate(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint40 lastTimeUpdate)
    {
        lastTimeUpdate = _streams[streamId].lastTimeUpdate;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getRecipient(uint256 streamId) external view override notNull(streamId) returns (address recipient) {
        recipient = _streams[streamId].recipient;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function getStream(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (OpenEnded.Stream memory stream)
    {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function isCanceled(uint256 streamId) public view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isCanceled;
    }

    /// @inheritdoc ISablierV2OpenEndedState
    function isStream(uint256 streamId) public view override returns (bool result) {
        result = _streams[streamId].isStream;
    }
}
