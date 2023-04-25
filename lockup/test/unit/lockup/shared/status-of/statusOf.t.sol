// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract StatusOf_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_StatusOf_Null() external {
        uint256 nullStreamId = 1729;
        Lockup.Status actualStatus = lockup.statusOf(nullStreamId);
        Lockup.Status expectedStatus = Lockup.Status.NULL;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStreamExists() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_StatusOf_Depleted() external whenStreamExists {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenAssetsNotFullyWithdrawn() {
        _;
    }

    function test_StatusOf_Canceled() external whenStreamExists whenAssetsNotFullyWithdrawn {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStreamNotCanceled() {
        _;
    }

    function test_StatusOf_Pending() external whenStreamExists whenAssetsNotFullyWithdrawn whenStreamNotCanceled {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    function test_StatusOf_Settled()
        external
        whenStreamExists
        whenAssetsNotFullyWithdrawn
        whenStreamNotCanceled
        whenStartTimeInThePast
    {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.SETTLED;
        assertEq(actualStatus, expectedStatus);
    }

    modifier whenRefundableAmountNotZero() {
        _;
    }

    function test_StatusOf_Streaming()
        external
        whenStreamExists
        whenAssetsNotFullyWithdrawn
        whenStreamNotCanceled
        whenStartTimeInThePast
        whenRefundableAmountNotZero
    {
        vm.warp({ timestamp: DEFAULT_START_TIME + 1 seconds });
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);
    }
}
