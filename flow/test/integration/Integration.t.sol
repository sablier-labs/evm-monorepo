// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";

abstract contract Integration_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    function createDefaultStream() internal returns (uint256) {
        return createDefaultStreamWithAsset(dai);
    }

    function createDefaultStreamWithAsset(IERC20 asset_) internal returns (uint256) {
        return openEnded.create({
            sender: users.sender,
            recipient: users.recipient,
            amountPerSecond: AMOUNT_PER_SECOND,
            asset: asset_
        });
    }

    /// @dev Expects a delegate call error.
    function expectRevertDueToDelegateCall(bool success, bytes memory returnData) internal {
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }
}
