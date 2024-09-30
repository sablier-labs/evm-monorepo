// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierFlowBase } from "src/interfaces/ISablierFlowBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../Integration.t.sol";

contract Recover_Integration_Concrete_Test is Integration_Test {
    uint256 internal surplusAmount = 1e6;

    function setUp() public override {
        Integration_Test.setUp();

        // Increase the flow contract balance in order to have a surplus.
        deal({ token: address(usdc), to: address(flow), give: surplusAmount });
    }

    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        flow.recover(usdc, users.eve);
    }

    function test_RevertWhen_TokenBalanceNotExceedAggregateAmount() external whenCallerAdmin {
        // Using dai token for this test because it has zero surplus.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlowBase_SurplusZero.selector, dai));
        flow.recover(dai, users.admin);
    }

    function test_WhenTokenBalanceExceedAggregateAmount() external whenCallerAdmin {
        assertEq(usdc.balanceOf(address(flow)), surplusAmount + flow.aggregateBalance(usdc));

        // It should emit {Recover} and {Transfer} events.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.admin, value: surplusAmount });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.Recover(users.admin, usdc, users.admin, surplusAmount);

        // Recover the surplus.
        flow.recover(usdc, users.admin);

        // It should lead to token balance same as aggregate amount.
        assertEq(usdc.balanceOf(address(flow)), flow.aggregateBalance(usdc));
    }
}
