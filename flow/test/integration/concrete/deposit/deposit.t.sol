// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Deposit_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.deposit, (defaultStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.deposit, (nullStreamId, DEPOSIT_AMOUNT_6D));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_DepositAmountZero() external whenNoDelegateCall givenNotNull {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_DepositAmountZero.selector, defaultStreamId));
        flow.deposit(defaultStreamId, 0);
    }

    function test_WhenTokenMissesERC20Return() external whenNoDelegateCall givenNotNull whenDepositAmountNotZero {
        uint256 streamId = createDefaultStream(IERC20(address(usdt)));

        // It should make the deposit
        _test_Deposit({ streamId: streamId, token: IERC20(address(usdt)), depositAmount: DEPOSIT_AMOUNT_6D });
    }

    function test_GivenTokenHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenDepositAmountNotZero
        whenTokenDoesNotMissERC20Return
    {
        // It should make the deposit.
        uint256 streamId = createDefaultStream(IERC20(address(dai)));
        _test_Deposit({ streamId: streamId, token: dai, depositAmount: DEPOSIT_AMOUNT_18D });
    }

    function test_GivenTokenDoesNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenDepositAmountNotZero
        whenTokenDoesNotMissERC20Return
    {
        // It should make the deposit.
        _test_Deposit({ streamId: defaultStreamId, token: usdc, depositAmount: DEPOSIT_AMOUNT_6D });
    }

    function _test_Deposit(uint256 streamId, IERC20 token, uint128 depositAmount) private {
        // It should emit 1 {Transfer}, 1 {DepositFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: depositAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: users.sender, amount: depositAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: token, from: users.sender, to: address(flow), amount: depositAmount });
        flow.deposit({ streamId: streamId, amount: depositAmount });

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = depositAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
