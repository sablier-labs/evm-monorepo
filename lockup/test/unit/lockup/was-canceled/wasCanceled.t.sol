// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract WasCanceled_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.wasCanceled(nullStreamId);
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_WasCanceled_StreamNotCanceled() external whenNotNull {
        bool wasCanceled = lockup.wasCanceled(defaultStreamId);
        assertFalse(wasCanceled, "wasCanceled");
    }

    modifier whenStreamCanceled() {
        lockup.cancel(defaultStreamId);
        _;
    }

    function test_WasCanceled() external whenNotNull whenStreamCanceled {
        bool wasCanceled = lockup.wasCanceled(defaultStreamId);
        assertTrue(wasCanceled, "wasCanceled");
    }
}
