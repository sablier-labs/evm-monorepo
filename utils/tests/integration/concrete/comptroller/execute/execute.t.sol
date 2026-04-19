// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { stdError } from "forge-std/src/StdError.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";
import { ComptrollerableMock } from "../../../../mocks/ComptrollerableMock.sol";
import { PanicContractMock } from "../../../../mocks/PanicContractMock.sol";
import { RevertingContractMock } from "../../../../mocks/RevertingContractMock.sol";

contract Execute_Integration_Concrete_Test is Base_Test {
    struct Targets {
        ComptrollerableMock comptrollerableMock;
        PanicContractMock panic;
        RevertingContractMock reverter;
    }

    ISablierComptroller internal newComptroller;
    bytes internal setComptrollerPayload;
    Targets internal targets;

    function setUp() public override {
        Base_Test.setUp();

        // Create the targets.
        targets = Targets({
            comptrollerableMock: comptrollerableMock,
            panic: new PanicContractMock(),
            reverter: new RevertingContractMock()
        });

        // Deploy a new comptroller.
        newComptroller = new SablierComptroller(admin);

        // Encode set comptroller function call.
        setComptrollerPayload = abi.encodeCall(comptrollerableMock.setComptroller, (newComptroller));
    }

    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        comptroller.execute({ target: address(comptrollerableMock), targetCallData: setComptrollerPayload });
    }

    function test_RevertWhen_TargetNotContract() external whenCallerAdmin {
        comptroller.execute({ target: address(0), targetCallData: setComptrollerPayload });
    }

    function test_WhenCallPanics() external whenCallerAdmin whenTargetContract whenCallReverts {
        // It should panic due to a failed assertion.
        bytes memory revertingPayload = bytes.concat(targets.panic.failedAssertion.selector);
        vm.expectRevert(stdError.assertionError);
        comptroller.execute({ target: address(targets.panic), targetCallData: revertingPayload });

        // It should panic due to an arithmetic overflow.
        revertingPayload = bytes.concat(targets.panic.arithmeticOverflow.selector);
        vm.expectRevert(stdError.arithmeticError);
        comptroller.execute({ target: address(targets.panic), targetCallData: revertingPayload });

        // It should panic due to a division by zero.
        revertingPayload = bytes.concat(targets.panic.divisionByZero.selector);
        vm.expectRevert(stdError.divisionError);
        comptroller.execute({ target: address(targets.panic), targetCallData: revertingPayload });

        // It should panic due to an index out of bounds.
        revertingPayload = bytes.concat(targets.panic.indexOOB.selector);
        vm.expectRevert(stdError.indexOOBError);
        comptroller.execute({ target: address(targets.panic), targetCallData: revertingPayload });
    }

    function test_WhenCallRevertsSilently() external whenCallerAdmin whenTargetContract whenCallReverts {
        // It should revert with an empty revert statement.
        bytes memory revertingPayload = bytes.concat(targets.reverter.withNothing.selector);
        vm.expectRevert(Errors.SablierComptroller_ExecutionFailedSilently.selector);
        comptroller.execute({ target: address(targets.reverter), targetCallData: revertingPayload });

        // It should revert with a custom error.
        revertingPayload = bytes.concat(targets.reverter.withCustomError.selector);
        vm.expectRevert(RevertingContractMock.SomeError.selector);
        comptroller.execute(address(targets.reverter), revertingPayload);

        // It should revert with a require.
        revertingPayload = bytes.concat(targets.reverter.withRequire.selector);
        vm.expectRevert("You shall not pass");
        comptroller.execute({ target: address(targets.reverter), targetCallData: revertingPayload });

        // It should revert with a reason string.
        revertingPayload = bytes.concat(targets.reverter.withReasonString.selector);
        vm.expectRevert("You shall not pass");
        comptroller.execute({ target: address(targets.reverter), targetCallData: revertingPayload });
    }

    function test_WhenCallDoesNotRevert() external whenCallerAdmin whenTargetContract {
        // It should emit an {Execute} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.Execute({
            target: address(comptrollerableMock),
            targetCallData: setComptrollerPayload,
            result: ""
        });

        comptroller.execute({ target: address(targets.comptrollerableMock), targetCallData: setComptrollerPayload });

        // It should execute the call.
        assertEq(
            address(comptrollerableMock.comptroller()), address(newComptroller), "The new comptroller should be set"
        );
    }
}
