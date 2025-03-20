// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { SablierMerkleFactoryBase } from "./abstracts/SablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryVCA } from "./interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { SablierMerkleVCA } from "./SablierMerkleVCA.sol";
import { MerkleVCA } from "./types/DataTypes.sol";

/// @title SablierMerkleFactoryVCA
/// @notice See the documentation in {ISablierMerkleFactoryVCA}.
contract SablierMerkleFactoryVCA is ISablierMerkleFactoryVCA, SablierMerkleFactoryBase {
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

    /// @inheritdoc ISablierMerkleFactoryVCA
    function createMerkleVCA(
        MerkleVCA.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleVCA merkleVCA)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(params.token));

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleVCA contract with CREATE2.
        merkleVCA = new SablierMerkleVCA{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleVCA contract, including some metadata that is not stored on-chain.
        emit CreateMerkleVCA({
            merkleVCA: merkleVCA,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender),
            oracle: oracle
        });
    }
}
