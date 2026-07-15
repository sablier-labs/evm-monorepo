// SPDX-License-Identifier: UNLICENSED
// solhint-disable no-inline-assembly
pragma solidity >=0.8.22;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { StdConstants, Vm } from "forge-std/src/StdConstants.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { ChainlinkOracleMock } from "src/mocks/ChainlinkMocks.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

import {
    AtomicComptrollerDeployer,
    Create2Utils,
    NonDeterministicComptrollerDeployer,
    VanityComptrollerDeployer
} from "../../../../scripts/solidity/AtomicComptrollerDeployer.sol";

contract Constructor_Integration_Concrete_Test is StdAssertions {
    address internal constant CANONICAL_CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address internal constant CANONICAL_PROXY = 0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399;
    address internal constant EXPECTED_LEGACY_IMPLEMENTATION = 0x53dE3A712d2b6657e92fA2452d58a6b823f86920;
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant INITIAL_ADMIN = address(0xA11CE);
    uint256 internal constant INITIAL_MIN_FEE_USD = 1e8;
    bytes32 internal constant IMPLEMENTATION_SALT = bytes32("implementation");
    address internal constant LEGACY_IMPLEMENTATION_ADMIN = 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F;
    bytes32 internal constant LEGACY_IMPLEMENTATION_SALT = bytes32("Version 1.0.0");
    bytes32 internal constant PROXY_SALT = bytes32("proxy");
    bytes32 internal constant VANITY_PROXY_SALT = 0xf26994e6af0b95cca8dfa22a0bc25e1f38a54c42d98a250c915c3f25c66e005e;

    ChainlinkOracleMock internal oracle;
    Create2FactoryMock internal create2Factory;
    Vm internal vm = StdConstants.VM;

    function setUp() public {
        oracle = new ChainlinkOracleMock();
        create2Factory = new Create2FactoryMock();
    }

    function test_GivenNoPriorDeployment() external {
        AtomicComptrollerDeployer.Params memory params = _deploymentParams();
        (address proxy, address implementation) = _computeAddresses(params);

        // It should atomically deploy and initialize the comptroller.
        new AtomicComptrollerDeployer(params);
        _assertDeployment(proxy, implementation, INITIAL_MIN_FEE_USD);
    }

    function test_GivenProxyPredeployedByUnknownCaller() external {
        AtomicComptrollerDeployer.Params memory params = _deploymentParams();
        (address proxy, address implementation) = _computeAddresses(params);

        address unknownCaller = address(0xBAD);
        vm.startPrank(unknownCaller);
        _deploy(params.implementationSalt, params.implementationCreationCode);
        _deploy(params.proxySalt, params.proxyCreationCode);
        vm.stopPrank();

        // It should preserve the specified admin and configuration.
        assertEq(SablierComptroller(payable(proxy)).admin(), INITIAL_ADMIN, "predeployed proxy admin");
        new AtomicComptrollerDeployer(params);
        _assertDeployment(proxy, implementation, INITIAL_MIN_FEE_USD);
    }

    function test_GivenLegacyVanityDeployment() external {
        vm.etch(CANONICAL_CREATE2_FACTORY, address(create2Factory).code);

        VanityComptrollerDeployer.Params memory params;
        params.create2Factory = CANONICAL_CREATE2_FACTORY;
        params.legacyImplementationSalt = LEGACY_IMPLEMENTATION_SALT;
        params.legacyImplementationCreationCode = bytes.concat(
            _readCreationCode("scripts/bytecode/comptroller-v1.0/SablierComptroller.bytecode"),
            abi.encode(LEGACY_IMPLEMENTATION_ADMIN)
        );
        params.expectedLegacyImplementation = EXPECTED_LEGACY_IMPLEMENTATION;
        params.proxySalt = VANITY_PROXY_SALT;
        params.proxyCreationCode = bytes.concat(
            _readCreationCode("scripts/bytecode/comptroller-v1.0/ERC1967Proxy.bytecode"),
            abi.encode(EXPECTED_LEGACY_IMPLEMENTATION, bytes(""))
        );
        params.expectedProxy = CANONICAL_PROXY;
        params.implementationSalt = bytes32("Version 2.0.0");
        params.implementationCreationCode =
            bytes.concat(type(SablierComptroller).creationCode, abi.encode(INITIAL_ADMIN));
        params.expectedImplementation = Create2Utils.computeAddress(
            CANONICAL_CREATE2_FACTORY, params.implementationSalt, params.implementationCreationCode
        );
        params.initialAdmin = INITIAL_ADMIN;
        params.initialMinFeeUSD = 0;
        params.initialOracle = address(oracle);

        // It should deploy initialize and upgrade the exact vanity proxy atomically.
        new VanityComptrollerDeployer(params);
        assertGt(EXPECTED_LEGACY_IMPLEMENTATION.code.length, 0, "legacy implementation code");
        _assertDeployment(CANONICAL_PROXY, params.expectedImplementation, 0);
    }

    function test_GivenNon_deterministicDeployment() external {
        // It should atomically deploy and initialize the comptroller.
        NonDeterministicComptrollerDeployer deployer = new NonDeterministicComptrollerDeployer({
            initialAdmin: INITIAL_ADMIN,
            initialMinFeeUSD: INITIAL_MIN_FEE_USD,
            initialOracle: address(oracle)
        });
        _assertDeployment(deployer.PROXY(), deployer.IMPLEMENTATION(), INITIAL_MIN_FEE_USD);
    }

    function _assertDeployment(address proxy, address implementation, uint256 expectedMinFeeUSD) private view {
        SablierComptroller comptroller = SablierComptroller(payable(proxy));
        assertGt(implementation.code.length, 0, "implementation code");
        assertGt(proxy.code.length, 0, "proxy code");
        assertEq(address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT)))), implementation, "implementation slot");
        assertEq(comptroller.admin(), INITIAL_ADMIN, "admin");
        assertEq(comptroller.oracle(), address(oracle), "oracle");

        assertEq(comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Airdrops), expectedMinFeeUSD, "airdrops min fee");
        assertEq(comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Bob), expectedMinFeeUSD, "bob min fee");
        assertEq(comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Flow), expectedMinFeeUSD, "flow min fee");
        assertEq(comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Lockup), expectedMinFeeUSD, "lockup min fee");
    }

    function _computeAddresses(AtomicComptrollerDeployer.Params memory params)
        private
        pure
        returns (address proxy, address implementation)
    {
        implementation = Create2Utils.computeAddress(
            params.create2Factory, params.implementationSalt, params.implementationCreationCode
        );
        proxy = Create2Utils.computeAddress(params.create2Factory, params.proxySalt, params.proxyCreationCode);
    }

    function _deploy(bytes32 salt, bytes memory creationCode) private {
        (bool success,) = address(create2Factory).call(abi.encodePacked(salt, creationCode));
        assertTrue(success, "CREATE2 deployment");
    }

    function _deploymentParams() private view returns (AtomicComptrollerDeployer.Params memory params) {
        params.create2Factory = address(create2Factory);
        params.implementationSalt = IMPLEMENTATION_SALT;
        params.implementationCreationCode =
            bytes.concat(type(SablierComptroller).creationCode, abi.encode(INITIAL_ADMIN));
        params.proxySalt = PROXY_SALT;
        params.initialAdmin = INITIAL_ADMIN;
        params.initialMinFeeUSD = INITIAL_MIN_FEE_USD;
        params.initialOracle = address(oracle);

        address implementation = Create2Utils.computeAddress(
            params.create2Factory, params.implementationSalt, params.implementationCreationCode
        );
        bytes memory initializer = abi.encodeCall(
            SablierComptroller.initialize,
            (
                INITIAL_ADMIN,
                INITIAL_MIN_FEE_USD,
                INITIAL_MIN_FEE_USD,
                INITIAL_MIN_FEE_USD,
                INITIAL_MIN_FEE_USD,
                address(oracle)
            )
        );
        params.proxyCreationCode =
            bytes.concat(type(ERC1967Proxy).creationCode, abi.encode(implementation, initializer));
    }

    function _readCreationCode(string memory artifact) private view returns (bytes memory) {
        return vm.parseBytes(vm.trim(vm.readFile(artifact)));
    }
}

contract Create2FactoryMock {
    fallback() external payable {
        assembly {
            let creationCodeSize := sub(calldatasize(), 0x20)
            calldatacopy(0, 0x20, creationCodeSize)
            let deployed := create2(callvalue(), 0, creationCodeSize, calldataload(0))
            if iszero(deployed) { revert(0, 0) }
            mstore(0, deployed)
            return(0x0c, 0x14)
        }
    }
}
