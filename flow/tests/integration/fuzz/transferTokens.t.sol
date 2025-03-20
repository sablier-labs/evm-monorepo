// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract TransferTokens_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    function testFuzz_WhenTokenMissingReturnValue(
        address caller,
        address to,
        uint128 amount
    )
        external
        whenNoDelegateCall
    {
        // Cast the usdt to IERC20.
        IERC20 _usdt = IERC20(address(usdt));

        vm.assume(caller != address(0) && to != address(0) && caller != to);

        // Change the caller and fund him with some tokens.
        deal({ token: address(_usdt), to: caller, give: amount });
        resetPrank(caller);

        // Approve the flow contract to spend usdt.
        _usdt.approve(address(flow), amount);

        uint256 beforeCallerBalance = _usdt.balanceOf(caller);
        uint256 beforeToBalance = _usdt.balanceOf(to);

        expectCallToTransferFrom(_usdt, caller, to, amount);

        // Transfer amount to the provided address.
        flow.transferTokens(_usdt, to, amount);

        // It should update the balances.
        assertEq(_usdt.balanceOf(caller), beforeCallerBalance - amount, "caller token balance");
        assertEq(_usdt.balanceOf(to), beforeToBalance + amount, "recipient token balance");
    }

    function testFuzz_WhenTokenNotMissingReturnValue(
        address caller,
        address to,
        uint128 amount
    )
        external
        whenNoDelegateCall
    {
        vm.assume(caller != address(0) && to != address(0) && caller != to);

        // Change the caller and fund him with some tokens.
        deal({ token: address(usdc), to: caller, give: amount });
        resetPrank(caller);

        // Approve the flow contract to spend usdc.
        usdc.approve(address(flow), amount);

        uint256 beforeCallerBalance = usdc.balanceOf(caller);
        uint256 beforeToBalance = usdc.balanceOf(to);

        expectCallToTransferFrom({ token: usdc, from: caller, to: to, value: amount });

        // Transfer amount to the provided address.
        flow.transferTokens(usdc, to, amount);

        // It should update the balances.
        assertEq(usdc.balanceOf(caller), beforeCallerBalance - amount, "caller token balance");
        assertEq(usdc.balanceOf(to), beforeToBalance + amount, "recipient token balance");
    }
}
