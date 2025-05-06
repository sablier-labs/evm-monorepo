// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20Faucet } from "src/mocks/erc20/ERC20Faucet.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

contract DeployDeterministicERC20Faucet is BaseScript {
    function run() public broadcast returns (ERC20Faucet token) {
        bytes32 salt = keccak256(abi.encodePacked("This is the ERC20Faucet salt"));
        token = new ERC20Faucet{ salt: salt }();
    }
}
