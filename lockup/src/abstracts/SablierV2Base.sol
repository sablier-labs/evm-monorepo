// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { IAdminable } from "../interfaces/IAdminable.sol";
import { ISablierV2Base } from "../interfaces/ISablierV2Base.sol";
import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { Errors } from "../libraries/Errors.sol";
import { Adminable } from "./Adminable.sol";
import { NoDelegateCall } from "./NoDelegateCall.sol";

/// @title SablierV2Base
/// @notice See the documentation in {ISablierV2Base}.
abstract contract SablierV2Base is
    ISablierV2Base, // no dependencies
    NoDelegateCall, // no dependencies
    Adminable // one dependency
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Base
    UD60x18 public immutable override MAX_FEE;

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Base
    ISablierV2Comptroller public override comptroller;

    /// @inheritdoc ISablierV2Base
    mapping(IERC20 asset => uint128 revenues) public override protocolRevenues;

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
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Base
    function claimProtocolRevenues(IERC20 asset) external override onlyAdmin {
        // Checks: the protocol revenues are not zero.
        uint128 revenues = protocolRevenues[asset];
        if (revenues == 0) {
            revert Errors.SablierV2Base_NoProtocolRevenues(asset);
        }

        // Effects: set the protocol revenues to zero.
        protocolRevenues[asset] = 0;

        // Interactions: perform the ERC-20 transfer to pay the protocol revenues.
        asset.safeTransfer({ to: msg.sender, value: revenues });

        // Log the claim of the protocol revenues.
        emit ISablierV2Base.ClaimProtocolRevenues({ admin: msg.sender, asset: asset, protocolRevenues: revenues });
    }

    /// @inheritdoc ISablierV2Base
    function setComptroller(ISablierV2Comptroller newComptroller) external override onlyAdmin {
        // Effects: set the new comptroller.
        ISablierV2Comptroller oldComptroller = comptroller;
        comptroller = newComptroller;

        // Log the change of the comptroller.
        emit ISablierV2Base.SetComptroller({
            admin: msg.sender,
            oldComptroller: oldComptroller,
            newComptroller: newComptroller
        });
    }
}
