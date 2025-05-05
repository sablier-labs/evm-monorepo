// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { SablierERC20Faucet } from "src/mocks/erc20/SablierERC20Faucet.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

contract DeploySablierERC20Faucet is BaseScript {
    function run() public broadcast returns (SablierERC20Faucet token) {
        token = new SablierERC20Faucet();
    }
}
