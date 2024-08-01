// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleLockupFactory } from "../../src/periphery/SablierMerkleLockupFactory.sol";

import { BaseScript } from "../Base.s.sol";

contract DeployMerkleLockupFactory is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (SablierMerkleLockupFactory merkleLockupFactory) {
        merkleLockupFactory = new SablierMerkleLockupFactory();
    }
}
