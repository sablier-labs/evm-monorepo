// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { SablierV2MerkleLockupFactory } from "../../src/periphery/SablierV2MerkleLockupFactory.sol";

import { BaseScript } from "../Base.s.sol";

contract DeployMerkleLockupFactory is BaseScript {
    /// @dev Deploy via Forge.
    function run() public virtual broadcast returns (SablierV2MerkleLockupFactory merkleLockupFactory) {
        merkleLockupFactory = new SablierV2MerkleLockupFactory();
    }
}
