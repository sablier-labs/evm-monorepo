// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

import { Errors } from "src/libraries/Errors.sol";

/// @title NoDelegateCall
/// @notice This contract implements logic to prevent delegate calls.
abstract contract NoDelegateCall {
    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    address private immutable _original;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        _original = address(this);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Prevents delegate calls.
    modifier noDelegateCall() {
        _preventDelegateCall();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev This function checks whether a delegate call is being made.
    ///
    /// A private function is used instead of inlining this logic in a modifier because Solidity copies modifiers into
    /// every function that uses them. The `_original` address would get copied in every place the modifier is used,
    /// which would increase the contract size. By using a function instead, we can avoid this duplication of code
    /// and reduce the overall size of the contract.
    function _preventDelegateCall() private view {
        if (address(this) != _original) {
            revert Errors.DelegateCall();
        }
    }
}
