// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { SablierFactoryMerkleBase } from "./abstracts/SablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleLT } from "./interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { SablierMerkleLT } from "./SablierMerkleLT.sol";
import { MerkleLT } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗     ████████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║     ╚══██╔══╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║        ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║        ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ███████╗   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝   ╚═╝

*/

/// @title SablierFactoryMerkleLT
/// @notice See the documentation in {ISablierFactoryMerkleLT}.
contract SablierFactoryMerkleLT is ISablierFactoryMerkleLT, SablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) SablierFactoryMerkleBase(initialComptroller) { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleLT
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        override
        returns (bool result)
    {
        uint256 totalPercentage;
        for (uint256 i = 0; i < tranches.length; ++i) {
            totalPercentage += tranches[i].unlockPercentage.unwrap();
        }
        return totalPercentage == uUNIT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleLT
    function createMerkleLT(
        MerkleLT.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLT merkleLT)
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(address(params.token));

        // Calculate the sum of percentages and durations across all tranches.
        uint256 count = params.tranchesWithPercentages.length;
        uint256 totalDuration;
        for (uint256 i = 0; i < count; ++i) {
            unchecked {
                // Safe to use `unchecked` because its only used in the event.
                totalDuration += params.tranchesWithPercentages[i].duration;
            }
        }

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, comptroller, abi.encode(params)));

        // Deploy the MerkleLT contract with CREATE2.
        merkleLT = new SablierMerkleLT{ salt: salt }({
            params: params,
            campaignCreator: msg.sender,
            comptroller: address(comptroller)
        });

        // Log the creation of the MerkleLT contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLT({
            merkleLT: merkleLT,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            totalDuration: totalDuration,
            comptroller: address(comptroller),
            minFeeUSD: comptroller.getAirdropsMinFeeUSDFor(msg.sender)
        });
    }
}
