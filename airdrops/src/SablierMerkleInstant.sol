// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { SablierMerkleSignature } from "./abstracts/SablierMerkleSignature.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { ClaimType, MerkleBase } from "./types/MerkleBase.sol";
import { MerkleInstant } from "./types/MerkleInstant.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝

*/

/// @title SablierMerkleInstant
/// @notice See the documentation in {ISablierMerkleInstant}.
contract SablierMerkleInstant is
    ISablierMerkleInstant, // 3 inherited components
    SablierMerkleSignature // 5 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleInstant.ConstructorParams memory campaignParams,
        address campaignCreator,
        address comptroller
    )
        SablierMerkleBase(MerkleBase.ConstructorParams({
                campaignCreator: campaignCreator,
                campaignName: campaignParams.campaignName,
                campaignStartTime: campaignParams.campaignStartTime,
                claimType: campaignParams.claimType,
                comptroller: comptroller,
                expiration: campaignParams.expiration,
                initialAdmin: campaignParams.initialAdmin,
                ipfsCID: campaignParams.ipfsCID,
                merkleRoot: campaignParams.merkleRoot,
                token: campaignParams.token
            }))
    { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleInstant
    function claim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
        revertIfNot(ClaimType.DEFAULT)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: recipient, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimTo(
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
        revertIfNot(ClaimType.DEFAULT)
        notZeroAddress(to)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimViaAttestation(
        uint256 index,
        address to,
        uint128 amount,
        uint40 expireAt,
        bytes32[] calldata merkleProof,
        bytes calldata attestation
    )
        external
        payable
        override
        revertIfNot(ClaimType.ATTEST)
        notZeroAddress(to)
    {
        // Check: the attestation signature is valid and the recovered signer matches the attestor.
        _verifyAttestationSignature(msg.sender, expireAt, attestation);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleInstant
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable
        override
        revertIfNot(ClaimType.DEFAULT)
        notZeroAddress(to)
    {
        // Check: the signature is valid and the recovered signer matches the recipient.
        _verifyClaimSignature(index, recipient, to, amount, validFrom, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: to, amount: amount, viaSig: true });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by handling the tokens transfer and emitting an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 amount, bool viaSig) private {
        // Interaction: withdraw the tokens to the `to` address.
        TOKEN.safeTransfer(to, amount);

        // Emit claim event.
        emit ClaimInstant(index, recipient, amount, to, viaSig);
    }
}
