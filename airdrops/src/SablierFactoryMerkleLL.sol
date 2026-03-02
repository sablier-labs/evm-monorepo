// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { SablierFactoryMerkleBase } from "./abstracts/SablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleLL } from "./interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { MerkleLL } from "./types/MerkleLL.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗     ██╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║     ██║
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║     ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║     ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ███████╗███████╗
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚══════╝

*/

/// @title SablierFactoryMerkleLL
/// @notice See the documentation in {ISablierFactoryMerkleLL}.
contract SablierFactoryMerkleLL is ISablierFactoryMerkleLL, SablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) SablierFactoryMerkleBase(initialComptroller) { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleLL
    function computeMerkleLL(
        address campaignCreator,
        MerkleLL.ConstructorParams calldata campaignParams
    )
        external
        view
        override
        returns (address merkleLL)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(campaignParams.token));

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, comptroller, abi.encode(campaignParams)));

        // Get the bytecode hash for the {SablierMerkleLL} contract.
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(SablierMerkleLL).creationCode, abi.encode(campaignParams, campaignCreator, address(comptroller))
            )
        );

        // Compute CREATE2 address using `keccak256(0xff + deployer + salt + bytecodeHash)`.
        merkleLL =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleLL
    function createMerkleLL(
        MerkleLL.ConstructorParams memory campaignParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLL merkleLL)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(campaignParams.token));

        // Set the granularity to 1 second if it is provided as a zero.
        campaignParams.granularity = campaignParams.granularity == 0 ? 1 seconds : campaignParams.granularity;

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, comptroller, abi.encode(campaignParams)));

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }({
            campaignParams: campaignParams,
            campaignCreator: msg.sender,
            comptroller: address(comptroller)
        });

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL({
            merkleLL: merkleLL,
            campaignParams: campaignParams,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            comptroller: address(comptroller),
            minFeeUSD: comptroller.getMinFeeUSDFor({
                protocol: ISablierComptroller.Protocol.Airdrops,
                user: msg.sender
            })
        });
    }
}
