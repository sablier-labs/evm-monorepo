// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract IsPercentagesSum100_Integration_Test is Integration_Test {
    function test_WhenPercentagesSumLessThan100Pct() external view whenPercentagesSumNot100Pct {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        assertFalse(merkleFactoryLT.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }

    function test_WhenPercentagesSumGreaterThan100Pct() external view whenPercentagesSumNot100Pct {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.5e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.6e18);

        assertFalse(merkleFactoryLT.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }

    function test_WhenPercentagesSum100Pct() external view {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.2e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        assertTrue(merkleFactoryLT.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }
}
