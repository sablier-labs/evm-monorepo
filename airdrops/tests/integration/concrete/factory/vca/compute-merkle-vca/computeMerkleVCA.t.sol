// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UNIT } from "@prb/math/src/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/MerkleVCA.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

contract ComputeMerkleVCA_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_NativeTokenFound() external {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        // Set dai as the native token.
        setMsgSender(address(comptroller));
        address newNativeToken = address(dai);
        factoryMerkleVCA.setNativeToken(newNativeToken);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFactoryMerkleBase_ForbidNativeToken.selector, newNativeToken)
        );
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_AggregateAmountZero() external whenNativeTokenNotFound {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.aggregateAmount = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierFactoryMerkleVCA_AggregateAmountZero.selector);
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_VestingStartTimeZero() external whenNativeTokenNotFound whenAggregateAmountNotZero {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierFactoryMerkleVCA_StartTimeZero.selector);
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_VestingEndTimeLessThanVestingStartTime()
        external
        whenNativeTokenNotFound
        whenAggregateAmountNotZero
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
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_VestingEndTimeEqualsVestingStartTime()
        external
        whenNativeTokenNotFound
        whenAggregateAmountNotZero
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
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_ExpirationZero()
        external
        whenNativeTokenNotFound
        whenAggregateAmountNotZero
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = 0;

        // It should revert.
        vm.expectRevert(Errors.SablierFactoryMerkleVCA_ExpirationTimeZero.selector);
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_ExpirationNotExceedOneWeekFromVestingEndTime()
        external
        whenNativeTokenNotFound
        whenAggregateAmountNotZero
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenExpirationNotZero
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.expiration = VESTING_END_TIME + 1 weeks - 1 seconds;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleVCA_ExpirationTooEarly.selector, params.vestingEndTime, params.expiration
            )
        );
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_RevertWhen_UnlockPercentageGreaterThan100()
        external
        whenNativeTokenNotFound
        whenAggregateAmountNotZero
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenExpirationNotZero
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
        factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
    }

    function test_WhenUnlockPercentageNotGreaterThan100()
        external
        view
        whenNativeTokenNotFound
        whenAggregateAmountNotZero
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenExpirationNotZero
        whenExpirationExceedsOneWeekFromVestingEndTime
    {
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();

        address actualAddress = factoryMerkleVCA.computeMerkleVCA(users.campaignCreator, params);
        address expectedAddress = computeMerkleVCAAddress();
        assertEq(actualAddress, expectedAddress);
    }
}
