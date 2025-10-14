// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { SablierFactoryMerkleBase } from "./abstracts/SablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleInstant } from "./interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { SablierMerkleInstant } from "./SablierMerkleInstant.sol";
import { MerkleInstant } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝

*/

/// @title SablierFactoryMerkleInstant
/// @notice See the documentation in {ISablierFactoryMerkleInstant}.
contract SablierFactoryMerkleInstant is ISablierFactoryMerkleInstant, SablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) SablierFactoryMerkleBase(initialComptroller) { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleInstant
    function computeMerkleInstant(
        address campaignCreator,
        MerkleInstant.ConstructorParams calldata params
    )
        external
        view
        override
        returns (address merkleInstant)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(params.token));

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, comptroller, abi.encode(params)));

        // Get the bytecode hash for the {SablierMerkleInstant} contract.
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(SablierMerkleInstant).creationCode, abi.encode(params, campaignCreator, address(comptroller))
            )
        );

        // Compute CREATE2 address using `keccak256(0xff + deployer + salt + bytecodeHash)`.
        merkleInstant =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleInstant
    function createMerkleInstant(
        MerkleInstant.ConstructorParams calldata params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleInstant merkleInstant)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(params.token));

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, comptroller, abi.encode(params)));

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }({
            params: params,
            campaignCreator: msg.sender,
            comptroller: address(comptroller)
        });

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant({
            merkleInstant: merkleInstant,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            comptroller: address(comptroller),
            minFeeUSD: comptroller.getMinFeeUSDFor({ protocol: ISablierComptroller.Protocol.Airdrops, user: msg.sender })
        });
    }
}
