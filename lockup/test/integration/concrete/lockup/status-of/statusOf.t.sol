// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract StatusOf_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.statusOf(nullStreamId);
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_StatusOf_AssetsFullyWithdrawn() external whenNotNull {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenAssetsNotFullyWithdrawn() {
        _;
    }

    function test_StatusOf_StreamCanceled() external whenNotNull whenAssetsNotFullyWithdrawn {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStreamNotCanceled() {
        _;
    }

    function test_StatusOf_StartTimeInTheFuture()
        external
        whenNotNull
        whenAssetsNotFullyWithdrawn
        whenStreamNotCanceled
    {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStartTimeNotInTheFuture() {
        _;
    }

    function test_StatusOf_RefundableAmountNotZero()
        external
        whenNotNull
        whenAssetsNotFullyWithdrawn
        whenStreamNotCanceled
        whenStartTimeNotInTheFuture
    {
        vm.warp({ timestamp: defaults.END_TIME() });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.SETTLED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRefundableAmountNotZero() {
        _;
    }

    function test_StatusOf()
        external
        whenNotNull
        whenAssetsNotFullyWithdrawn
        whenStreamNotCanceled
        whenStartTimeNotInTheFuture
        whenRefundableAmountNotZero
    {
        vm.warp({ timestamp: defaults.START_TIME() + 1 seconds });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);
    }
}
