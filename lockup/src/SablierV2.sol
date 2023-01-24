// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { Adminable } from "@prb/contracts/access/Adminable.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";

/// @title SablierV2
/// @dev Abstract contract that implements the ISablierV2 interface.
abstract contract SablierV2 is
    ISablierV2, // no dependencies
    Adminable // one dependency
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    UD60x18 public immutable override MAX_FEE;

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    ISablierV2Comptroller public override comptroller;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Protocol revenues mapped by ERC-20 asset addresses.
    mapping(IERC20 => uint128) internal _protocolRevenues;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param maxFee The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    constructor(address initialAdmin, ISablierV2Comptroller initialComptroller, UD60x18 maxFee) {
        admin = initialAdmin;
        comptroller = initialComptroller;
        MAX_FEE = maxFee;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function getProtocolRevenues(IERC20 asset) external view override returns (uint128 protocolRevenues) {
        protocolRevenues = _protocolRevenues[asset];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2
    function claimProtocolRevenues(IERC20 asset) external override onlyAdmin {
        // Checks: the protocol revenues are not zero.
        uint128 protocolRevenues = _protocolRevenues[asset];
        if (protocolRevenues == 0) {
            revert Errors.SablierV2Lockup_NoProtocolRevenues(asset);
        }

        // Effects: set the protocol revenues to zero.
        _protocolRevenues[asset] = 0;

        // Interactions: perform the ERC-20 transfer to pay the protocol revenues.
        asset.safeTransfer(msg.sender, protocolRevenues);

        // Emit an event.
        emit Events.ClaimProtocolRevenues(msg.sender, asset, protocolRevenues);
    }

    /// @inheritdoc ISablierV2
    function setComptroller(ISablierV2Comptroller newComptroller) external override onlyAdmin {
        // Effects: set the new comptroller.
        ISablierV2Comptroller oldComptroller = comptroller;
        comptroller = newComptroller;

        // Emit an event.
        emit Events.SetComptroller({
            admin: msg.sender,
            oldComptroller: oldComptroller,
            newComptroller: newComptroller
        });
    }
}
