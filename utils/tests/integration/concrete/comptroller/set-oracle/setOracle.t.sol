// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ChainlinkOracleMock } from "src/mocks/ChainlinkMocks.sol";
import { Noop } from "src/mocks/Noop.sol";

import { Base_Test } from "tests/Base.t.sol";

contract SetOracle_Comptroller_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.accountant);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.accountant));
        comptroller.setOracle(address(0));
    }

    function test_WhenNewOracleZero() external whenCallerAdmin {
        address previousOracle = comptroller.oracle();

        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetOracle(admin, previousOracle, address(0));

        // Set the oracle to zero.
        comptroller.setOracle(address(0));

        // It should set the oracle to zero.
        assertEq(comptroller.oracle(), address(0), "oracle after");
    }

    function test_RevertWhen_NewOracleWithoutImplementation() external whenCallerAdmin whenNewOracleNotZero {
        Noop noop = new Noop();

        // It should revert.
        vm.expectRevert();
        comptroller.setOracle(address(noop));
    }

    function test_WhenNewOracleWithImplementation() external whenCallerAdmin whenNewOracleNotZero {
        ChainlinkOracleMock newOracleWithImpl = new ChainlinkOracleMock();
        address previousOracle = comptroller.oracle();

        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetOracle(admin, previousOracle, address(newOracleWithImpl));

        // Set the oracle to the new oracle.
        comptroller.setOracle(address(newOracleWithImpl));

        // It should set the oracle.
        assertEq(comptroller.oracle(), address(newOracleWithImpl), "oracle after");
    }
}
