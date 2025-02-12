// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract TransferFrom_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    function testFuzz_TransferFrom(address caller, address to, uint128 amount) external whenNoDelegateCall {
        vm.assume(caller != address(0) && to != address(0) && caller != to);

        // Change the caller and fund him with some tokens.
        deal({ token: address(dai), to: caller, give: amount });
        resetPrank(caller);

        // Approve the flow contract to spend dai.
        dai.approve(address(flow), amount);

        uint256 beforeCallerBalance = dai.balanceOf(caller);
        uint256 beforeToBalance = dai.balanceOf(to);

        // Transfer amount to the provided address.
        flow.transferFrom(dai, to, amount);

        // It should update the balances.
        assertEq(dai.balanceOf(caller), beforeCallerBalance - amount, "caller token balance");
        assertEq(dai.balanceOf(to), beforeToBalance + amount, "recipient token balance");
    }
}
