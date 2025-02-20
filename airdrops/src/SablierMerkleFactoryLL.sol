// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { SablierMerkleFactoryBase } from "./abstracts/SablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryLL } from "./interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { MerkleLL } from "./types/DataTypes.sol";

/// @title SablierMerkleFactoryLL
/// @notice See the documentation in {ISablierMerkleFactoryLL}.
contract SablierMerkleFactoryLL is ISablierMerkleFactoryLL, SablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinimumFee The initial minimum fee charged for claiming an airdrop.
    constructor(
        address initialAdmin,
        uint256 initialMinimumFee
    )
        SablierMerkleFactoryBase(initialAdmin, initialMinimumFee)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                                NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryLL
    function createMerkleLL(
        MerkleLL.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLL merkleLL)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL({
            merkleLL: merkleLL,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
    }
}
