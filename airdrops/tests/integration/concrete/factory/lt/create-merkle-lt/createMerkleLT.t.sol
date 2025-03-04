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
        merkleFactoryLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        givenCampaignNotExists
    {
        vm.assume(customFee <= MAX_FEE);

        // Set the custom fee for this test.
        resetPrank(users.admin);
        merkleFactoryLT.setCustomFee(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedLT = computeMerkleLTAddress(campaignOwner, expiration);

        // It should emit a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            params: merkleLTConstructorParams(campaignOwner, expiration),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: TOTAL_DURATION,
            fee: customFee,
            oracle: address(oracle)
        });

        ISablierMerkleLT actualLT = createMerkleLT(campaignOwner, expiration);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactoryLT), "factory");
        assertEq(actualLT.minimumFee(), customFee, "minimum fee");
    }

    function test_GivenCustomFeeNotSet(address campaignOwner, uint40 expiration) external givenCampaignNotExists {
        address expectedLT = computeMerkleLTAddress(campaignOwner, expiration);

        vm.expectEmit({ emitter: address(merkleFactoryLT) });
        emit ISablierMerkleFactoryLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            params: merkleLTConstructorParams(campaignOwner, expiration),
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            totalDuration: TOTAL_DURATION,
            fee: MINIMUM_FEE,
            oracle: address(oracle)
        });

        ISablierMerkleLT actualLT = createMerkleLT(campaignOwner, expiration);
        assertGt(address(actualLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(actualLT), expectedLT, "MerkleLT contract does not match computed address");

        // It should set the correct shape.
        assertEq(actualLT.shape(), SHAPE, "shape");

        // It should set the current factory address.
        assertEq(actualLT.FACTORY(), address(merkleFactoryLT), "factory");
        assertEq(actualLT.minimumFee(), MINIMUM_FEE, "minimum fee");
    }
}
