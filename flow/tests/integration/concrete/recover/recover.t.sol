// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract Recover_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    uint256 internal surplusAmount = 1e6;

    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();

        // Increase the flow contract balance in order to have a surplus.
        deal({ token: address(usdc), to: address(flow), give: surplusAmount });
    }

    function test_RevertWhen_CallerNotComptroller() external {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.ComptrollerManager_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        flow.recover(usdc, users.eve);
    }

    function test_RevertWhen_TokenBalanceNotExceedAggregateAmount() external whenCallerComptroller {
        // Using dai token for this test because it has zero surplus.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_SurplusZero.selector, dai));
        flow.recover(dai, users.accountant);
    }

    function test_WhenTokenBalanceExceedAggregateAmount() external whenCallerComptroller {
        assertEq(usdc.balanceOf(address(flow)), surplusAmount + flow.aggregateAmount(usdc));

        // It should emit {Recover} and {Transfer} events.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.accountant, value: surplusAmount });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.Recover(comptroller, usdc, users.accountant, surplusAmount);

        // Recover the surplus.
        flow.recover(usdc, users.accountant);

        // It should lead to token balance same as aggregate amount.
        assertEq(usdc.balanceOf(address(flow)), flow.aggregateAmount(usdc));
    }
}
