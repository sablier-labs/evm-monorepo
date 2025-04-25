// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Recover_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.recover(dai, users.eve);
    }

    function test_WhenCallerAdmin() external {
        setMsgSender(users.admin);

        uint256 surplusAmount = 1e18;

        // Increase the lockup contract balance in order to have a surplus.
        deal({ token: address(dai), to: address(lockup), give: dai.balanceOf(address(lockup)) + surplusAmount });

        // It should emit {Transfer} event.
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({ from: address(lockup), to: users.admin, value: surplusAmount });

        // Recover the surplus.
        lockup.recover(dai, users.admin);

        // It should lead to token balance same as aggregate amount.
        assertEq(dai.balanceOf(address(lockup)), lockup.aggregateAmount(dai));
    }
}
