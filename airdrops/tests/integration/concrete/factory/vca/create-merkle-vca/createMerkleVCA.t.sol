// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

/// @dev Some of the tests use `users.sender` as the campaign creator to avoid collision with the default MerkleVCA
/// contract deployed in {Integration_Test.setUp}.
contract CreateMerkleVCA_Integration_Test is Integration_Test {
    /// @dev This test reverts because a default MerkleVCA contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external {
        // This test fails
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleVCA(params);
    }

    function test_RevertWhen_StartTimeZero() external givenCampaignNotExists {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.timestamps.start = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_StartTimeZero.selector);
        createMerkleVCA(params);
    }

    function test_RevertWhen_EndTimeLessThanStartTime() external givenCampaignNotExists whenStartTimeNotZero {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time to be less than the start time.
        params.timestamps.end = RANGED_STREAM_START_TIME - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_StartTimeExceedsEndTime.selector, params.timestamps.start, params.timestamps.end
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_EndTimeEqualsStartTime() external givenCampaignNotExists whenStartTimeNotZero {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time equal to the start time.
        params.timestamps.end = RANGED_STREAM_START_TIME;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_StartTimeExceedsEndTime.selector, params.timestamps.start, params.timestamps.end
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_ZeroExpiry()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_ExpiryTimeZero.selector);
        createMerkleVCA(params);
    }

    function test_RevertWhen_ExpiryNotExceedOneWeekFromEndTime()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = RANGED_STREAM_END_TIME + 1 weeks - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_ExpiryWithinOneWeekOfUnlockEndTime.selector,
                params.timestamps.end,
                params.expiration
            )
        );
        createMerkleVCA(params);
    }

    function test_GivenCustomFeeSet()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryExceedsOneWeekFromEndTime
    {
        // Set the custom fee to 0 for this test.
        uint256 customFee = 0;

        resetPrank(users.admin);
        merkleFactoryVCA.setCustomFee(users.campaignCreator, customFee);

        resetPrank(users.campaignCreator);
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.campaignName = "Merkle VCA campaign with custom fee set";

        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactoryVCA));
        emit ISablierMerkleFactoryVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: customFee,
            oracle: address(oracle)
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA(params);
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with 0 custom fee.
        assertEq(actualVCA.minimumFee(), customFee, "custom fee");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactoryVCA), "factory");

        // It should set return the correct unlock timestamps.
        assertEq(actualVCA.timestamps().start, RANGED_STREAM_START_TIME, "unlock start");
        assertEq(actualVCA.timestamps().end, RANGED_STREAM_END_TIME, "unlock end");
    }

    function test_GivenCustomFeeNotSet()
        external
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryExceedsOneWeekFromEndTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.campaignName = "Merkle VCA campaign with default fee set";

        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(merkleFactoryVCA));
        emit ISablierMerkleFactoryVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            fee: MINIMUM_FEE,
            oracle: address(oracle)
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA(params);
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualVCA.minimumFee(), MINIMUM_FEE, "minimum fee");
        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(merkleFactoryVCA), "factory");

        // It should set return the correct unlock timestamps.
        assertEq(actualVCA.timestamps().start, RANGED_STREAM_START_TIME, "unlock start");
        assertEq(actualVCA.timestamps().end, RANGED_STREAM_END_TIME, "unlock end");
    }
}
