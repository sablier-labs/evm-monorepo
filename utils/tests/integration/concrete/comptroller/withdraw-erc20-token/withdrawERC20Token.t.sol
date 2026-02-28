// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract WithdrawERC20Token_Comptroller_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        comptroller.withdrawERC20Token({ token: dai, to: users.eve });
    }

    function test_RevertWhen_RecipientZeroAddress() external whenCallerAdmin {
        vm.expectRevert(Errors.SablierComptroller_ToZeroAddress.selector);
        comptroller.withdrawERC20Token({ token: dai, to: address(0) });
    }

    function test_RevertGiven_TokenBalanceZero() external whenCallerAdmin whenRecipientNotZeroAddress {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierComptroller_TokenBalanceZero.selector, address(usdc)));
        comptroller.withdrawERC20Token({ token: usdc, to: users.accountant });
    }

    function test_GivenTokenBalanceNotZero()
        external
        whenCallerAdmin
        whenRecipientNotZeroAddress
        givenTokenBalanceNotZero
    {
        uint256 depositAmount = 1000e18;

        // Deal the comptroller with some tokens.
        deal({ token: address(dai), to: address(comptroller), give: depositAmount });

        uint256 previousBalance = dai.balanceOf(users.accountant);

        // It should emit a {WithdrawERC20Token} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.WithdrawERC20Token({
            admin: admin,
            token: dai,
            to: users.accountant,
            amount: depositAmount
        });

        // Withdraw the tokens.
        comptroller.withdrawERC20Token({ token: dai, to: users.accountant });

        // It should transfer the entire balance to the recipient.
        assertEq(dai.balanceOf(address(comptroller)), 0, "comptroller balance");
        assertEq(dai.balanceOf(users.accountant), previousBalance + depositAmount, "recipient balance");
    }
}
