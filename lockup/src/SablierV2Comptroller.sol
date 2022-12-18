// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { Ownable } from "@prb/contracts/access/Ownable.sol";
import { UD60x18, ud, ZERO } from "@prb/math/UD60x18.sol";

import { Events } from "./libraries/Events.sol";

import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";

/// @title SablierV2Comptroller
/// @dev This contract implements the ISablierV2Comptroller interface.
contract SablierV2Comptroller is
    ISablierV2Comptroller, // one dependency
    Ownable // one dependency
{
    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Global fees mapped by token addresses.
    mapping(address => UD60x18) internal _protocolFees;

    /*//////////////////////////////////////////////////////////////////////////
                             PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getProtocolFee(address token) external view override returns (UD60x18 protocolFee) {
        protocolFee = _protocolFees[token];
    }

    /*//////////////////////////////////////////////////////////////////////////
                           PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Comptroller
    function setProtocolFee(address token, UD60x18 newProtocolFee) external onlyOwner {
        // Effects: set the new global fee.
        UD60x18 oldProtocolFee = _protocolFees[token];
        _protocolFees[token] = newProtocolFee;

        // Emit an event.
        emit Events.SetProtocolFee(owner, token, oldProtocolFee, newProtocolFee);
    }
}
