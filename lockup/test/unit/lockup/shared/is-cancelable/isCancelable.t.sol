// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract IsCancelable_Unit_Test is Shared_Lockup_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        super.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier streamNotActive() {
        _;
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamNull() external streamNotActive {
        uint256 nullStreamId = 1729;
        bool isCancelable = lockup.isCancelable(nullStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamCanceled() external streamNotActive {
        lockup.cancel(defaultStreamId);
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");
    }

    modifier streamActive() {
        _;
    }

    /// @dev it should return true.
    function test_IsCancelable_CancelableStream() external streamActive {
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertTrue(isCancelable, "isCancelable");
    }

    modifier nonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function test_IsCancelable() external streamActive nonCancelableStream {
        uint256 streamId = createDefaultStreamNonCancelable();
        bool isCancelable = lockup.isCancelable(streamId);
        assertFalse(isCancelable, "isCancelable");
    }
}
