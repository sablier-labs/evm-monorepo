// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "periphery/libraries/Errors.sol";
import { ISablierV2MerkleLT } from "periphery/interfaces/ISablierV2MerkleLT.sol";
import { MerkleLockup, MerkleLT } from "periphery/types/DataTypes.sol";

import { MerkleLockup_Integration_Test } from "../../MerkleLockup.t.sol";

contract CreateMerkleLT_Integration_Test is MerkleLockup_Integration_Test {
    function setUp() public override {
        MerkleLockup_Integration_Test.setUp();

        // Make alice the caller of createMerkleLT.
        resetPrank(users.alice);
    }

    function test_RevertWhen_CampaignNameTooLong() external {
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        baseParams.name = "this string is longer than 32 characters";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2MerkleLockup_CampaignNameTooLong.selector, bytes(baseParams.name).length, 32
            )
        );

        merkleLockupFactory.createMerkleLT(
            baseParams, lockupTranched, tranchesWithPercentages, aggregateAmount, recipientCount
        );
    }

    modifier whenCampaignNameNotTooLong() {
        _;
    }

    /// @dev This test works because a default MerkleLockup contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CreatedAlready() external whenCampaignNameNotTooLong {
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleLockupFactory.createMerkleLT(
            baseParams, lockupTranched, tranchesWithPercentages, aggregateAmount, recipientCount
        );
    }

    modifier givenNotCreatedAlready() {
        _;
    }

    function testFuzz_CreateMerkleLT(
        address admin,
        uint40 expiration
    )
        external
        whenCampaignNameNotTooLong
        givenNotCreatedAlready
    {
        vm.assume(admin != users.admin);
        address expectedLT = computeMerkleLTAddress(admin, expiration);

        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams({
            admin: admin,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleLockupFactory) });
        emit CreateMerkleLT({
            merkleLT: ISablierV2MerkleLT(expectedLT),
            baseParams: baseParams,
            lockupTranched: lockupTranched,
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            totalDuration: defaults.TOTAL_DURATION(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        address actualLT = address(createMerkleLT(admin, expiration));
        assertGt(actualLT.code.length, 0, "MerkleLT contract not created");
        assertEq(actualLT, expectedLT, "MerkleLT contract does not match computed address");
    }
}
