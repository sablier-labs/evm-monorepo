// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Adminable } from "./abstracts/Adminable.sol";
import { IAdminable } from "./interfaces/IAdminable.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗   ██╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║   ██║╚════██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║   ██║ █████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║     ╚████╔╝ ███████╗
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝

 ██████╗ ██████╗ ███╗   ███╗██████╗ ████████╗██████╗  ██████╗ ██╗     ██╗     ███████╗██████╗
██╔════╝██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██╔═══██╗██║     ██║     ██╔════╝██╔══██╗
██║     ██║   ██║██╔████╔██║██████╔╝   ██║   ██████╔╝██║   ██║██║     ██║     █████╗  ██████╔╝
██║     ██║   ██║██║╚██╔╝██║██╔═══╝    ██║   ██╔══██╗██║   ██║██║     ██║     ██╔══╝  ██╔══██╗
╚██████╗╚██████╔╝██║ ╚═╝ ██║██║        ██║   ██║  ██║╚██████╔╝███████╗███████╗███████╗██║  ██║
 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝        ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝

*/

/// @title SablierV2Comptroller
/// @notice See the documentation in {ISablierV2Comptroller}.
contract SablierV2Comptroller is
    ISablierV2Comptroller, // 1 inherited component
    Adminable // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Comptroller
    mapping(IERC20 asset => UD60x18 fee) public override protocolFees;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    constructor(address initialAdmin) {
        admin = initialAdmin;
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Comptroller
    function setProtocolFee(IERC20 asset, UD60x18 newProtocolFee) external override onlyAdmin {
        // Effects: set the new global fee.
        UD60x18 oldProtocolFee = protocolFees[asset];
        protocolFees[asset] = newProtocolFee;

        // Log the change of the protocol fee.
        emit ISablierV2Comptroller.SetProtocolFee({
            admin: msg.sender,
            asset: asset,
            oldProtocolFee: oldProtocolFee,
            newProtocolFee: newProtocolFee
        });
    }
}
