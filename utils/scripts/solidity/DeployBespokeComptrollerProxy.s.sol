// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

import {
    AtomicComptrollerDeployer,
    Create2Utils,
    NonDeterministicComptrollerDeployer
} from "./AtomicComptrollerDeployer.sol";

/// @notice Atomically deploys the current Comptroller implementation and a bespoke initialized proxy.
/// @dev The initializer binds the intended admin to the proxy initcode, so a copied deployment keeps the same
/// authority. Uses CREATE2 when its canonical factory is available and CREATE otherwise. This script rejects chains
/// configured to use the vanity proxy.
contract DeployBespokeComptrollerProxy is BaseScript {
    error ProxyAlreadyDeployed(address proxy);
    error UnexpectedProxy(address actual, address expected);
    error VanityAddressConfigured(address proxy);

    string internal constant DEPLOYMENT_VERSION = "2.0.0";

    function run() public broadcast returns (address proxy, address implementation) {
        address expectedProxy = getComptroller();
        if (expectedProxy == CANONICAL_COMPTROLLER) revert VanityAddressConfigured(expectedProxy);
        if (expectedProxy.code.length != 0) revert ProxyAlreadyDeployed(expectedProxy);

        if (CREATE2_FACTORY.code.length == 0) {
            NonDeterministicComptrollerDeployer deployer = new NonDeterministicComptrollerDeployer({
                initialAdmin: getAdmin(),
                initialMinFeeUSD: getInitialMinFeeUSD(),
                initialOracle: getChainlinkOracle()
            });
            proxy = deployer.PROXY();
            implementation = deployer.IMPLEMENTATION();
        } else {
            (proxy, implementation) = _deployDeterministic(expectedProxy);
        }

        if (proxy != expectedProxy) revert UnexpectedProxy({ actual: proxy, expected: expectedProxy });

        vm.assertGt(implementation.code.length, 0, "implementation: not deployed");
        vm.assertGt(proxy.code.length, 0, "proxy: not deployed");
    }

    function getVersion() public pure override returns (string memory) {
        return DEPLOYMENT_VERSION;
    }

    function _deployDeterministic(address expectedProxy) private returns (address proxy, address implementation) {
        AtomicComptrollerDeployer.Params memory params = _deploymentParams();
        implementation = Create2Utils.computeAddress({
            create2Factory: params.create2Factory,
            salt: params.implementationSalt,
            creationCode: params.implementationCreationCode
        });
        proxy = Create2Utils.computeAddress({
            create2Factory: params.create2Factory,
            salt: params.proxySalt,
            creationCode: params.proxyCreationCode
        });

        if (proxy != expectedProxy) revert UnexpectedProxy({ actual: proxy, expected: expectedProxy });

        new AtomicComptrollerDeployer(params);
    }

    function _deploymentParams() private view returns (AtomicComptrollerDeployer.Params memory params) {
        params.create2Factory = CREATE2_FACTORY;
        params.implementationSalt = bytes32(abi.encodePacked(string.concat("Version ", DEPLOYMENT_VERSION)));
        params.implementationCreationCode = bytes.concat(type(SablierComptroller).creationCode, abi.encode(getAdmin()));
        params.proxySalt = keccak256(abi.encode("Sablier Comptroller Proxy", chainId, DEPLOYMENT_VERSION));
        params.initialAdmin = getAdmin();
        params.initialMinFeeUSD = getInitialMinFeeUSD();
        params.initialOracle = getChainlinkOracle();

        address implementation = Create2Utils.computeAddress({
            create2Factory: params.create2Factory,
            salt: params.implementationSalt,
            creationCode: params.implementationCreationCode
        });
        bytes memory initializer = abi.encodeCall(
            SablierComptroller.initialize,
            (
                params.initialAdmin,
                params.initialMinFeeUSD,
                params.initialMinFeeUSD,
                params.initialMinFeeUSD,
                params.initialMinFeeUSD,
                params.initialOracle
            )
        );
        params.proxyCreationCode =
            bytes.concat(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializer));
    }
}
