// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Deposit_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.deposit, (defaultStreamId, TRANSFER_AMOUNT));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.deposit, (nullStreamId, TRANSFER_AMOUNT));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_TransferAmountZero() external whenNoDelegateCall givenNotNull {
        vm.expectRevert(Errors.SablierFlow_TransferAmountZero.selector);
        flow.deposit(defaultStreamId, 0);
    }

    function test_WhenAssetMissesERC20Return() external whenNoDelegateCall givenNotNull whenTransferAmountNotZero {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));

        // It should make the deposit
        _test_Deposit(streamId, IERC20(address(usdt)), TRANSFER_AMOUNT_6D, 6);
    }

    function test_GivenAssetDoesNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenTransferAmountNotZero
        whenAssetDoesNotMissERC20Return
    {
        // It should make the deposit.
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdc)));
        _test_Deposit(streamId, usdc, TRANSFER_AMOUNT_6D, 6);
    }

    function test_GivenAssetHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenTransferAmountNotZero
        whenAssetDoesNotMissERC20Return
    {
        // It should make the deposit.
        _test_Deposit(defaultStreamId, dai, TRANSFER_AMOUNT, 18);
    }

    function _test_Deposit(uint256 streamId, IERC20 asset, uint128 transferAmount, uint8 assetDecimals) private {
        uint128 normalizedAmount = getNormalizedAmount(transferAmount, assetDecimals);

        // It should emit 1 {Transfer}, 1 {DepositFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: users.sender, depositAmount: normalizedAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC20 transfer.
        expectCallToTransferFrom({ asset: asset, from: users.sender, to: address(flow), amount: transferAmount });
        flow.deposit(streamId, transferAmount);

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = normalizedAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
