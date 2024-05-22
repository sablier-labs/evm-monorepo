// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../Base.t.sol";

abstract contract Integration_Test is Base_Test {
    uint256 internal defaultStreamId;
    uint256 internal nullStreamId = 420;

    function setUp() public virtual override {
        Base_Test.setUp();

        defaultStreamId = createDefaultStream();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStream() internal returns (uint256) {
        return createDefaultStreamWithAsset(dai);
    }

    function createDefaultStreamWithAsset(IERC20 asset_) internal returns (uint256) {
        return openEnded.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: asset_,
            isTransferable: IS_TRANFERABLE
        });
    }

    function defaultDeposit() internal {
        defaultDeposit(defaultStreamId);
    }

    function defaultDeposit(uint256 streamId) internal {
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    function expectRevertDueToDelegateCall(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(openEnded).delegatecall(callData);
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }

    function expectRevertNull() internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
    }

    function expectRevertCanceled() internal {
        openEnded.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_StreamCanceled.selector, defaultStreamId));
    }
}
