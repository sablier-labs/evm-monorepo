// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MAX_UD2x18, ud2x18 } from "@prb/math/src/UD2x18.sol";

import { MerkleLT } from "periphery/types/DataTypes.sol";

import { MerkleLockup_Integration_Test } from "../../MerkleLockup.t.sol";

contract IsPercentagesSum100_Integration_Test is MerkleLockup_Integration_Test {
    function test_RevertWhen_SumOverflow() public {
        MerkleLT.TrancheWithPercentage[] memory tranches = defaults.tranchesWithPercentages();
        tranches[0].unlockPercentage = MAX_UD2x18;

        vm.expectRevert();
        merkleLockupFactory.isPercentagesSum100(tranches);
    }

    modifier whenSumDoesNotOverflow() {
        _;
    }

    modifier whenTotalPercentageNotOneHundred() {
        _;
    }

    function test_TotalPercentageLessThanOneHundred()
        external
        view
        whenSumDoesNotOverflow
        whenTotalPercentageNotOneHundred
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        assertFalse(merkleLockupFactory.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }

    function test_TotalPercentageGreaterThanOneHundred()
        external
        view
        whenSumDoesNotOverflow
        whenTotalPercentageNotOneHundred
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.5e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.6e18);

        assertFalse(merkleLockupFactory.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }

    modifier whenTotalPercentageOneHundred() {
        _;
    }

    function test_IsPercentagesSum100() external view whenSumDoesNotOverflow whenTotalPercentageOneHundred {
        assertTrue(merkleLockupFactory.isPercentagesSum100(defaults.tranchesWithPercentages()), "isPercentagesSum100");
    }
}
