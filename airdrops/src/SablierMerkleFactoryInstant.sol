// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { SablierMerkleFactoryBase } from "./abstracts/SablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryInstant } from "./interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { SablierMerkleInstant } from "./SablierMerkleInstant.sol";
import { MerkleInstant } from "./types/DataTypes.sol";

/// @title SablierMerkleFactoryInstant
/// @notice See the documentation in {ISablierMerkleFactoryInstant}.
contract SablierMerkleFactoryInstant is ISablierMerkleFactoryInstant, SablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinimumFee The initial minimum fee charged for claiming an airdrop.
    /// @param initialOracle The initial oracle contract address.
    constructor(
        address initialAdmin,
        uint256 initialMinimumFee,
        address initialOracle
    )
        SablierMerkleFactoryBase(initialAdmin, initialMinimumFee, initialOracle)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                                NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryInstant
    function createMerkleInstant(
        MerkleInstant.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleInstant merkleInstant)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant({
            merkleInstant: merkleInstant,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender),
            oracle: oracle
        });
    }
}
