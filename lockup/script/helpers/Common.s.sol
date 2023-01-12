// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";

abstract contract Common is Script {
    /// @dev See https://github.com/Zoltu/deterministic-deployment-proxy.
    address internal constant DETERMINISTIC_CREATE2_FACTORY = 0x7A0D94F55792C434d74a40883C6ed8545E406D12;
    address internal deployer;

    function setUp() public virtual {
        string memory mnemonic = vm.envString("MNEMONIC");
        (deployer, ) = deriveRememberKey(mnemonic, 0);
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}
