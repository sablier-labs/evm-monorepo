// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsTransferrable_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.isTransferrable(nullStreamId);
    }

    modifier givenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_RevertGiven_StatusDepleted() external givenNotNull {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamId));
        lockup.toggleTransfer(defaultStreamId);
    }

    modifier givenStreamNotDepleted() {
        _;
    }

    function test_RevertGiven_StatusCanceled() external givenNotNull givenStreamNotDepleted {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamCanceled.selector, defaultStreamId));
        lockup.toggleTransfer(defaultStreamId);
    }

    modifier givenStreamNotCanceled() {
        _;
    }

    function test_RevertWhen_CallerUnauthorized() external givenNotNull givenStreamNotDepleted givenStreamNotCanceled {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.toggleTransfer(defaultStreamId);
    }

    modifier whenCallerAuthorized() {
        _;
    }

    function test_IsTransferrable_Stream()
        external
        givenNotNull
        givenStreamNotDepleted
        givenStreamNotCanceled
        whenCallerAuthorized
    {
        bool isTransferrable = lockup.isTransferrable(defaultStreamId);
        assertTrue(isTransferrable, "isTransferrable");
    }

    modifier givenStreamNotTransferrable() {
        _;
    }

    function test_IsTransferrable_StreamNotTransferrable()
        external
        givenNotNull
        givenStreamNotDepleted
        givenStreamNotCanceled
        whenCallerAuthorized
        givenStreamNotTransferrable
    {
        lockup.toggleTransfer(defaultStreamId);
        bool isTransferrable = lockup.isTransferrable(defaultStreamId);
        assertFalse(isTransferrable, "isTransferrable");
    }
}
