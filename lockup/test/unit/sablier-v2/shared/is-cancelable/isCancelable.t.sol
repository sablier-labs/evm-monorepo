// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SharedTest } from "../SharedTest.t.sol";

abstract contract IsCancelable_Test is SharedTest {
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
        bool isCancelable = sablierV2.isCancelable(nullStreamId);
        assertFalse(isCancelable);
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamCanceled() external streamNotActive {
        sablierV2.cancel(defaultStreamId);
        bool isCancelable = sablierV2.isCancelable(defaultStreamId);
        assertFalse(isCancelable);
    }

    /// @dev it should return false.
    function test_IsCancelable_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        sablierV2.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        bool isCancelable = sablierV2.isCancelable(defaultStreamId);
        assertFalse(isCancelable);
    }

    modifier streamActive() {
        _;
    }

    /// @dev it should return true.
    function test_IsCancelable_CancelableStream() external streamActive {
        bool isCancelable = sablierV2.isCancelable(defaultStreamId);
        assertTrue(isCancelable);
    }

    modifier nonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function test_IsCancelable() external streamActive nonCancelableStream {
        uint256 streamId = createDefaultStreamNonCancelable();
        bool isCancelable = sablierV2.isCancelable(streamId);
        assertFalse(isCancelable);
    }
}
