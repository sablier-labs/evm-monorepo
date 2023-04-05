// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetReturnedAmount_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.getReturnedAmount(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return zero.
    function test_GetReturnedAmount_StreamActive() external whenStreamNonNull {
        uint128 actualReturnedAmount = lockup.getReturnedAmount(streamId);
        uint128 expectedReturnedAmount = 0;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "returnedAmount");
    }

    /// @dev it should return zero.
    function test_GetReturnedAmount_StreamDepleted() external whenStreamNonNull {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        uint128 actualReturnedAmount = lockup.getReturnedAmount(streamId);
        uint128 expectedReturnedAmount = 0;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "returnedAmount");
    }

    /// @dev it should return the returned amount.
    function test_GetReturnedAmount_StreamCanceled() external whenStreamNonNull {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(streamId);
        uint128 actualReturnedAmount = lockup.getReturnedAmount(streamId);
        uint128 expectedReturnedAmount = DEFAULT_RETURNED_AMOUNT;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "returnedAmount");
    }
}
