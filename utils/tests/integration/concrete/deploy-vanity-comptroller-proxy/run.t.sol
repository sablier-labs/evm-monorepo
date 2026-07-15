// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { StdConstants, Vm } from "forge-std/src/StdConstants.sol";

import { ChainId } from "src/tests/ChainId.sol";
import { DeployVanityComptrollerProxy } from "../../../../scripts/solidity/DeployVanityComptrollerProxy.s.sol";

contract Run_Integration_Concrete_Test {
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    Vm internal vm = StdConstants.VM;

    function test_RevertGiven_BespokeProxyConfigured() external {
        vm.chainId(ChainId.ROBINHOOD);
        DeployVanityComptrollerProxy script = new DeployVanityComptrollerProxy();
        address configuredProxy = script.getComptroller();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(DeployVanityComptrollerProxy.VanityAddressNotConfigured.selector, configuredProxy)
        );
        script.run();
    }

    function test_RevertGiven_VanityProxyAlreadyDeployed() external {
        vm.chainId(ChainId.ETHEREUM);
        DeployVanityComptrollerProxy script = new DeployVanityComptrollerProxy();
        address proxy = script.getComptroller();
        vm.etch(proxy, hex"00");

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(DeployVanityComptrollerProxy.ProxyAlreadyDeployed.selector, proxy));
        script.run();
    }

    function test_RevertGiven_CREATE2FactoryNotDeployed() external {
        vm.chainId(ChainId.ETHEREUM);
        vm.etch(CREATE2_FACTORY, "");
        DeployVanityComptrollerProxy script = new DeployVanityComptrollerProxy();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(DeployVanityComptrollerProxy.Create2FactoryNotDeployed.selector, CREATE2_FACTORY)
        );
        script.run();
    }
}
