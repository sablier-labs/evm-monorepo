// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IComptrollerManager } from "src/interfaces/IComptrollerManager.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract TransferFeesToComptroller_Lockup_Integration_Concrete_Test is Base_Test {
    function test_GivenFeeZero() external {
        _test_TransferFeesToComptroller(0);
    }

    function test_GivenFeeNotZero() external {
        _test_TransferFeesToComptroller(LOCKUP_MIN_FEE_WEI);
    }

    function _test_TransferFeesToComptroller(uint256 fee) private {
        // Deal some ETH to the comptroller manager.
        vm.deal(address(comptrollerManager), fee);

        // Get the initial balance.
        uint256 initialEthBalance = address(comptroller).balance;

        // It should emit {TransferFeesToComptroller} event.
        vm.expectEmit({ emitter: address(comptrollerManager) });
        emit IComptrollerManager.TransferFeesToComptroller(comptroller, fee);

        // Call the function.
        comptrollerManager.transferFeesToComptroller();

        assertEq(address(comptroller).balance, initialEthBalance + fee, "eth balance");
    }
}
