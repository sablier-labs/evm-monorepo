// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { stdError } from "forge-std/src/StdError.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ComptrollerManagerMock } from "src/mocks/ComptrollerManagerMock.sol";

import { TargetPanic } from "./targets/TargetPanic.sol";
import { TargetReverter } from "./targets/TargetReverter.sol";
import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract Execute_Concrete_Test is SablierComptroller_Concrete_Test {
    struct Targets {
        ComptrollerManagerMock comptrollerManager;
        TargetPanic panic;
        TargetReverter reverter;
    }

    bytes internal data;
    Targets internal targets;

    function setUp() public override {
        SablierComptroller_Concrete_Test.setUp();

        // Create the targets.
        targets = Targets({
            comptrollerManager: comptrollerManager,
            panic: new TargetPanic(),
            reverter: new TargetReverter()
        });

        // Declare the data to change the admin.
        data = abi.encodeCall(comptrollerManager.setComptroller, (comptrollerZero));
    }

    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        comptroller.execute({ target: address(comptrollerManager), data: data });
    }

    function test_RevertWhen_TargetNotContract() external whenCallerAdmin {
        comptroller.execute({ target: address(0), data: data });
    }

    function test_WhenCallPanics() external whenCallerAdmin whenTargetContract whenCallReverts {
        // It should panic due to a failed assertion.
        data = bytes.concat(targets.panic.failedAssertion.selector);
        vm.expectRevert(stdError.assertionError);
        comptroller.execute(address(targets.panic), data);

        // It should panic due to an arithmetic overflow.
        data = bytes.concat(targets.panic.arithmeticOverflow.selector);
        vm.expectRevert(stdError.arithmeticError);
        comptroller.execute(address(targets.panic), data);

        // It should panic due to a division by zero.
        data = bytes.concat(targets.panic.divisionByZero.selector);
        vm.expectRevert(stdError.divisionError);
        comptroller.execute(address(targets.panic), data);

        // It should panic due to an index out of bounds.
        data = bytes.concat(targets.panic.indexOOB.selector);
        vm.expectRevert(stdError.indexOOBError);
        comptroller.execute(address(targets.panic), data);
    }

    function test_WhenCallRevertsSilently() external whenCallerAdmin whenTargetContract whenCallReverts {
        // It should revert with an empty revert statement.
        data = bytes.concat(targets.reverter.withNothing.selector);
        vm.expectRevert(Errors.SablierComptroller_ExecutionFailedSilently.selector);
        comptroller.execute(address(targets.reverter), data);

        // It should revert with a custom error.
        data = bytes.concat(targets.reverter.withCustomError.selector);
        vm.expectRevert(TargetReverter.SomeError.selector);
        comptroller.execute(address(targets.reverter), data);

        // It should revert with a require.
        data = bytes.concat(targets.reverter.withRequire.selector);
        vm.expectRevert("You shall not pass");
        comptroller.execute(address(targets.reverter), data);

        // It should revert with a reason string.
        data = bytes.concat(targets.reverter.withReasonString.selector);
        vm.expectRevert("You shall not pass");
        comptroller.execute(address(targets.reverter), data);
    }

    function test_WhenCallDoesNotRevert() external whenCallerAdmin whenTargetContract {
        // It should emit an {Execute} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.Execute({ target: address(comptrollerManager), data: data, result: "" });

        comptroller.execute({ target: address(targets.comptrollerManager), data: data });

        // It should execute the call.
        assertEq(
            address(comptrollerManager.comptroller()),
            address(comptrollerZero),
            "The new comptroller should be set to the comptroller zero"
        );
    }
}
