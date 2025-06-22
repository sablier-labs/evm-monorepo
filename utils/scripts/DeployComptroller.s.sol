// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { SablierComptroller } from "../src/SablierComptroller.sol";
import { BaseScript } from "../src/tests/BaseScript.sol";

contract DeployComptroller is BaseScript {
    function run() public broadcast returns (SablierComptroller comptroller) {
        comptroller = new SablierComptroller(
            getAdmin(), getInitialMinFeeUSD(), getInitialMinFeeUSD(), getInitialMinFeeUSD(), getChainlinkOracle()
        );
    }
}
