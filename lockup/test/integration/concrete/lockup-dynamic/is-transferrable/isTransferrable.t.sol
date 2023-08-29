// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { LockupDynamic_Integration_Concrete_Test } from "../LockupDynamic.t.sol";

contract IsTransferrable_LockupDynamic_Integration_Concrete_Test is LockupDynamic_Integration_Concrete_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        LockupDynamic_Integration_Concrete_Test.setUp();
        defaultStreamId = createDefaultStream();
    }

    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockupDynamic.isTransferrable(nullStreamId);
    }

    modifier givenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_RevertGiven_StreamTransferNotEnabled() external givenNotNull {
        uint256 noTransferStreamId = createDefaultStreamWithTransferDisabled();
        bool isTransferrable = lockupDynamic.isTransferrable(noTransferStreamId);
        assertFalse(isTransferrable, "isTransferrable");
    }

    modifier givenStreamTransferEnabled() {
        _;
    }

    function test_IsTransferrable_Stream() external givenNotNull givenStreamTransferEnabled {
        bool isTransferrable = lockupDynamic.isTransferrable(defaultStreamId);
        assertTrue(isTransferrable, "isTransferrable");
    }
}
