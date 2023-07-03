// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <=0.9.0;

import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployComptroller is BaseScript {
    function run(address initialAdmin) public virtual broadcast returns (SablierV2Comptroller comptroller) {
        comptroller = new SablierV2Comptroller(initialAdmin);
    }
}
