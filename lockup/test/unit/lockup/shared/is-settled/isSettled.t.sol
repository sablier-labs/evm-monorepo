// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract IsSettled_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.isSettled(nullStreamId);
    }

    function test_IsSettled_StreamDepleted() external {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isSettled = lockup.isSettled(defaultStreamId);
        assertTrue(isSettled, "isSettled");
    }

    function test_IsSettled_StreamCanceled() external {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        bool isSettled = lockup.isSettled(defaultStreamId);
        assertTrue(isSettled, "isSettled");
    }

    modifier whenStreamActive() {
        _;
    }

    function test_IsSettled_RefundableAmountNotZero() external whenStreamActive {
        bool isSettled = lockup.isSettled(defaultStreamId);
        assertFalse(isSettled, "isSettled");
    }

    function test_IsSettled_RefundableAmountZero() external whenStreamActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        bool isSettled = lockup.isSettled(defaultStreamId);
        assertTrue(isSettled, "isSettled");
    }
}
