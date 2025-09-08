// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UNIT } from "@prb/math/src/UD60x18.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
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
        setMsgSender(address(comptroller));
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

    function test_RevertWhen_VestingStartTimeZero() external whenNativeTokenNotFound givenCampaignNotExists {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierFactoryMerkleVCA_StartTimeZero.selector);
        createMerkleVCA(params);
    }

    function test_RevertWhen_VestingEndTimeLessThanVestingStartTime()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the vesting end time to be less than the vesting start time.
        params.vestingEndTime = VESTING_START_TIME - 1 seconds;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleVCA_VestingEndTimeNotGreaterThanVestingStartTime.selector,
                params.vestingStartTime,
                params.vestingEndTime
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_VestingEndTimeEqualsVestingStartTime()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        // Set the vesting end time equal to the start time.
        params.vestingEndTime = VESTING_START_TIME;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleVCA_VestingEndTimeNotGreaterThanVestingStartTime.selector,
                params.vestingStartTime,
                params.vestingEndTime
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_ZeroExpiration()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierFactoryMerkleVCA_ExpirationTimeZero.selector);
        createMerkleVCA(params);
    }

    function test_RevertWhen_ExpirationNotExceedOneWeekFromVestingEndTime()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenNotZeroExpiration
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = VESTING_END_TIME + 1 weeks - 1 seconds;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleVCA_ExpirationTooEarly.selector, params.vestingEndTime, params.expiration
            )
        );
        createMerkleVCA(params);
    }

    function test_RevertWhen_UnlockPercentageGreaterThan100()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenNotZeroExpiration
        whenExpirationExceedsOneWeekFromVestingEndTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.unlockPercentage = UNIT.add(UNIT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleVCA_UnlockPercentageTooHigh.selector, params.unlockPercentage
            )
        );
        createMerkleVCA(params);
    }

    function test_GivenCustomFeeUSDSet()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenNotZeroExpiration
        whenExpirationExceedsOneWeekFromVestingEndTime
        whenUnlockPercentageNotGreaterThan100
    {
        // Set the custom fee to 0.
        uint256 customFeeUSD = 0;

        setMsgSender(admin);
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.campaignCreator, customFeeUSD);

        setMsgSender(users.campaignCreator);
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
            comptroller: address(comptroller),
            minFeeUSD: customFeeUSD
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA(params);
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should create the campaign with 0 custom fee.
        assertEq(actualVCA.minFeeUSD(), customFeeUSD, "custom fee USD");

        // It should set the comptroller address.
        assertEq(address(actualVCA.COMPTROLLER()), address(comptroller), "comptroller address");

        // It should set the correct vesting end time.
        assertEq(actualVCA.VESTING_END_TIME(), VESTING_END_TIME, "vesting end time");

        // It should set the correct vesting start time.
        assertEq(actualVCA.VESTING_START_TIME(), VESTING_START_TIME, "vesting start time");
    }

    function test_GivenCustomFeeUSDNotSet()
        external
        whenNativeTokenNotFound
        givenCampaignNotExists
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenNotZeroExpiration
        whenExpirationExceedsOneWeekFromVestingEndTime
        whenUnlockPercentageNotGreaterThan100
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
            comptroller: address(comptroller),
            minFeeUSD: AIRDROP_MIN_FEE_USD
        });

        ISablierMerkleVCA actualVCA = createMerkleVCA(params);
        assertGt(address(actualVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(actualVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should set the comptroller address.
        assertEq(address(actualVCA.COMPTROLLER()), address(comptroller), "comptroller address");

        // It should set the correct min fee.
        assertEq(actualVCA.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");

        // It should set the correct vesting end time.
        assertEq(actualVCA.VESTING_END_TIME(), VESTING_END_TIME, "vesting end time");

        // It should set the correct vesting start time.
        assertEq(actualVCA.VESTING_START_TIME(), VESTING_START_TIME, "vesting start time");
    }
}
