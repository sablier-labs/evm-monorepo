// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { ComptrollerManager } from "@sablier/evm-utils/src/ComptrollerManager.sol";

import { ISablierFactoryMerkleBase } from "./../interfaces/ISablierFactoryMerkleBase.sol";
import { Errors } from "./../libraries/Errors.sol";

/// @title SablierFactoryMerkleBase
/// @notice See the documentation in {ISablierFactoryMerkleBase}.
abstract contract SablierFactoryMerkleBase is
    ComptrollerManager, // 1 inherited component
    ISablierFactoryMerkleBase // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleBase
    address public override nativeToken;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialComptroller The address of the initial comptroller contract.
    constructor(address initialComptroller) ComptrollerManager(initialComptroller) { }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleBase
    function setNativeToken(address newNativeToken) external override onlyComptroller {
        // Check: provided token is not zero address.
        if (newNativeToken == address(0)) {
            revert Errors.SablierFactoryMerkleBase_NativeTokenZeroAddress();
        }

        // Check: native token is not set.
        if (nativeToken != address(0)) {
            revert Errors.SablierFactoryMerkleBase_NativeTokenAlreadySet(nativeToken);
        }

        // Effect: set the native token.
        nativeToken = newNativeToken;

        // Log the update.
        emit SetNativeToken({ comptroller: msg.sender, nativeToken: newNativeToken });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks that the provided token is not the native token.
    /// @dev Reverts if the provided token is the native token.
    function _forbidNativeToken(address token) internal view {
        if (token == nativeToken) {
            revert Errors.SablierFactoryMerkleBase_ForbidNativeToken(token);
        }
    }
}
