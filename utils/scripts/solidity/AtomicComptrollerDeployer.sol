// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

interface ISablierComptrollerV10 {
    function initialize(
        address initialAdmin,
        uint256 initialAirdropMinFeeUSD,
        uint256 initialFlowMinFeeUSD,
        uint256 initialLockupMinFeeUSD,
        address initialOracle
    )
        external;
}

library Create2Utils {
    error DeploymentFailed(bytes32 salt);

    function computeAddress(
        address create2Factory,
        bytes32 salt,
        bytes memory creationCode
    )
        internal
        pure
        returns (address deployed)
    {
        deployed = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), create2Factory, salt, keccak256(creationCode)))))
        );
    }

    function deploy(
        address create2Factory,
        bytes32 salt,
        bytes memory creationCode
    )
        internal
        returns (address deployed)
    {
        deployed = computeAddress(create2Factory, salt, creationCode);

        if (deployed.code.length == 0) {
            (bool success,) = create2Factory.call(abi.encodePacked(salt, creationCode));
            if (!success || deployed.code.length == 0) revert DeploymentFailed(salt);
        }
    }
}

abstract contract ComptrollerDeploymentVerifier {
    error UnexpectedAdmin(address actual, address expected);
    error UnexpectedMinFeeUSD(ISablierComptroller.Protocol protocol, uint256 actual, uint256 expected);
    error UnexpectedOracle(address actual, address expected);
    error UnexpectedVersion(string actual, string expected);

    string internal constant EXPECTED_VERSION = "v1.1";

    event DeployComptroller(address indexed proxy, address indexed implementation);

    function _verifyState(
        address proxy,
        address initialAdmin,
        uint256 initialMinFeeUSD,
        address initialOracle
    )
        internal
        view
    {
        ISablierComptroller comptroller = ISablierComptroller(payable(proxy));
        string memory actualVersion = comptroller.VERSION();
        if (keccak256(bytes(actualVersion)) != keccak256(bytes(EXPECTED_VERSION))) {
            revert UnexpectedVersion({ actual: actualVersion, expected: EXPECTED_VERSION });
        }

        address actualAdmin = comptroller.admin();
        if (actualAdmin != initialAdmin) {
            revert UnexpectedAdmin({ actual: actualAdmin, expected: initialAdmin });
        }

        address actualOracle = address(comptroller.oracle());
        if (actualOracle != initialOracle) {
            revert UnexpectedOracle({ actual: actualOracle, expected: initialOracle });
        }

        _verifyMinFeeUSD(comptroller, ISablierComptroller.Protocol.Airdrops, initialMinFeeUSD);
        _verifyMinFeeUSD(comptroller, ISablierComptroller.Protocol.Bob, initialMinFeeUSD);
        _verifyMinFeeUSD(comptroller, ISablierComptroller.Protocol.Flow, initialMinFeeUSD);
        _verifyMinFeeUSD(comptroller, ISablierComptroller.Protocol.Lockup, initialMinFeeUSD);
    }

    function _verifyMinFeeUSD(
        ISablierComptroller comptroller,
        ISablierComptroller.Protocol protocol,
        uint256 expected
    )
        private
        view
    {
        uint256 actual = comptroller.getMinFeeUSD(protocol);
        if (actual != expected) {
            revert UnexpectedMinFeeUSD({ protocol: protocol, actual: actual, expected: expected });
        }
    }
}

/// @notice Deploys and initializes a Comptroller implementation and proxy within this contract's creation transaction.
/// @dev The proxy creation code must contain non-empty initialization calldata that binds the intended admin.
/// Otherwise, a third party could copy the CREATE2 deployment before this transaction and initialize the proxy
/// themselves.
contract AtomicComptrollerDeployer is ComptrollerDeploymentVerifier {
    struct Params {
        address create2Factory;
        bytes32 implementationSalt;
        bytes implementationCreationCode;
        bytes32 proxySalt;
        bytes proxyCreationCode;
        address initialAdmin;
        uint256 initialMinFeeUSD;
        address initialOracle;
    }

    constructor(Params memory params) {
        address implementation = Create2Utils.deploy({
            create2Factory: params.create2Factory,
            salt: params.implementationSalt,
            creationCode: params.implementationCreationCode
        });
        address proxy = Create2Utils.deploy({
            create2Factory: params.create2Factory,
            salt: params.proxySalt,
            creationCode: params.proxyCreationCode
        });

        _verifyState(proxy, params.initialAdmin, params.initialMinFeeUSD, params.initialOracle);

        emit DeployComptroller({ proxy: proxy, implementation: implementation });
    }
}

/// @notice Atomically bootstraps the legacy vanity proxy and upgrades it to the current Comptroller implementation.
/// @dev The legacy proxy creation code has empty initialization calldata. Combining the steps in one transaction
/// removes the initialization gap within that transaction, but cannot prevent a third party from predeploying and
/// initializing the public CREATE2 payload first.
contract VanityComptrollerDeployer is ComptrollerDeploymentVerifier {
    struct Params {
        address create2Factory;
        bytes32 legacyImplementationSalt;
        bytes legacyImplementationCreationCode;
        address expectedLegacyImplementation;
        bytes32 proxySalt;
        bytes proxyCreationCode;
        address expectedProxy;
        bytes32 implementationSalt;
        bytes implementationCreationCode;
        address expectedImplementation;
        address initialAdmin;
        uint256 initialMinFeeUSD;
        address initialOracle;
    }

    error ProxyAlreadyDeployed(address proxy);
    error UnexpectedAddress(address actual, address expected);

    constructor(Params memory params) {
        if (params.expectedProxy.code.length != 0) revert ProxyAlreadyDeployed(params.expectedProxy);

        address legacyImplementation = Create2Utils.deploy({
            create2Factory: params.create2Factory,
            salt: params.legacyImplementationSalt,
            creationCode: params.legacyImplementationCreationCode
        });
        _requireExpectedAddress(legacyImplementation, params.expectedLegacyImplementation);

        address proxy = Create2Utils.deploy({
            create2Factory: params.create2Factory,
            salt: params.proxySalt,
            creationCode: params.proxyCreationCode
        });
        _requireExpectedAddress(proxy, params.expectedProxy);

        ISablierComptrollerV10 legacyComptroller = ISablierComptrollerV10(proxy);
        legacyComptroller.initialize({
            initialAdmin: address(this),
            initialAirdropMinFeeUSD: params.initialMinFeeUSD,
            initialFlowMinFeeUSD: params.initialMinFeeUSD,
            initialLockupMinFeeUSD: params.initialMinFeeUSD,
            initialOracle: params.initialOracle
        });

        address implementation = Create2Utils.deploy({
            create2Factory: params.create2Factory,
            salt: params.implementationSalt,
            creationCode: params.implementationCreationCode
        });
        _requireExpectedAddress(implementation, params.expectedImplementation);

        UUPSUpgradeable(payable(proxy)).upgradeToAndCall(implementation, "");
        SablierComptroller(payable(proxy)).transferAdmin(params.initialAdmin);

        _verifyState(proxy, params.initialAdmin, params.initialMinFeeUSD, params.initialOracle);
        emit DeployComptroller({ proxy: proxy, implementation: implementation });
    }

    function _requireExpectedAddress(address actual, address expected) private pure {
        if (actual != expected) revert UnexpectedAddress({ actual: actual, expected: expected });
    }
}

/// @notice Deploys a non-deterministic Comptroller implementation and initialized proxy in one transaction.
contract NonDeterministicComptrollerDeployer is ComptrollerDeploymentVerifier {
    address public immutable IMPLEMENTATION;
    address public immutable PROXY;

    constructor(address initialAdmin, uint256 initialMinFeeUSD, address initialOracle) {
        IMPLEMENTATION = address(new SablierComptroller({ initialAdmin: initialAdmin }));
        bytes memory initializer = abi.encodeCall(
            SablierComptroller.initialize,
            (initialAdmin, initialMinFeeUSD, initialMinFeeUSD, initialMinFeeUSD, initialMinFeeUSD, initialOracle)
        );
        PROXY = address(new ERC1967Proxy({ implementation: IMPLEMENTATION, _data: initializer }));

        _verifyState(PROXY, initialAdmin, initialMinFeeUSD, initialOracle);
        emit DeployComptroller({ proxy: PROXY, implementation: IMPLEMENTATION });
    }
}
