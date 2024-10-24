// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { MerkleBase } from "./types/DataTypes.sol";

/// @title SablierMerkleInstant
/// @notice See the documentation in {ISablierMerkleInstant}.
contract SablierMerkleInstant is
    ISablierMerkleInstant, // 2 inherited components
    SablierMerkleBase // 4 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleBase.ConstructorParams memory baseParams,
        uint256 sablierFee
    )
        SablierMerkleBase(baseParams, sablierFee)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        // Interaction: withdraw the assets to the recipient.
        ASSET.safeTransfer(recipient, amount);

        // Log the claim.
        emit Claim(index, recipient, amount);
    }
}
