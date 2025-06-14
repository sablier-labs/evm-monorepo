// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { SablierFactoryMerkleBase } from "./abstracts/SablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleLL } from "./interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { MerkleLL } from "./types/DataTypes.sol";

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
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleLL
    function createMerkleLL(
        MerkleLL.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLL merkleLL)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(params.token));

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, comptroller, abi.encode(params)));

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }({
            params: params,
            campaignCreator: msg.sender,
            comptroller: address(comptroller)
        });

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL({
            merkleLL: merkleLL,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            comptroller: address(comptroller),
            minFeeUSD: comptroller.getAirdropsMinFeeUSDFor(msg.sender)
        });
    }
}
