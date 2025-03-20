// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { Noop } from "@sablier/evm-utils/src/mocks/Noop.sol";

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { ChainlinkOracleMock } from "tests/utils/ChainlinkMocks.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetOracle_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setOracle(address(0));
    }

    function test_WhenNewOracleZero() external whenCallerAdmin {
        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetOracle(users.admin, address(0), address(oracle));
        merkleFactoryBase.setOracle(address(0));

        // It should set the oracle to zero.
        assertEq(merkleFactoryBase.oracle(), address(0), "oracle after");
    }

    function test_RevertWhen_NewOracleWithoutImplementation() external whenCallerAdmin whenNewOracleNotZero {
        Noop noop = new Noop();

        // It should revert.
        vm.expectRevert();
        merkleFactoryBase.setOracle(address(noop));
    }

    function test_WhenNewOracleWithImplementation() external whenCallerAdmin whenNewOracleNotZero {
        ChainlinkOracleMock newOracleWithImpl = new ChainlinkOracleMock();

        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetOracle(users.admin, address(newOracleWithImpl), address(oracle));
        merkleFactoryBase.setOracle(address(newOracleWithImpl));

        // It should set the oracle.
        assertEq(merkleFactoryBase.oracle(), address(newOracleWithImpl), "oracle after");
    }
}
