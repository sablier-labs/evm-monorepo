// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { Script } from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    bytes32 internal constant ZERO_SALT = bytes32(0);
    address internal deployer;
    string internal mnemonic;

    function setUp() public virtual {
        mnemonic = vm.envString("MNEMONIC");
        (deployer, ) = deriveRememberKey(mnemonic, 0);
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}
