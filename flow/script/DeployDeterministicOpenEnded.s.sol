// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2OpenEnded } from "src/SablierV2OpenEnded.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierV2OpenEnded} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicOpenEnded is BaseScript {
    function run() public broadcast returns (SablierV2OpenEnded openEnded) {
        openEnded = new SablierV2OpenEnded{ salt: constructCreate2Salt() }();
    }
}
