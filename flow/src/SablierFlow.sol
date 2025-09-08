// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";
import { Batch } from "@sablier/evm-utils/src/Batch.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { NoDelegateCall } from "@sablier/evm-utils/src/NoDelegateCall.sol";

import { SablierFlowState } from "./abstracts/SablierFlowState.sol";
import { IFlowNFTDescriptor } from "./interfaces/IFlowNFTDescriptor.sol";
import { ISablierFlow } from "./interfaces/ISablierFlow.sol";
import { Errors } from "./libraries/Errors.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Flow } from "./types/DataTypes.sol";

/// @title SablierFlow
/// @notice See the documentation in {ISablierFlow}.
contract SablierFlow is
    Batch, // 1 inherited component
    Comptrollerable, // 1 inherited component
    ERC721, // 6 inherited components
    ISablierFlow, // 8 inherited components
    NoDelegateCall, // 0 inherited components
    SablierFlowState // 1 inherited component
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(
        address initialComptroller,
        address initialNFTDescriptor
    )
        Comptrollerable(initialComptroller)
        ERC721("Sablier Flow NFT", "SAB-FLOW")
        SablierFlowState(initialNFTDescriptor)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits an ERC-4906 event to trigger an update of the NFT metadata.
    modifier updateMetadata(uint256 streamId) {
        _;
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlow
    function calculateMinFeeWei(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint256 minFeeWei)
    {
        // Calculate the minimum fee in wei for the stream sender.
        minFeeWei = comptroller.calculateMinFeeWeiFor({
            protocol: ISablierComptroller.Protocol.Flow,
            user: _streams[streamId].sender
        });
    }

    /// @inheritdoc ISablierFlow
    function coveredDebtOf(uint256 streamId) external view override notNull(streamId) returns (uint128 coveredDebt) {
        coveredDebt = _coveredDebtOf(streamId);
    }

    /// @inheritdoc ISablierFlow
    function depletionTimeOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        notPaused(streamId)
        returns (uint256 depletionTime)
    {
        uint128 balance = _streams[streamId].balance;

        // If the stream balance is zero, revert to avoid ambiguity from a depleting stream.
        if (balance == 0) {
            revert Errors.SablierFlow_StreamBalanceZero(streamId);
        }

        uint8 tokenDecimals = _streams[streamId].tokenDecimals;
        uint256 balanceScaled = Helpers.scaleAmount({ amount: balance, decimals: tokenDecimals });
        uint256 snapshotDebtScaled = _streams[streamId].snapshotDebtScaled;

        // MVT represents Minimum Value Transferable, the smallest amount of token that can be transferred, which is
        // always 1 in token's decimal.
        uint256 oneMVTScaled = Helpers.scaleAmount({ amount: 1, decimals: tokenDecimals });

        // If the total debt exceeds balance, return zero.
        if (snapshotDebtScaled + _ongoingDebtScaledOf(streamId) >= balanceScaled + oneMVTScaled) {
            return 0;
        }

        uint256 ratePerSecond = _streams[streamId].ratePerSecond.unwrap();

        // Depletion time is defined as the UNIX timestamp at which the total debt exceeds stream balance by 1 unit of
        // token (mvt). So we calculate it by solving: total debt at depletion time = stream balance + 1. This ensures
        // that we find the lowest timestamp at which the total debt exceeds the stream balance.
        // Safe to use unchecked because the calculations cannot overflow or underflow.
        unchecked {
            uint256 solvencyAmount = balanceScaled - snapshotDebtScaled + oneMVTScaled;
            uint256 solvencyPeriod = solvencyAmount / ratePerSecond;

            // If the division is exact, return the depletion time.
            if (solvencyAmount % ratePerSecond == 0) {
                depletionTime = _streams[streamId].snapshotTime + solvencyPeriod;
            }
            // Otherwise, round up before returning since the division by rate per second has round down the result.
            else {
                depletionTime = _streams[streamId].snapshotTime + solvencyPeriod + 1;
            }
        }
    }

    /// @inheritdoc ISablierFlow
    function getRecipient(uint256 streamId) external view override notNull(streamId) returns (address recipient) {
        // Check the stream NFT exists and return the owner, which is the stream's recipient.
        recipient = _requireOwned(streamId);
    }

    /// @inheritdoc ISablierFlow
    function ongoingDebtScaledOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint256 ongoingDebtScaled)
    {
        ongoingDebtScaled = _ongoingDebtScaledOf(streamId);
    }

    /// @inheritdoc ISablierFlow
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId);
    }

    /// @inheritdoc ISablierFlow
    function statusOf(uint256 streamId) external view override notNull(streamId) returns (Flow.Status status) {
        // If the stream has not started, return PENDING.
        if (_streams[streamId].snapshotTime > block.timestamp) {
            return Flow.Status.PENDING;
        }

        // If the stream has been voided, return VOIDED.
        if (_streams[streamId].isVoided) {
            return Flow.Status.VOIDED;
        }

        // See whether the stream has uncovered debt.
        bool hasDebt = _uncoveredDebtOf(streamId) > 0;

        if (_streams[streamId].ratePerSecond.unwrap() == 0) {
            // If the stream is paused and has uncovered debt, return PAUSED_INSOLVENT.
            if (hasDebt) {
                return Flow.Status.PAUSED_INSOLVENT;
            }

            // If the stream is paused and has no uncovered debt, return PAUSED_SOLVENT.
            return Flow.Status.PAUSED_SOLVENT;
        }

        // If the stream is streaming and has uncovered debt, return STREAMING_INSOLVENT.
        if (hasDebt) {
            return Flow.Status.STREAMING_INSOLVENT;
        }

        // If the stream is streaming and has no uncovered debt, return STREAMING_SOLVENT.
        status = Flow.Status.STREAMING_SOLVENT;
    }

    /// @inheritdoc ISablierFlow
    function totalDebtOf(uint256 streamId) external view override notNull(streamId) returns (uint256 totalDebt) {
        totalDebt = _totalDebtOf(streamId);
    }

    /// @inheritdoc ISablierFlow
    function uncoveredDebtOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint256 uncoveredDebt)
    {
        uncoveredDebt = _uncoveredDebtOf(streamId);
    }

    /// @inheritdoc ISablierFlow
    function withdrawableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _coveredDebtOf(streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlow
    function adjustRatePerSecond(
        uint256 streamId,
        UD21x18 newRatePerSecond
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Check: the new rate per second is not zero.
        if (newRatePerSecond.unwrap() == 0) {
            revert Errors.SablierFlow_NewRatePerSecondZero(streamId);
        }

        UD21x18 oldRatePerSecond = _streams[streamId].ratePerSecond;

        // Checks and Effects: adjust the rate per second.
        _adjustRatePerSecond(streamId, newRatePerSecond);

        // Log the adjustment.
        emit ISablierFlow.AdjustFlowStream({
            streamId: streamId,
            totalDebt: _totalDebtOf(streamId),
            oldRatePerSecond: oldRatePerSecond,
            newRatePerSecond: newRatePerSecond
        });
    }

    /// @inheritdoc ISablierFlow
    function create(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        uint40 startTime,
        IERC20 token,
        bool transferable
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects, and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, startTime, token, transferable);
    }

    /// @inheritdoc ISablierFlow
    function createAndDeposit(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        uint40 startTime,
        IERC20 token,
        bool transferable,
        uint128 amount
    )
        external
        payable
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects, and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, startTime, token, transferable);

        // Checks, Effects, and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function deposit(
        uint256 streamId,
        uint128 amount,
        address sender,
        address recipient
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notVoided(streamId)
        updateMetadata(streamId)
    {
        // Check: the provided sender and recipient match the stream's sender and recipient.
        _verifyStreamSenderRecipient(streamId, sender, recipient);

        // Checks, Effects, and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function depositAndPause(
        uint256 streamId,
        uint128 amount
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: deposit on stream.
        _deposit(streamId, amount);

        // Checks, Effects, and Interactions: pause the stream.
        _pause(streamId);
    }

    /// @inheritdoc ISablierFlow
    function pause(uint256 streamId)
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: pause the stream.
        _pause(streamId);
    }

    /// @inheritdoc ISablierFlow
    function recover(IERC20 token, address to) external override onlyComptroller {
        uint256 surplus = token.balanceOf(address(this)) - aggregateAmount[token];

        // Check: there is a surplus to recover.
        if (surplus == 0) {
            revert Errors.SablierFlow_SurplusZero(address(token));
        }

        // Interaction: transfer the surplus to the provided address.
        token.safeTransfer(to, surplus);

        emit ISablierFlow.Recover(comptroller, token, to, surplus);
    }

    /// @inheritdoc ISablierFlow
    function refund(
        uint256 streamId,
        uint128 amount
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: make the refund.
        _refund(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function refundAndPause(
        uint256 streamId,
        uint128 amount
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: make the refund.
        _refund(streamId, amount);

        // Checks, Effects, and Interactions: pause the stream.
        _pause(streamId);
    }

    /// @inheritdoc ISablierFlow
    function refundMax(uint256 streamId)
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
        returns (uint128 refundedAmount)
    {
        refundedAmount = _refundableAmountOf(streamId);

        // Checks, Effects, and Interactions: make the refund.
        _refund(streamId, refundedAmount);
    }

    /// @inheritdoc ISablierFlow
    function restart(
        uint256 streamId,
        UD21x18 ratePerSecond
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notVoided(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: restart the stream.
        _restart(streamId, ratePerSecond);
    }

    /// @inheritdoc ISablierFlow
    function restartAndDeposit(
        uint256 streamId,
        UD21x18 ratePerSecond,
        uint128 amount
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notVoided(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: restart the stream.
        _restart(streamId, ratePerSecond);

        // Checks, Effects, and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function setNativeToken(address newNativeToken) external override onlyComptroller {
        // Check: provided token is not zero address.
        if (newNativeToken == address(0)) {
            revert Errors.SablierFlow_NativeTokenZeroAddress();
        }

        // Check: native token is not set.
        if (nativeToken != address(0)) {
            revert Errors.SablierFlow_NativeTokenAlreadySet(nativeToken);
        }

        // Effect: set the native token.
        nativeToken = newNativeToken;

        // Log the update.
        emit ISablierFlow.SetNativeToken({ comptroller: comptroller, nativeToken: newNativeToken });
    }

    /// @inheritdoc ISablierFlow
    function setNFTDescriptor(IFlowNFTDescriptor newNFTDescriptor) external override onlyComptroller {
        // Effect: set the NFT descriptor.
        IFlowNFTDescriptor oldNftDescriptor = nftDescriptor;
        nftDescriptor = newNFTDescriptor;

        // Log the change of the NFT descriptor.
        emit ISablierFlow.SetNFTDescriptor(comptroller, oldNftDescriptor, newNFTDescriptor);

        // Refresh the NFT metadata for all streams.
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: nextStreamId - 1 });
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721) returns (bool) {
        // 0x49064906 is the ERC-165 interface ID required by ERC-4906
        return interfaceId == 0x49064906 || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override(IERC721Metadata, ERC721) returns (string memory uri) {
        // Check: the stream NFT exists.
        _requireOwned({ tokenId: streamId });

        // Generate the URI describing the stream NFT.
        uri = nftDescriptor.tokenURI({ sablierFlow: this, streamId: streamId });
    }

    /// @inheritdoc ISablierFlow
    function transferTokens(IERC20 token, address to, uint128 amount) external payable {
        // Interaction: transfer the amount.
        token.safeTransferFrom({ from: msg.sender, to: to, value: amount });
    }

    /// @inheritdoc ISablierFlow
    function void(uint256 streamId)
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        notVoided(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: void the stream.
        _void(streamId);
    }

    /// @inheritdoc ISablierFlow
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects, and Interactions: make the withdrawal.
        _withdraw(streamId, to, amount);
    }

    /// @inheritdoc ISablierFlow
    function withdrawMax(
        uint256 streamId,
        address to
    )
        external
        payable
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
        returns (uint128 withdrawnAmount)
    {
        withdrawnAmount = _coveredDebtOf(streamId);

        // Checks, Effects, and Interactions: make the withdrawal.
        _withdraw(streamId, to, withdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         INTERNAL STATE-CHANGING FUNCTIONS
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
            revert Errors.SablierFlow_NotTransferable(streamId);
        }

        return super._update(to, streamId, auth);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the amount of covered debt by the stream balance.
    function _coveredDebtOf(uint256 streamId) private view returns (uint128) {
        uint128 balance = _streams[streamId].balance;

        // If the balance is zero, return zero.
        if (balance == 0) {
            return 0;
        }

        uint256 totalDebt = _totalDebtOf(streamId);

        // If the stream balance is less than or equal to the total debt, return the stream balance.
        if (balance < totalDebt) {
            return balance;
        }

        // At this point, the total debt fits within `uint128`, as it is less than or equal to the balance.
        return totalDebt.toUint128();
    }

    /// @notice Checks whether `msg.sender` is the stream's recipient or an approved third party.
    /// @param streamId The stream ID for the query.
    function _isCallerStreamRecipientOrApproved(uint256 streamId, address recipient) private view returns (bool) {
        return _isAuthorized({ owner: recipient, spender: msg.sender, tokenId: streamId });
    }

    /// @dev Calculates the ongoing debt, as a 18-decimals fixed point number, accrued since last snapshot. Return 0 if
    /// the stream is paused or `block.timestamp` is less than or equal to snapshot time.
    function _ongoingDebtScaledOf(uint256 streamId) private view returns (uint256) {
        uint256 blockTimestamp = block.timestamp;
        uint256 snapshotTime = _streams[streamId].snapshotTime;

        // If the snapshot time is in the future, return zero.
        if (snapshotTime >= blockTimestamp) {
            return 0;
        }

        uint256 ratePerSecond = _streams[streamId].ratePerSecond.unwrap();

        // Check: if the rate per second is zero, skip the calculations.
        if (ratePerSecond == 0) {
            return 0;
        }

        // Safe to use unchecked because of the check above.
        uint256 elapsedTime;
        unchecked {
            // Calculate time elapsed since the last snapshot.
            elapsedTime = blockTimestamp - snapshotTime;
        }

        // Calculate the ongoing debt scaled.
        return elapsedTime * ratePerSecond;
    }

    /// @dev Calculates the refundable amount.
    function _refundableAmountOf(uint256 streamId) private view returns (uint128) {
        return _streams[streamId].balance - _coveredDebtOf(streamId);
    }

    /// @dev The total debt is the sum of the snapshot debt and the ongoing debt descaled to token's decimal. This
    /// value is independent of the stream's balance.
    function _totalDebtOf(uint256 streamId) private view returns (uint256) {
        uint256 totalDebtScaled = _ongoingDebtScaledOf(streamId) + _streams[streamId].snapshotDebtScaled;
        return Helpers.descaleAmount({ amount: totalDebtScaled, decimals: _streams[streamId].tokenDecimals });
    }

    /// @dev Calculates the uncovered debt.
    function _uncoveredDebtOf(uint256 streamId) private view returns (uint256) {
        uint128 balance = _streams[streamId].balance;

        uint256 totalDebt = _totalDebtOf(streamId);

        if (balance < totalDebt) {
            return totalDebt - balance;
        } else {
            return 0;
        }
    }

    /// @dev Checks whether the provided addresses matches stream's sender and recipient.
    function _verifyStreamSenderRecipient(uint256 streamId, address sender, address recipient) private view {
        if (sender != _streams[streamId].sender) {
            revert Errors.SablierFlow_NotStreamSender(sender, _streams[streamId].sender);
        }

        if (recipient != _ownerOf(streamId)) {
            revert Errors.SablierFlow_NotStreamRecipient(recipient, _ownerOf(streamId));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _adjustRatePerSecond(uint256 streamId, UD21x18 newRatePerSecond) private {
        // Check: the new rate per second is different from the current rate per second.
        if (newRatePerSecond.unwrap() == _streams[streamId].ratePerSecond.unwrap()) {
            revert Errors.SablierFlow_RatePerSecondNotDifferent(streamId, newRatePerSecond);
        }

        uint40 blockTimestamp = uint40(block.timestamp);

        // Update the snapshot variables only if the snapshot time is in the past.
        if (_streams[streamId].snapshotTime < blockTimestamp) {
            uint256 ongoingDebtScaled = _ongoingDebtScaledOf(streamId);

            // Update the snapshot debt only if the stream has ongoing debt.
            if (ongoingDebtScaled > 0) {
                // Effect: update the snapshot debt.
                _streams[streamId].snapshotDebtScaled += ongoingDebtScaled;
            }

            // Effect: update the snapshot time.
            _streams[streamId].snapshotTime = blockTimestamp;
        }

        // Effect: set the new rate per second.
        _streams[streamId].ratePerSecond = newRatePerSecond;
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _create(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        uint40 startTime,
        IERC20 token,
        bool transferable
    )
        private
        returns (uint256 streamId)
    {
        // Check: the sender is not the zero address.
        if (sender == address(0)) {
            revert Errors.SablierFlow_SenderZeroAddress();
        }

        // Check: the token is not the native token.
        if (address(token) == nativeToken) {
            revert Errors.SablierFlow_CreateNativeToken(nativeToken);
        }

        uint8 tokenDecimals = IERC20Metadata(address(token)).decimals();

        // Check: the token decimals are not greater than 18.
        if (tokenDecimals > 18) {
            revert Errors.SablierFlow_InvalidTokenDecimals(address(token));
        }

        uint40 blockTimestamp = uint40(block.timestamp);

        // Check: if the start time is in the future, the rate per second is not zero.
        if (startTime > blockTimestamp && ratePerSecond.unwrap() == 0) {
            revert Errors.SablierFlow_CreateRatePerSecondZero();
        }

        // Zero is used a sentinel value for `block.timestamp`.
        uint40 snapshotTime;
        if (startTime == 0) {
            snapshotTime = blockTimestamp;
        }
        // Otherwise, set the snapshot time to the start time.
        else {
            snapshotTime = startTime;
        }

        // Load the stream ID.
        streamId = nextStreamId;

        // Effect: create the stream.
        _streams[streamId] = Flow.Stream({
            balance: 0,
            isStream: true,
            isTransferable: transferable,
            isVoided: false,
            ratePerSecond: ratePerSecond,
            sender: sender,
            snapshotDebtScaled: 0,
            snapshotTime: snapshotTime,
            token: token,
            tokenDecimals: tokenDecimals
        });

        // Effect: mint the NFT to the recipient.
        _mint({ to: recipient, tokenId: streamId });

        // Effect: bump the next stream ID.
        // Safe to use unchecked arithmetic because this calculation cannot realistically overflow.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Log the newly created stream.
        emit ISablierFlow.CreateFlowStream({
            streamId: streamId,
            creator: msg.sender,
            sender: sender,
            recipient: recipient,
            ratePerSecond: ratePerSecond,
            token: token,
            transferable: transferable,
            snapshotTime: snapshotTime
        });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _deposit(uint256 streamId, uint128 amount) private {
        // Check: the deposit amount is not zero.
        if (amount == 0) {
            revert Errors.SablierFlow_DepositAmountZero(streamId);
        }

        IERC20 token = _streams[streamId].token;

        // Effect: update the stream balance.
        _streams[streamId].balance += amount;

        unchecked {
            // Effect: update the aggregate amount.
            aggregateAmount[token] += amount;
        }

        // Interaction: transfer the amount.
        token.safeTransferFrom({ from: msg.sender, to: address(this), value: amount });

        // Log the deposit.
        emit ISablierFlow.DepositFlowStream({ streamId: streamId, funder: msg.sender, amount: amount });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _pause(uint256 streamId) private {
        // Check: the stream is not pending.
        if (_streams[streamId].snapshotTime > block.timestamp) {
            revert Errors.SablierFlow_StreamPending(streamId, _streams[streamId].snapshotTime);
        }

        // Checks and Effects: pause the stream by adjusting the rate per second to zero.
        _adjustRatePerSecond({ streamId: streamId, newRatePerSecond: ud21x18(0) });

        // Log the pause.
        emit ISablierFlow.PauseFlowStream({
            streamId: streamId,
            sender: _streams[streamId].sender,
            recipient: _ownerOf(streamId),
            totalDebt: _totalDebtOf(streamId)
        });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _refund(uint256 streamId, uint128 amount) private {
        // Check: the refund amount is not zero.
        if (amount == 0) {
            revert Errors.SablierFlow_RefundAmountZero(streamId);
        }

        // Calculate the refundable amount.
        uint128 refundableAmount = _refundableAmountOf(streamId);

        // Check: the refund amount is not greater than the refundable amount.
        if (amount > refundableAmount) {
            revert Errors.SablierFlow_RefundOverflow(streamId, amount, refundableAmount);
        }

        // Although the refundable amount should never exceed the balance, this condition is checked
        // to avoid exploits in case of a bug.
        if (refundableAmount > _streams[streamId].balance) {
            revert Errors.SablierFlow_InvalidCalculation(streamId, _streams[streamId].balance, amount);
        }

        address sender = _streams[streamId].sender;
        IERC20 token = _streams[streamId].token;

        // Safe to use unchecked because at this point, the amount cannot exceed the balance.
        unchecked {
            // Effect: update the stream balance.
            _streams[streamId].balance -= amount;

            // Effect: update the aggregate amount.
            aggregateAmount[token] -= amount;
        }

        // Interaction: perform the ERC-20 transfer.
        token.safeTransfer({ to: sender, value: amount });

        // Log the refund.
        emit ISablierFlow.RefundFromFlowStream(streamId, sender, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _restart(uint256 streamId, UD21x18 ratePerSecond) private {
        // Check: the stream is paused.
        if (_streams[streamId].ratePerSecond.unwrap() != 0) {
            revert Errors.SablierFlow_StreamNotPaused(streamId);
        }

        // Checks and Effects: restart the stream by adjusting the rate per second to a value greater than zero.
        _adjustRatePerSecond({ streamId: streamId, newRatePerSecond: ratePerSecond });

        // Log the restart.
        emit ISablierFlow.RestartFlowStream(streamId, msg.sender, ratePerSecond);
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _void(uint256 streamId) private {
        // Check: `msg.sender` is either the stream's sender, recipient or an approved third party.
        if (
            msg.sender != _streams[streamId].sender
                && !_isCallerStreamRecipientOrApproved({ streamId: streamId, recipient: _ownerOf(streamId) })
        ) {
            revert Errors.SablierFlow_Unauthorized({ streamId: streamId, caller: msg.sender });
        }

        uint256 debtToWriteOff = _uncoveredDebtOf(streamId);

        // If the stream is solvent, update the total debt normally.
        if (debtToWriteOff == 0) {
            uint256 ongoingDebtScaled = _ongoingDebtScaledOf(streamId);
            if (ongoingDebtScaled > 0) {
                // Effect: Update the snapshot debt by adding the ongoing debt.
                _streams[streamId].snapshotDebtScaled += ongoingDebtScaled;
            }
        }
        // If the stream is insolvent, write off the uncovered debt.
        else {
            // Effect: update the total debt by setting snapshot debt to the stream balance.
            _streams[streamId].snapshotDebtScaled =
                Helpers.scaleAmount({ amount: _streams[streamId].balance, decimals: _streams[streamId].tokenDecimals });
        }

        // Effect: update the snapshot time.
        _streams[streamId].snapshotTime = uint40(block.timestamp);

        // Effect: set the rate per second to zero.
        _streams[streamId].ratePerSecond = ud21x18(0);

        // Effect: set the stream as voided.
        _streams[streamId].isVoided = true;

        // Log the void.
        emit ISablierFlow.VoidFlowStream({
            streamId: streamId,
            sender: _streams[streamId].sender,
            recipient: _ownerOf(streamId),
            caller: msg.sender,
            newTotalDebt: _totalDebtOf(streamId),
            writtenOffDebt: debtToWriteOff
        });
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _withdraw(uint256 streamId, address to, uint128 amount) private {
        // Calculate the minimum fee in wei for the stream sender.
        uint256 minFeeWei = comptroller.calculateMinFeeWeiFor({
            protocol: ISablierComptroller.Protocol.Flow,
            user: _streams[streamId].sender
        });

        uint256 feePaid = msg.value;

        // Check: fee paid is at least the minimum fee.
        if (feePaid < minFeeWei) {
            revert Errors.SablierFlow_InsufficientFeePayment(feePaid, minFeeWei);
        }

        // Check: the withdraw amount is not zero.
        if (amount == 0) {
            revert Errors.SablierFlow_WithdrawAmountZero(streamId);
        }

        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierFlow_WithdrawToZeroAddress(streamId);
        }

        address recipient = _ownerOf(streamId);

        // Check: `msg.sender` is neither the stream's recipient nor an approved third party, the withdrawal address
        // must be the recipient.
        if (to != recipient && !_isCallerStreamRecipientOrApproved(streamId, recipient)) {
            revert Errors.SablierFlow_WithdrawalAddressNotRecipient({ streamId: streamId, caller: msg.sender, to: to });
        }

        uint8 tokenDecimals = _streams[streamId].tokenDecimals;

        // Calculate the total debt.
        uint256 totalDebtScaled = _ongoingDebtScaledOf(streamId) + _streams[streamId].snapshotDebtScaled;
        uint256 totalDebt = Helpers.descaleAmount(totalDebtScaled, tokenDecimals);

        // Calculate the withdrawable amount.
        uint128 balance = _streams[streamId].balance;
        uint128 withdrawableAmount;

        if (balance < totalDebt) {
            // If the stream balance is less than the total debt, the withdrawable amount is the balance.
            withdrawableAmount = balance;
        } else {
            // Otherwise, the withdrawable amount is the total debt.
            withdrawableAmount = totalDebt.toUint128();
        }

        // Check: the withdraw amount is not greater than the withdrawable amount.
        if (amount > withdrawableAmount) {
            revert Errors.SablierFlow_Overdraw(streamId, amount, withdrawableAmount);
        }

        // Calculate the amount scaled.
        uint256 amountScaled = Helpers.scaleAmount(amount, tokenDecimals);

        // Safe to use unchecked, `amount` cannot be greater than the balance or total debt at this point.
        unchecked {
            // If the amount is less than the snapshot debt, reduce it from the snapshot debt and leave the snapshot
            // time unchanged.
            if (amountScaled <= _streams[streamId].snapshotDebtScaled) {
                _streams[streamId].snapshotDebtScaled -= amountScaled;
            }
            // Else reduce the amount from the ongoing debt by setting snapshot time to `block.timestamp` and set the
            // snapshot debt to the remaining total debt.
            else {
                _streams[streamId].snapshotDebtScaled = totalDebtScaled - amountScaled;

                // Effect: update the stream time.
                _streams[streamId].snapshotTime = uint40(block.timestamp);
            }

            // Effect: update the stream balance.
            _streams[streamId].balance -= amount;
        }

        // Load the variables in memory.
        IERC20 token = _streams[streamId].token;

        unchecked {
            // Effect: update the aggregate amount.
            aggregateAmount[token] -= amount;
        }

        // Interaction: perform the ERC-20 transfer.
        token.safeTransfer({ to: to, value: amount });

        // Protocol Invariant: the difference in total debt should be equal to the difference in the stream balance.
        assert(totalDebt - _totalDebtOf(streamId) == balance - _streams[streamId].balance);

        // Log the withdrawal.
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: streamId,
            to: to,
            token: token,
            caller: msg.sender,
            withdrawAmount: amount
        });
    }
}
