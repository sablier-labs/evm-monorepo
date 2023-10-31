// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Deposit_Integration_Test is Integration_Test {
    uint256 internal streamId;

    function setUp() public override {
        Integration_Test.setUp();

        streamId = createDefaultStream();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2OpenEnded.create, (users.sender, users.recipient, AMOUNT_PER_SECOND, dai));
        (bool success, bytes memory returnData) = address(openEnded).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 888_888;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.deposit(nullStreamId, DEPOSIT_AMOUNT);
    }

    modifier givenNotNull() {
        _;
    }

    function test_RevertGiven_Canceled() external whenNotDelegateCalled givenNotNull {
        openEnded.cancel(streamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_StreamCanceled.selector, streamId));
        openEnded.deposit(streamId, DEPOSIT_AMOUNT);
    }

    modifier givenNotCanceled() {
        _;
    }

    function test_RevertWhen_DepositAmountZero() external whenNotDelegateCalled givenNotNull givenNotCanceled {
        vm.expectRevert(Errors.SablierV2OpenEnded_DepositAmountZero.selector);
        openEnded.deposit(streamId, 0);
    }

    modifier whenDepositAmountNonZero() {
        _;
    }

    function test_Deposit_AssetMissingReturnValue()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenDepositAmountNonZero
    {
        streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        test_Deposit(streamId, IERC20(address(usdt)));
    }

    function test_Deposit_Not18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotCanceled
        whenDepositAmountNonZero
    {
        streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        test_Deposit(streamId, IERC20(address(usdt)));
    }

    function test_Deposit() external whenNotDelegateCalled givenNotNull givenNotCanceled whenDepositAmountNonZero {
        test_Deposit(streamId, dai);
    }

    function test_Deposit(uint256 streamId_, IERC20 asset) internal {
        vm.expectEmit({ emitter: address(asset) });
        emit Transfer({
            from: users.sender,
            to: address(openEnded),
            value: normalizeToAssetDecimals(streamId_, DEPOSIT_AMOUNT)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit DepositOpenEndedStream({ streamId: streamId_, funder: users.sender, asset: asset, amount: DEPOSIT_AMOUNT });

        expectCallToTransferFrom({
            asset: asset,
            from: users.sender,
            to: address(openEnded),
            amount: normalizeToAssetDecimals(streamId_, DEPOSIT_AMOUNT)
        });
        openEnded.deposit(streamId_, DEPOSIT_AMOUNT);

        uint128 actualStreamBalance = openEnded.getBalance(streamId_);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
