// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { UD60x18, uUNIT } from "@prb/math/src/UD60x18.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { SablierFactoryMerkleBase } from "./abstracts/SablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleVCA } from "./interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { Errors } from "./libraries/Errors.sol";
import { SablierMerkleVCA } from "./SablierMerkleVCA.sol";
import { MerkleVCA } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗   ██╗ ██████╗ █████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║   ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║   ██║██║     ███████║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ╚██╗ ██╔╝██║     ██╔══██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗     ╚████╔╝ ╚██████╗██║  ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═══╝   ╚═════╝╚═╝  ╚═╝

*/

/// @title SablierFactoryMerkleVCA
/// @notice See the documentation in {ISablierFactoryMerkleVCA}.
contract SablierFactoryMerkleVCA is ISablierFactoryMerkleVCA, SablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) SablierFactoryMerkleBase(initialComptroller) { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleVCA
    function computeMerkleVCA(
        address campaignCreator,
        MerkleVCA.ConstructorParams calldata params
    )
        external
        view
        override
        returns (address merkleVCA)
    {
        // Check: validate the deployment parameters.
        _checkDeploymentParams(
            address(params.token),
            params.vestingStartTime,
            params.vestingEndTime,
            params.expiration,
            params.unlockPercentage
        );

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, comptroller, abi.encode(params)));

        // Get the bytecode hash for the {SablierMerkleVCA} contract.
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(SablierMerkleVCA).creationCode, abi.encode(params, campaignCreator, address(comptroller))
            )
        );

        // Compute CREATE2 address using `keccak256(0xff + deployer + salt + bytecodeHash)`.
        merkleVCA =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleVCA
    function createMerkleVCA(
        MerkleVCA.ConstructorParams calldata params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleVCA merkleVCA)
    {
        // Check: validate the deployment parameters.
        _checkDeploymentParams(
            address(params.token),
            params.vestingStartTime,
            params.vestingEndTime,
            params.expiration,
            params.unlockPercentage
        );

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, comptroller, abi.encode(params)));

        // Deploy the MerkleVCA contract with CREATE2.
        merkleVCA = new SablierMerkleVCA{ salt: salt }({
            params: params,
            campaignCreator: msg.sender,
            comptroller: address(comptroller)
        });

        // Log the creation of the MerkleVCA contract, including some metadata that is not stored on-chain.
        emit CreateMerkleVCA({
            merkleVCA: merkleVCA,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            comptroller: address(comptroller),
            minFeeUSD: comptroller.getMinFeeUSDFor({ protocol: ISablierComptroller.Protocol.Airdrops, user: msg.sender })
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Validate the deployment parameters.
    function _checkDeploymentParams(
        address token,
        uint40 vestingStartTime,
        uint40 vestingEndTime,
        uint40 expiration,
        UD60x18 unlockPercentage
    )
        private
        view
    {
        // Check: user-provided token is not the native token.
        _forbidNativeToken(token);

        // Check: vesting start time is not zero.
        if (vestingStartTime == 0) {
            revert Errors.SablierFactoryMerkleVCA_StartTimeZero();
        }

        // Check: vesting end time is greater than the vesting start time.
        if (vestingEndTime <= vestingStartTime) {
            revert Errors.SablierFactoryMerkleVCA_VestingEndTimeNotGreaterThanVestingStartTime(
                vestingStartTime, vestingEndTime
            );
        }

        // Check: campaign expiration is not zero.
        if (expiration == 0) {
            revert Errors.SablierFactoryMerkleVCA_ExpirationTimeZero();
        }

        // Check: campaign expiration is at least 1 week later than the vesting end time.
        if (expiration < vestingEndTime + 1 weeks) {
            revert Errors.SablierFactoryMerkleVCA_ExpirationTooEarly(vestingEndTime, expiration);
        }

        // Check: unlock percentage is not greater than 100%.
        if (unlockPercentage.unwrap() > uUNIT) {
            revert Errors.SablierFactoryMerkleVCA_UnlockPercentageTooHigh(unlockPercentage);
        }
    }
}
