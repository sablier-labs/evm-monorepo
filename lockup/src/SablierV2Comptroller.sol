// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { Adminable } from "@prb/contracts/access/Adminable.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { Events } from "./libraries/Events.sol";

/// @title SablierV2Comptroller
/// @dev This contract implements the {ISablierV2Comptroller} interface.
contract SablierV2Comptroller is
    ISablierV2Comptroller, // one dependency
    Adminable // one dependency
{
    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Comptroller
    UD60x18 public override flashFee;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev ERC-20 assets that can be flash loaned.
    mapping(IERC20 => bool) internal _flashAssets;

    /// @dev Global fees mapped by ERC-20 asset addresses.
    mapping(IERC20 => UD60x18) internal _protocolFees;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    constructor(address initialAdmin) {
        admin = initialAdmin;
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Comptroller
    function getProtocolFee(IERC20 asset) external view override returns (UD60x18 protocolFee) {
        protocolFee = _protocolFees[asset];
    }

    /// @inheritdoc ISablierV2Comptroller
    function isFlashLoanable(IERC20 asset) external view override returns (bool result) {
        result = _flashAssets[asset];
    }

    /*//////////////////////////////////////////////////////////////////////////
                           PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Comptroller
    function setFlashFee(UD60x18 newFlashFee) external override onlyAdmin {
        // Effects: set the new flash fee.
        UD60x18 oldFlashFee = flashFee;
        flashFee = newFlashFee;

        // Emit an event.
        emit Events.SetFlashFee({ admin: msg.sender, oldFlashFee: oldFlashFee, newFlashFee: newFlashFee });
    }

    /// @inheritdoc ISablierV2Comptroller
    function setProtocolFee(IERC20 asset, UD60x18 newProtocolFee) external override onlyAdmin {
        // Effects: set the new global fee.
        UD60x18 oldProtocolFee = _protocolFees[asset];
        _protocolFees[asset] = newProtocolFee;

        // Emit an event.
        emit Events.SetProtocolFee({
            admin: msg.sender,
            asset: asset,
            oldProtocolFee: oldProtocolFee,
            newProtocolFee: newProtocolFee
        });
    }

    /// @inheritdoc ISablierV2Comptroller
    function toggleFlashAsset(IERC20 asset) external override onlyAdmin {
        // Effects: enable the ERC-20 asset for flash loaning.
        bool oldFlag = _flashAssets[asset];
        _flashAssets[asset] = !oldFlag;

        // Emit an event.
        emit Events.ToggleFlashAsset({ admin: msg.sender, asset: asset, newFlag: !oldFlag });
    }
}
