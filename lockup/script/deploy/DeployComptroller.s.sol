// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19 <=0.9.0;

import { SablierV2Comptroller } from "../../src/SablierV2Comptroller.sol";

import { BaseScript } from "../shared/Base.s.sol";

contract DeployComptroller is BaseScript {
    function run(address initialAdmin) public virtual broadcaster returns (SablierV2Comptroller comptroller) {
        comptroller = new SablierV2Comptroller(initialAdmin);
    }
}
