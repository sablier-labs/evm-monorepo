// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract IsCancelable_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamNull() external whenStreamNotActive {
        uint256 nullStreamId = 1729;
        bool isCancelable = lockup.isCancelable(nullStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamCanceled() external whenStreamNotActive {
        lockup.cancel(defaultStreamId);
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamDepleted() external whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier whenStreamActive() {
        _;
    }

    /// @dev it should return true.
    function test_IsCancelable_CancelableStream() external whenStreamActive {
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertTrue(isCancelable, "isCancelable");
    }

    modifier whenStreamIsNonCancelable() {
        _;
    }

    /// @dev it should return false.
    function test_IsCancelable() external whenStreamActive whenStreamIsNonCancelable {
        uint256 streamId = createDefaultStreamNonCancelable();
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
