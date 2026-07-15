// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { SablierComptroller } from "src/SablierComptroller.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

import { Create2Utils, VanityComptrollerDeployer } from "./AtomicComptrollerDeployer.sol";

/// @notice Deploys the legacy vanity proxy, initializes it, and upgrades it to Comptroller v1.1 in one transaction.
/// @dev The legacy proxy initcode is public and contains empty initialization calldata. Although this script removes
/// the initialization gap within its transaction, a third party can still predeploy and initialize the proxy first.
contract DeployVanityComptrollerProxy is BaseScript {
    address private constant EXPECTED_LEGACY_IMPLEMENTATION = 0x53dE3A712d2b6657e92fA2452d58a6b823f86920;
    address private constant LEGACY_IMPLEMENTATION_ADMIN = 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F;
    bytes32 private constant LEGACY_IMPLEMENTATION_SALT = bytes32("Version 1.0.0");
    bytes32 private constant PROXY_SALT = 0xf26994e6af0b95cca8dfa22a0bc25e1f38a54c42d98a250c915c3f25c66e005e;
    string internal constant DEPLOYMENT_VERSION = "2.0.0";

    error Create2FactoryNotDeployed(address factory);
    error ProxyAlreadyDeployed(address proxy);
    error VanityAddressNotConfigured(address configuredProxy);

    function run() public broadcast returns (address proxy, address implementation) {
        proxy = getComptroller();
        if (proxy != CANONICAL_COMPTROLLER) revert VanityAddressNotConfigured(proxy);
        if (proxy.code.length != 0) revert ProxyAlreadyDeployed(proxy);
        if (CREATE2_FACTORY.code.length == 0) revert Create2FactoryNotDeployed(CREATE2_FACTORY);

        VanityComptrollerDeployer.Params memory params = _deploymentParams();
        implementation = params.expectedImplementation;
        new VanityComptrollerDeployer(params);

        vm.assertGt(implementation.code.length, 0, "implementation: not deployed");
        vm.assertGt(proxy.code.length, 0, "proxy: not deployed");
    }

    function getVersion() public pure override returns (string memory) {
        return DEPLOYMENT_VERSION;
    }

    function _deploymentParams() private view returns (VanityComptrollerDeployer.Params memory params) {
        params.create2Factory = CREATE2_FACTORY;
        params.legacyImplementationSalt = LEGACY_IMPLEMENTATION_SALT;
        params.legacyImplementationCreationCode = bytes.concat(
            _readCreationCode("scripts/bytecode/comptroller-v1.0/SablierComptroller.bytecode"),
            abi.encode(LEGACY_IMPLEMENTATION_ADMIN)
        );
        params.expectedLegacyImplementation = EXPECTED_LEGACY_IMPLEMENTATION;
        params.proxySalt = PROXY_SALT;
        params.proxyCreationCode = bytes.concat(
            _readCreationCode("scripts/bytecode/comptroller-v1.0/ERC1967Proxy.bytecode"),
            abi.encode(EXPECTED_LEGACY_IMPLEMENTATION, bytes(""))
        );
        params.expectedProxy = CANONICAL_COMPTROLLER;
        params.implementationSalt = bytes32(abi.encodePacked(string.concat("Version ", DEPLOYMENT_VERSION)));
        params.implementationCreationCode = bytes.concat(type(SablierComptroller).creationCode, abi.encode(getAdmin()));
        params.expectedImplementation = Create2Utils.computeAddress(
            CREATE2_FACTORY, params.implementationSalt, params.implementationCreationCode
        );
        params.initialAdmin = getAdmin();
        params.initialMinFeeUSD = getInitialMinFeeUSD();
        params.initialOracle = getChainlinkOracle();
    }

    function _readCreationCode(string memory artifact) private view returns (bytes memory) {
        return vm.parseBytes(vm.trim(vm.readFile(artifact)));
    }
}
