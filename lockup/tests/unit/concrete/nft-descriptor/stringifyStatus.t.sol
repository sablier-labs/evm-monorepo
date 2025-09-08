// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/Lockup.sol";

import { Base_Test } from "tests/Base.t.sol";

contract StringifyStatus_Unit_Concrete_Test is Base_Test {
    function test_StringifyStatus() external view {
        assertEq(nftDescriptorMock.stringifyStatus_(Lockup.Status.DEPLETED), "Depleted", "depleted status mismatch");
        assertEq(nftDescriptorMock.stringifyStatus_(Lockup.Status.CANCELED), "Canceled", "canceled status mismatch");
        assertEq(nftDescriptorMock.stringifyStatus_(Lockup.Status.STREAMING), "Streaming", "streaming status mismatch");
        assertEq(nftDescriptorMock.stringifyStatus_(Lockup.Status.SETTLED), "Settled", "settled status mismatch");
        assertEq(nftDescriptorMock.stringifyStatus_(Lockup.Status.PENDING), "Pending", "pending status mismatch");
    }
}
