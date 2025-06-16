// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILockupNFTDescriptor } from "../interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockupState } from "../interfaces/ISablierLockupState.sol";
import { Errors } from "../libraries/Errors.sol";
import { Lockup } from "../types/Lockup.sol";
import { LockupDynamic } from "../types/LockupDynamic.sol";
import { LockupLinear } from "../types/LockupLinear.sol";
import { LockupTranched } from "../types/LockupTranched.sol";

/// @title SablierLockupState
/// @notice See the documentation in {ISablierLockupState}.
abstract contract SablierLockupState is ISablierLockupState {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupState
    mapping(IERC20 token => uint256 amount) public override aggregateAmount;

    /// @inheritdoc ISablierLockupState
    address public override nativeToken;

    /// @inheritdoc ISablierLockupState
    uint256 public override nextStreamId;

    /// @inheritdoc ISablierLockupState
    ILockupNFTDescriptor public override nftDescriptor;

    /// @dev Mapping of contracts allowed to hook to Sablier when a stream is canceled or when tokens are withdrawn.
    mapping(address recipient => bool allowed) internal _allowedToHook;

    /// @dev Cliff timestamp mapped by stream IDs, used in LL streams.
    mapping(uint256 streamId => uint40 cliffTime) internal _cliffs;

    /// @dev Stream segments mapped by stream IDs, used in LD streams.
    mapping(uint256 streamId => LockupDynamic.Segment[] segments) internal _segments;

    /// @dev Lockup streams mapped by unsigned integers.
    mapping(uint256 id => Lockup.Stream stream) internal _streams;

    /// @dev Stream tranches mapped by stream IDs, used in LT streams.
    mapping(uint256 streamId => LockupTranched.Tranche[] tranches) internal _tranches;

    /// @dev Unlock amounts mapped by stream IDs, used in LL streams.
    mapping(uint256 streamId => LockupLinear.UnlockAmounts unlockAmounts) internal _unlockAmounts;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        _notNull(streamId);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(address initialNFTDescriptor) {
        // Set the next stream to 1.
        nextStreamId = 1;

        // Set the NFT Descriptor.
        nftDescriptor = ILockupNFTDescriptor(initialNFTDescriptor);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLockupState
    function getCliffTime(uint256 streamId) external view override notNull(streamId) returns (uint40 cliffTime) {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_LINEAR) {
            revert Errors.SablierLockupState_NotExpectedModel(
                _streams[streamId].lockupModel, Lockup.Model.LOCKUP_LINEAR
            );
        }

        cliffTime = _cliffs[streamId];
    }

    /// @inheritdoc ISablierLockupState
    function getDepositedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 depositedAmount)
    {
        depositedAmount = _streams[streamId].amounts.deposited;
    }

    /// @inheritdoc ISablierLockupState
    function getEndTime(uint256 streamId) external view override notNull(streamId) returns (uint40 endTime) {
        endTime = _streams[streamId].endTime;
    }

    /// @inheritdoc ISablierLockupState
    function getLockupModel(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (Lockup.Model lockupModel)
    {
        lockupModel = _streams[streamId].lockupModel;
    }

    /// @inheritdoc ISablierLockupState
    function getRefundedAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundedAmount)
    {
        refundedAmount = _streams[streamId].amounts.refunded;
    }

    /// @inheritdoc ISablierLockupState
    function getSegments(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupDynamic.Segment[] memory segments)
    {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_DYNAMIC) {
            revert Errors.SablierLockupState_NotExpectedModel(
                _streams[streamId].lockupModel, Lockup.Model.LOCKUP_DYNAMIC
            );
        }

        segments = _segments[streamId];
    }

    /// @inheritdoc ISablierLockupState
    function getSender(uint256 streamId) external view override notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierLockupState
    function getStartTime(uint256 streamId) external view override notNull(streamId) returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierLockupState
    function getTranches(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupTranched.Tranche[] memory tranches)
    {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_TRANCHED) {
            revert Errors.SablierLockupState_NotExpectedModel(
                _streams[streamId].lockupModel, Lockup.Model.LOCKUP_TRANCHED
            );
        }

        tranches = _tranches[streamId];
    }

    /// @inheritdoc ISablierLockupState
    function getUnderlyingToken(uint256 streamId) external view override notNull(streamId) returns (IERC20 token) {
        token = _streams[streamId].token;
    }

    /// @inheritdoc ISablierLockupState
    function getUnlockAmounts(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupLinear.UnlockAmounts memory unlockAmounts)
    {
        if (_streams[streamId].lockupModel != Lockup.Model.LOCKUP_LINEAR) {
            revert Errors.SablierLockupState_NotExpectedModel(
                _streams[streamId].lockupModel, Lockup.Model.LOCKUP_LINEAR
            );
        }

        unlockAmounts = _unlockAmounts[streamId];
    }

    /// @inheritdoc ISablierLockupState
    function getWithdrawnAmount(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawnAmount)
    {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierLockupState
    function isAllowedToHook(address recipient) external view returns (bool result) {
        result = _allowedToHook[recipient];
    }

    /// @inheritdoc ISablierLockupState
    function isCancelable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        if (_statusOf(streamId) != Lockup.Status.SETTLED) {
            result = _streams[streamId].isCancelable;
        }
    }

    /// @inheritdoc ISablierLockupState
    function isDepleted(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isDepleted;
    }

    /// @inheritdoc ISablierLockupState
    function isStream(uint256 streamId) external view override returns (bool result) {
        // Since {Helpers._checkCreateStream} reverts if the sender address is zero, this can be used to check whether
        // the stream exists.
        result = _streams[streamId].sender != address(0);
    }

    /// @inheritdoc ISablierLockupState
    function isTransferable(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].isTransferable;
    }

    /// @inheritdoc ISablierLockupState
    function wasCanceled(uint256 streamId) external view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].wasCanceled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the stream's status without performing a null check.
    function _statusOf(uint256 streamId) internal view returns (Lockup.Status) {
        if (_streams[streamId].isDepleted) {
            return Lockup.Status.DEPLETED;
        } else if (_streams[streamId].wasCanceled) {
            return Lockup.Status.CANCELED;
        }

        if (block.timestamp < _streams[streamId].startTime) {
            return Lockup.Status.PENDING;
        }

        if (_streamedAmountOf(streamId) < _streams[streamId].amounts.deposited) {
            return Lockup.Status.STREAMING;
        } else {
            return Lockup.Status.SETTLED;
        }
    }

    /// @notice Calculates the streamed amount of the stream.
    /// @dev This function is implemented by child contract. The logic varies according to the distribution model.
    function _streamedAmountOf(uint256 streamId) internal view virtual returns (uint128);

    /*//////////////////////////////////////////////////////////////////////////
                         INTERNAL STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice This function is implemented by {SablierLockup} and is used in the {SablierLockupDynamic},
    /// {SablierLockupLinear} and {SablierLockupTranched} contracts.
    /// @dev It updates state variables based on the stream parameters, mints an NFT to the recipient, bumps stream ID,
    /// and transfers the deposit amount.
    function _create(
        bool cancelable,
        uint128 depositAmount,
        Lockup.Model lockupModel,
        address recipient,
        address sender,
        uint256 streamId,
        Lockup.Timestamps memory timestamps,
        IERC20 token,
        bool transferable
    )
        internal
        virtual
    { }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A private function is used instead of inlining this logic in a modifier because Solidity copies modifiers
    /// into every function that uses them.
    function _notNull(uint256 streamId) private view {
        // Since {Helpers._checkCreateStream} reverts if the sender address is zero, this can be used to check whether
        // the stream exists.
        if (_streams[streamId].sender == address(0)) {
            revert Errors.SablierLockupState_Null(streamId);
        }
    }
}
