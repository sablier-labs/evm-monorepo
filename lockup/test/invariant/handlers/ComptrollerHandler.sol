// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { TimestampStore } from "../stores/TimestampStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract and not {SablierV2Comptroller} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract ComptrollerHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller public comptroller;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        TimestampStore timestampStore_,
        ISablierV2Comptroller comptroller_
    )
        BaseHandler(asset_, timestampStore_)
    {
        comptroller = comptroller_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-COMPTROLLER
    //////////////////////////////////////////////////////////////////////////*/

    function setFlashFee(
        uint256 timeJumpSeed,
        UD60x18 newFlashFee
    )
        external
        instrument("setFlashFee")
        adjustTimestamp(timeJumpSeed)
    {
        newFlashFee = _bound(newFlashFee, 0, UNIT);
        comptroller.setFlashFee(newFlashFee);
    }

    function setProtocolFee(
        uint256 timeJumpSeed,
        UD60x18 newProtocolFee
    )
        external
        instrument("setProtocolFee")
        adjustTimestamp(timeJumpSeed)
    {
        newProtocolFee = _bound(newProtocolFee, 0, MAX_FEE);
        comptroller.setProtocolFee(asset, newProtocolFee);
    }

    function toggleFlashAsset(uint256 timeJumpSeed)
        external
        instrument("toggleFlashAsset")
        adjustTimestamp(timeJumpSeed)
    {
        comptroller.toggleFlashAsset(asset);
    }
}
