// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Helpers } from "src/libraries/Helpers.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Deposit_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.deposit, (defaultStreamId, TRANSFER_AMOUNT));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        bytes memory callData = abi.encodeCall(flow.deposit, (nullStreamId, TRANSFER_AMOUNT));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_DepositAmountZero() external whenNotDelegateCalled givenNotNull givenNotPaused {
        vm.expectRevert(Errors.SablierFlow_DepositAmountZero.selector);
        flow.deposit(defaultStreamId, 0);
    }

    function test_Deposit_Paused() external whenNotDelegateCalled givenNotNull {
        flow.deposit(defaultStreamId, TRANSFER_AMOUNT);

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = TRANSFER_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_Deposit_AssetMissingReturnValue()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenDepositAmountNonZero
    {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        _test_Deposit(streamId, IERC20(address(usdt)), TRANSFER_AMOUNT_6D, 6);
    }

    function test_Deposit_Asset18Decimals() external {
        _test_Deposit(defaultStreamId, dai, TRANSFER_AMOUNT, 18);
    }

    function test_Deposit_AssetLessThan18Decimals() external {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdc)));
        _test_Deposit(streamId, usdc, TRANSFER_AMOUNT_6D, 6);
    }

    function _test_Deposit(uint256 streamId, IERC20 asset, uint128 transferAmount, uint8 assetDecimals) internal {
        uint128 normalizedAmount = Helpers.calculateNormalizedAmount(transferAmount, assetDecimals);

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({
            streamId: streamId,
            funder: users.sender,
            asset: asset,
            depositAmount: normalizedAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        expectCallToTransferFrom({ asset: asset, from: users.sender, to: address(flow), amount: transferAmount });
        flow.deposit(streamId, transferAmount);

        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = normalizedAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
