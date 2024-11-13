// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetAsset_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getAsset(nullStreamId);
    }

    function test_GivenNotNull() external view {
        IERC20 actualAsset = lockup.getAsset(defaultStreamId);
        IERC20 expectedAsset = dai;
        assertEq(actualAsset, expectedAsset, "asset");
    }
}
