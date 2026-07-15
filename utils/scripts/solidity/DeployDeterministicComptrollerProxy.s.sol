// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseScript } from "src/tests/BaseScript.sol";

interface ISablierComptrollerV10 {
    function admin() external view returns (address);

    function getMinFeeUSD(uint8 protocol) external view returns (uint256);

    function initialize(
        address initialAdmin,
        uint256 initialAirdropMinFeeUSD,
        uint256 initialFlowMinFeeUSD,
        uint256 initialLockupMinFeeUSD,
        address initialOracle
    )
        external;

    function oracle() external view returns (address);
}

/// @notice Bootstraps the canonical Sablier Comptroller v1.0 implementation and vanity proxy using CREATE2.
/// @dev The proxy's fixed salt commits to the v1.0 implementation address, so a newer implementation cannot be used
/// here. Run `UpgradeDeterministicComptrollerProxy` after this script.
contract DeployDeterministicComptrollerProxy is BaseScript {
    address private constant EXPECTED_IMPLEMENTATION = 0x53dE3A712d2b6657e92fA2452d58a6b823f86920;
    address private constant EXPECTED_PROXY = 0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399;
    address private constant LEGACY_IMPLEMENTATION_ADMIN = 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F;
    bytes32 private constant IMPLEMENTATION_SALT = bytes32("Version 1.0.0");
    bytes32 private constant PROXY_SALT = 0xf26994e6af0b95cca8dfa22a0bc25e1f38a54c42d98a250c915c3f25c66e005e;

    function run() public broadcast returns (address proxy, address implementation) {
        bytes memory implementationCreationCode = bytes.concat(
            _readCreationCode("scripts/bytecode/comptroller-v1.0/SablierComptroller.bytecode"),
            abi.encode(LEGACY_IMPLEMENTATION_ADMIN)
        );
        implementation = _deploy(IMPLEMENTATION_SALT, implementationCreationCode);
        vm.assertEq(implementation, EXPECTED_IMPLEMENTATION, "implementation: unexpected address");

        bytes memory proxyCreationCode = bytes.concat(
            _readCreationCode("scripts/bytecode/comptroller-v1.0/ERC1967Proxy.bytecode"),
            abi.encode(implementation, bytes(""))
        );
        proxy = _deploy(PROXY_SALT, proxyCreationCode);
        vm.assertEq(proxy, EXPECTED_PROXY, "proxy: unexpected address");

        ISablierComptrollerV10 comptroller = ISablierComptrollerV10(proxy);
        if (comptroller.admin() == address(0)) {
            // The broadcaster is the transient admin needed for the immediate v1.1 upgrade. The upgrade script
            // transfers control to `getAdmin()` before any dependent protocol is deployed.
            comptroller.initialize({
                initialAdmin: broadcaster,
                initialAirdropMinFeeUSD: getInitialMinFeeUSD(),
                initialFlowMinFeeUSD: getInitialMinFeeUSD(),
                initialLockupMinFeeUSD: getInitialMinFeeUSD(),
                initialOracle: getChainlinkOracle()
            });
        }

        address proxyAdmin = comptroller.admin();
        vm.assertTrue(proxyAdmin == broadcaster || proxyAdmin == getAdmin(), "proxy: admin");
        vm.assertEq(comptroller.oracle(), getChainlinkOracle(), "proxy: oracle");
        for (uint8 protocol = 0; protocol < 4; ++protocol) {
            vm.assertEq(comptroller.getMinFeeUSD(protocol), getInitialMinFeeUSD(), "proxy: min fee");
        }
    }

    function _deploy(bytes32 salt, bytes memory creationCode) private returns (address deployed) {
        deployed = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2_FACTORY, salt, keccak256(creationCode)))))
        );

        if (deployed.code.length == 0) {
            (bool success,) = CREATE2_FACTORY.call(abi.encodePacked(salt, creationCode));
            vm.assertTrue(success, "CREATE2 deployment failed");
        }
        vm.assertGt(deployed.code.length, 0, "CREATE2 deployment produced no code");
    }

    function _readCreationCode(string memory artifact) private view returns (bytes memory) {
        return vm.parseBytes(vm.trim(vm.readFile(artifact)));
    }
}
