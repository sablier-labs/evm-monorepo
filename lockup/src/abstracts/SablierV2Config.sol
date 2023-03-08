// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Adminable } from "../interfaces/ISablierV2Adminable.sol";
import { ISablierV2Config } from "../interfaces/ISablierV2Config.sol";
import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { Errors } from "../libraries/Errors.sol";
import { SablierV2Adminable } from "./SablierV2Adminable.sol";

/// @title SablierV2Config
/// @dev Abstract contract that implements the {ISablierV2Config} interface.
abstract contract SablierV2Config is
    ISablierV2Config, // no dependencies
    SablierV2Adminable // one dependency
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Config
    UD60x18 public immutable override MAX_FEE;

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Config
    ISablierV2Comptroller public override comptroller;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Protocol revenues mapped by ERC-20 asset addresses.
    mapping(IERC20 asset => uint128 revenues) internal _protocolRevenues;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param maxFee The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    constructor(address initialAdmin, ISablierV2Comptroller initialComptroller, UD60x18 maxFee) {
        admin = initialAdmin;
        comptroller = initialComptroller;
        MAX_FEE = maxFee;
        emit ISablierV2Adminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Config
    function getProtocolRevenues(IERC20 asset) external view override returns (uint128 protocolRevenues) {
        protocolRevenues = _protocolRevenues[asset];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Config
    function claimProtocolRevenues(IERC20 asset) external override onlyAdmin {
        // Checks: the protocol revenues are not zero.
        uint128 protocolRevenues = _protocolRevenues[asset];
        if (protocolRevenues == 0) {
            revert Errors.SablierV2Lockup_NoProtocolRevenues(asset);
        }

        // Effects: set the protocol revenues to zero.
        _protocolRevenues[asset] = 0;

        // Interactions: perform the ERC-20 transfer to pay the protocol revenues.
        asset.safeTransfer({ to: msg.sender, value: protocolRevenues });

        // Log the claim of the protocol revenues.
        emit ISablierV2Config.ClaimProtocolRevenues({
            admin: msg.sender,
            asset: asset,
            protocolRevenues: protocolRevenues
        });
    }

    /// @inheritdoc ISablierV2Config
    function setComptroller(ISablierV2Comptroller newComptroller) external override onlyAdmin {
        // Effects: set the new comptroller.
        ISablierV2Comptroller oldComptroller = comptroller;
        comptroller = newComptroller;

        // Log the change of the comptroller.
        emit ISablierV2Config.SetComptroller({
            admin: msg.sender,
            oldComptroller: oldComptroller,
            newComptroller: newComptroller
        });
    }
}
