// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { Noop } from "@sablier/evm-utils/src/mocks/Noop.sol";

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ChainlinkOracleMock } from "tests/utils/ChainlinkMocks.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetOracle_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        factoryMerkleBase.setOracle(address(0));
    }

    function test_WhenNewOracleZero() external whenCallerAdmin {
        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.SetOracle(users.admin, address(0), address(oracle));
        factoryMerkleBase.setOracle(address(0));

        // It should set the oracle to zero.
        assertEq(factoryMerkleBase.oracle(), address(0), "oracle after");
    }

    function test_RevertWhen_NewOracleWithoutImplementation() external whenCallerAdmin whenNewOracleNotZero {
        Noop noop = new Noop();

        // It should revert.
        vm.expectRevert();
        factoryMerkleBase.setOracle(address(noop));
    }

    function test_WhenNewOracleWithImplementation() external whenCallerAdmin whenNewOracleNotZero {
        ChainlinkOracleMock newOracleWithImpl = new ChainlinkOracleMock();

        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.SetOracle(users.admin, address(newOracleWithImpl), address(oracle));
        factoryMerkleBase.setOracle(address(newOracleWithImpl));

        // It should set the oracle.
        assertEq(factoryMerkleBase.oracle(), address(newOracleWithImpl), "oracle after");
    }
}
