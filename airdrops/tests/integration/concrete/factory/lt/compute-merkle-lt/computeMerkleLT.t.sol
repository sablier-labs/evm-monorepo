// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract ComputeMerkleLT_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleLT.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleLT.computeMerkleLT(users.campaignCreator, params);
    }

    function test_RevertWhen_TotalPercentageLessThan100() external whenNativeTokenNotFound whenTotalPercentageNot100 {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Create a MerkleLT campaign with a total percentage less than 100.
        params.tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        params.tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleLT_TotalPercentageNotOneHundred.selector, 0.25e18)
        );
        factoryMerkleLT.computeMerkleLT(users.campaignCreator, params);
    }

    function test_RevertWhen_TotalPercentageGreaterThan100()
        external
        whenNativeTokenNotFound
        whenTotalPercentageNot100
    {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        // Create a MerkleLT campaign with a total percentage greater than 100.
        params.tranchesWithPercentages[0].unlockPercentage = ud2x18(0.75e18);
        params.tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleLT_TotalPercentageNotOneHundred.selector, 1.55e18)
        );
        factoryMerkleLT.computeMerkleLT(users.campaignCreator, params);
    }

    function test_WhenTotalPercentage100() external view whenNativeTokenNotFound {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();

        address actualAddress = factoryMerkleLT.computeMerkleLT(users.campaignCreator, params);
        address expectedAddress = computeMerkleLTAddress();
        assertEq(actualAddress, expectedAddress);
    }
}
