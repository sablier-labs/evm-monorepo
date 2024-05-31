// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Deposit_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.deposit, (defaultStreamId, DEPOSIT_AMOUNT));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        bytes memory callData = abi.encodeCall(flow.deposit, (nullStreamId, DEPOSIT_AMOUNT));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_DepositAmountZero() external whenNotDelegateCalled givenNotNull givenNotPaused {
        vm.expectRevert(Errors.SablierFlow_DepositAmountZero.selector);
        flow.deposit(defaultStreamId, 0);
    }

    function test_Deposit_Paused() external whenNotDelegateCalled givenNotNull {
        flow.deposit(defaultStreamId, DEPOSIT_AMOUNT);

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_Deposit_AssetMissingReturnValue_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenDepositAmountNonZero
    {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        test_Deposit(streamId, IERC20(address(usdt)));
    }

    function test_Deposit() external whenNotDelegateCalled givenNotNull givenNotPaused whenDepositAmountNonZero {
        test_Deposit(defaultStreamId, dai);
    }

    function test_Deposit(uint256 streamId, IERC20 asset) internal {
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: users.sender,
            to: address(flow),
            value: normalizeAmountWithStreamId(streamId, DEPOSIT_AMOUNT)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: users.sender, asset: asset, depositAmount: DEPOSIT_AMOUNT });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        expectCallToTransferFrom({
            asset: asset,
            from: users.sender,
            to: address(flow),
            amount: normalizeAmountWithStreamId(streamId, DEPOSIT_AMOUNT)
        });
        flow.deposit(streamId, DEPOSIT_AMOUNT);

        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
