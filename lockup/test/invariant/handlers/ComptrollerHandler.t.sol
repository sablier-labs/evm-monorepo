// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, UNIT } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { BaseHandler } from "./BaseHandler.t.sol";

/// @title ComptrollerHandler
/// @dev This contract and not {SablierV2Comptroller} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract ComptrollerHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    ISablierV2Comptroller public comptroller;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, ISablierV2Comptroller comptroller_) {
        asset = asset_;
        comptroller = comptroller_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-COMPTROLLER
    //////////////////////////////////////////////////////////////////////////*/

    function setFlashFee(UD60x18 newFlashFee) external instrument("setFlashFee") {
        newFlashFee = _bound(newFlashFee, 0, UNIT);
        comptroller.setFlashFee(newFlashFee);
    }

    function setProtocolFee(UD60x18 newProtocolFee) external instrument("setProtocolFee") {
        newProtocolFee = _bound(newProtocolFee, 0, MAX_FEE);
        comptroller.setProtocolFee(asset, newProtocolFee);
    }

    function toggleFlashAsset() external instrument("toggleFlashAsset") {
        comptroller.toggleFlashAsset(asset);
    }
}
