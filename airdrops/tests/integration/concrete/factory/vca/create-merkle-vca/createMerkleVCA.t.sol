// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

/// @dev Some of the tests use `users.sender` as the campaign creator to avoid collision with the default MerkleVCA
/// contract deployed in {Integration_Test.setUp}.
contract CreateMerkleVCA_Integration_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        // Set dai as the native token.
        resetPrank(users.admin);
        address newNativeToken = address(dai);
        factoryMerkleVCA.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleVCA.createMerkleVCA(params, AGGREGATE_AMOUNT, AGGREGATE_AMOUNT);
    }

    /// @dev This test reverts because a default MerkleVCA contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNativeTokenNotFound {
        // This test fails
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        createMerkleVCA(params);
    }

    function test_RevertWhen_StartTimeZero() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.schedule.startTime = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_VestingStartTimeZero.selector);
        createMerkleVCA(params);
    }

    function test_RevertWhen_EndTimeLessThanStartTime()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenStartTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time to be less than the start time.
        params.schedule.endTime = RANGED_STREAM_START_TIME - 1 seconds;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_StartTimeGreaterThanEndTime.selector,
                params.schedule.startTime,
                params.schedule.endTime
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_EndTimeEqualsStartTime()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenStartTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the end time equal to the start time.
        params.schedule.endTime = RANGED_STREAM_START_TIME;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_StartTimeGreaterThanEndTime.selector,
                params.schedule.startTime,
                params.schedule.endTime
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_ZeroExpiry()
        external
        whenNativeTokenNotFound
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
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = RANGED_STREAM_END_TIME + 1 weeks - 1 seconds;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleVCA_ExpirationTooEarly.selector, params.schedule.endTime, params.expiration
            )
        );
        createMerkleVCA(params);
    }

    function test_GivenCustomFeeUSDSet()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryExceedsOneWeekFromEndTime
    {
        // Set the custom fee to 0.
        uint256 customFeeUSD = 0;

        resetPrank(users.admin);
        factoryMerkleVCA.setCustomFeeUSD(users.campaignCreator, customFeeUSD);

        resetPrank(users.campaignCreator);
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.campaignName = "Merkle VCA campaign with custom fee USD";

        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(factoryMerkleVCA));
        emit ISablierFactoryMerkleVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            minFeeUSD: customFeeUSD,
            oracle: address(oracle)
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA(params);
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with 0 custom fee.
        assertEq(actualVCA.minFeeUSD(), customFeeUSD, "custom fee USD");

        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(factoryMerkleVCA), "factory");

        // It should set return the correct schedule.
        assertEq(actualVCA.getSchedule().startTime, RANGED_STREAM_START_TIME, "schedule start time");
        assertEq(actualVCA.getSchedule().endTime, RANGED_STREAM_END_TIME, "schedule end time");
    }

    function test_GivenCustomFeeUSDNotSet()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiry
        whenExpiryExceedsOneWeekFromEndTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.campaignName = "Merkle VCA campaign with custom fee USD";

        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // It should emit a {CreateMerkleVCA} event.
        vm.expectEmit(address(factoryMerkleVCA));
        emit ISablierFactoryMerkleVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(address(expectedMerkleVCA)),
            params: params,
            aggregateAmount: AGGREGATE_AMOUNT,
            recipientCount: RECIPIENT_COUNT,
            minFeeUSD: MIN_FEE_USD,
            oracle: address(oracle)
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA(params);
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign.
        assertEq(actualVCA.minFeeUSD(), MIN_FEE_USD, "min fee USD");
        // It should set the current factory address.
        assertEq(actualVCA.FACTORY(), address(factoryMerkleVCA), "factory");

        // It should set return the correct unlock timestamps.
        assertEq(actualVCA.getSchedule().startTime, RANGED_STREAM_START_TIME, "schedule start time");
        assertEq(actualVCA.getSchedule().endTime, RANGED_STREAM_END_TIME, "schedule end time");
    }
}
