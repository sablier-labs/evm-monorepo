// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { StdConstants, Vm } from "forge-std/src/StdConstants.sol";

import { ChainId } from "src/tests/ChainId.sol";
import { DeployBespokeComptrollerProxy } from "../../../../scripts/solidity/DeployBespokeComptrollerProxy.s.sol";

contract Run_Integration_Concrete_Test {
    Vm internal vm = StdConstants.VM;

    function test_RevertGiven_VanityProxyConfigured() external {
        vm.chainId(ChainId.ETHEREUM);
        DeployBespokeComptrollerProxy script = new DeployBespokeComptrollerProxy();
        address proxy = script.getComptroller();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(DeployBespokeComptrollerProxy.VanityAddressConfigured.selector, proxy));
        script.run();
    }

    function test_RevertGiven_BespokeProxyAlreadyDeployed() external {
        vm.chainId(ChainId.ROBINHOOD);
        DeployBespokeComptrollerProxy script = new DeployBespokeComptrollerProxy();
        address proxy = script.getComptroller();
        vm.etch(proxy, hex"00");

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(DeployBespokeComptrollerProxy.ProxyAlreadyDeployed.selector, proxy));
        script.run();
    }

    function test_RevertGiven_CREATE2FactoryUnavailable() external {
        vm.chainId(ChainId.ROBINHOOD);
        DeployBespokeComptrollerProxy script = new DeployBespokeComptrollerProxy();

        // It should revert when the deployed proxy differs from the configured proxy.
        vm.expectPartialRevert(DeployBespokeComptrollerProxy.UnexpectedProxy.selector);
        script.run();
    }
}
