// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { StdConstants, Vm } from "forge-std/src/StdConstants.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { ChainId } from "src/tests/ChainId.sol";
import { ValidateExistingComptroller } from "../../../../scripts/solidity/ValidateExistingComptroller.s.sol";

contract Run_Integration_Concrete_Test is StdAssertions {
    bytes4 internal constant EXPECTED_INTERFACE_ID = ISablierComptroller.calculateMinFeeWeiFor.selector
        ^ ISablierComptroller.convertUSDFeeToWei.selector ^ ISablierComptroller.execute.selector
        ^ ISablierComptroller.getMinFeeUSDFor.selector;
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    Vm internal vm = StdConstants.VM;

    function test_RevertGiven_ProxyNotDeployed() external {
        ValidateExistingComptroller validator = _deployValidator();
        address proxy = validator.getComptroller();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(ValidateExistingComptroller.ProxyNotDeployed.selector, proxy));
        validator.run();
    }

    function test_RevertGiven_ImplementationNotDeployed() external {
        ValidateExistingComptroller validator = _deployValidator();
        _etchComptroller({
            validator: validator,
            admin: validator.getAdmin(),
            oracle: validator.getChainlinkOracle(),
            minimalInterfaceId: EXPECTED_INTERFACE_ID,
            supportsMinimalInterface: true
        });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(ValidateExistingComptroller.ImplementationNotDeployed.selector, address(0))
        );
        validator.run();
    }

    function test_RevertGiven_UnexpectedAdmin() external {
        ValidateExistingComptroller validator = _deployValidator();
        address unexpectedAdmin = address(0xBAD);
        _etchComptroller({
            validator: validator,
            admin: unexpectedAdmin,
            oracle: validator.getChainlinkOracle(),
            minimalInterfaceId: EXPECTED_INTERFACE_ID,
            supportsMinimalInterface: true
        });
        _etchImplementation(validator.getComptroller());

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                ValidateExistingComptroller.UnexpectedAdmin.selector, unexpectedAdmin, validator.getAdmin()
            )
        );
        validator.run();
    }

    function test_RevertGiven_UnexpectedOracle() external {
        ValidateExistingComptroller validator = _deployValidator();
        address unexpectedOracle = address(0xBAD);
        _etchComptroller({
            validator: validator,
            admin: validator.getAdmin(),
            oracle: unexpectedOracle,
            minimalInterfaceId: EXPECTED_INTERFACE_ID,
            supportsMinimalInterface: true
        });
        _etchImplementation(validator.getComptroller());

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                ValidateExistingComptroller.UnexpectedOracle.selector, unexpectedOracle, validator.getChainlinkOracle()
            )
        );
        validator.run();
    }

    function test_RevertGiven_UnexpectedMinimalInterface() external {
        ValidateExistingComptroller validator = _deployValidator();
        bytes4 unexpectedInterfaceId = ~EXPECTED_INTERFACE_ID;
        _etchComptroller({
            validator: validator,
            admin: validator.getAdmin(),
            oracle: validator.getChainlinkOracle(),
            minimalInterfaceId: unexpectedInterfaceId,
            supportsMinimalInterface: true
        });
        _etchImplementation(validator.getComptroller());

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                ValidateExistingComptroller.UnexpectedInterface.selector, unexpectedInterfaceId, EXPECTED_INTERFACE_ID
            )
        );
        validator.run();
    }

    function test_RevertGiven_MinimalInterfaceUnsupported() external {
        ValidateExistingComptroller validator = _deployValidator();
        _etchComptroller({
            validator: validator,
            admin: validator.getAdmin(),
            oracle: validator.getChainlinkOracle(),
            minimalInterfaceId: EXPECTED_INTERFACE_ID,
            supportsMinimalInterface: false
        });
        _etchImplementation(validator.getComptroller());

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(ValidateExistingComptroller.UnsupportedInterface.selector, EXPECTED_INTERFACE_ID)
        );
        validator.run();
    }

    function test_GivenValidConfiguration() external {
        ValidateExistingComptroller validator = _deployValidator();
        address proxy = validator.getComptroller();
        _etchComptroller({
            validator: validator,
            admin: validator.getAdmin(),
            oracle: validator.getChainlinkOracle(),
            minimalInterfaceId: EXPECTED_INTERFACE_ID,
            supportsMinimalInterface: true
        });
        address implementation = _etchImplementation(proxy);

        // It should return the configured proxy and implementation.
        (address actualProxy, address actualImplementation) = validator.run();
        assertEq(actualProxy, proxy, "proxy");
        assertEq(actualImplementation, implementation, "implementation");
    }

    function _deployValidator() private returns (ValidateExistingComptroller validator) {
        vm.chainId(ChainId.ETHEREUM);
        validator = new ValidateExistingComptroller();
    }

    function _etchComptroller(
        ValidateExistingComptroller validator,
        address admin,
        address oracle,
        bytes4 minimalInterfaceId,
        bool supportsMinimalInterface
    )
        private
    {
        ExistingComptrollerMock mock =
            new ExistingComptrollerMock(admin, oracle, minimalInterfaceId, supportsMinimalInterface);
        vm.etch(validator.getComptroller(), address(mock).code);
    }

    function _etchImplementation(address proxy) private returns (address implementation) {
        implementation = address(new ComptrollerImplementationMock());
        vm.store(proxy, IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation))));
    }
}

contract ExistingComptrollerMock {
    address private immutable _ADMIN;
    bytes4 private immutable _MINIMAL_INTERFACE_ID;
    address private immutable _ORACLE;
    bool private immutable _SUPPORTS_MINIMAL_INTERFACE;

    constructor(address admin_, address oracle_, bytes4 minimalInterfaceId_, bool supportsMinimalInterface_) {
        _ADMIN = admin_;
        _MINIMAL_INTERFACE_ID = minimalInterfaceId_;
        _ORACLE = oracle_;
        _SUPPORTS_MINIMAL_INTERFACE = supportsMinimalInterface_;
    }

    function admin() external view returns (address) {
        return _ADMIN;
    }

    function oracle() external view returns (address) {
        return _ORACLE;
    }

    function MINIMAL_INTERFACE_ID() external view returns (bytes4) {
        return _MINIMAL_INTERFACE_ID;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _SUPPORTS_MINIMAL_INTERFACE && interfaceId == _MINIMAL_INTERFACE_ID;
    }
}

contract ComptrollerImplementationMock { }
