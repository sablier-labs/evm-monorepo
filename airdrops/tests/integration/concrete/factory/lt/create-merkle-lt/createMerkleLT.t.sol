// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract CreateMerkleLT_Integration_Test is Integration_Test {
    /// @dev This test reverts because a default MerkleLT contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleLT(params);
    }

    function test_GivenCustomFeeSet() external givenCampaignNotExists {
        uint256 customFee = 0;

        // Set the custom fee for this test.
        resetPrank(users.admin);
        merkleFactoryLT.setCustomFee(users.campaignCreator, customFee);

        resetPrank(users.campaignCreator);
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.campaignName = "Merkle LT campaign with custom fee set";

        address expectedLT = computeMerkleLTAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: TOTAL_DURATION,
            fee: customFee,
            oracle: address(oracle)
        });

        ISablierMerkleLT actualLT = createMerkleLT(params);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactoryLT), "factory");
        assertEq(actualLT.minimumFee(), customFee, "minimum fee");
    }

    function test_GivenCustomFeeNotSet() external givenCampaignNotExists {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.campaignName = "Merkle LT campaign with default fee set";

        address expectedLT = computeMerkleLTAddress(params, users.campaignCreator);

        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: TOTAL_DURATION,
            fee: MINIMUM_FEE,
            oracle: address(oracle)
        });

        ISablierMerkleLT actualLT = createMerkleLT(params);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the correct shape.
        assertEq(actualLT.shape(), SHAPE, "shape");

        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactoryLT), "factory");
        assertEq(actualLT.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
