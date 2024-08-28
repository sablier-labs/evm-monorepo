// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { MAX_UD2x18, ud2x18 } from "@prb/math/src/UD2x18.sol";

import { MerkleLT } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract IsPercentagesSum100_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertWhen_PercentagesSumOverflows() public {
        MerkleLT.TrancheWithPercentage[] memory tranches = defaults.tranchesWithPercentages();
        tranches[0].unlockPercentage = MAX_UD2x18;

        vm.expectRevert();
        merkleFactory.isPercentagesSum100(tranches);
    }

    modifier whenPercentagesSumNotOverflow() {
        _;
    }

    modifier whenPercentagesSumNot100Pct() {
        _;
    }

    function test_WhenPercentagesSumLessThan100Pct()
        external
        view
        whenPercentagesSumNotOverflow
        whenPercentagesSumNot100Pct
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        assertFalse(merkleFactory.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }

    function test_WhenPercentagesSumGreaterThan100Pct()
        external
        view
        whenPercentagesSumNotOverflow
        whenPercentagesSumNot100Pct
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.5e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.6e18);

        assertFalse(merkleFactory.isPercentagesSum100(tranchesWithPercentages), "isPercentagesSum100");
    }

    function test_WhenPercentagesSum100Pct() external view whenPercentagesSumNotOverflow {
        assertTrue(merkleFactory.isPercentagesSum100(defaults.tranchesWithPercentages()), "isPercentagesSum100");
    }
}
