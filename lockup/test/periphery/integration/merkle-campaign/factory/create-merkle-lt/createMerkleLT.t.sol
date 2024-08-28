// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleBase, MerkleLT } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract CreateMerkleLT_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertWhen_CampaignNameTooLong() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        uint40 streamStartTime = defaults.STREAM_START_TIME_ZERO();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        baseParams.name = "this string is longer than 32 characters";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CampaignNameTooLong.selector, bytes(baseParams.name).length, 32
            )
        );

        merkleFactory.createMerkleLT(
            baseParams,
            lockupTranched,
            cancelable,
            transferable,
            streamStartTime,
            tranchesWithPercentages,
            aggregateAmount,
            recipientCount
        );
    }

    modifier whenCampaignNameNotTooLong() {
        _;
    }

    /// @dev This test works because a default MerkleLT contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CreatedAlready() external whenCampaignNameNotTooLong {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        uint40 streamStartTime = defaults.STREAM_START_TIME_ZERO();
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleLT(
            baseParams,
            lockupTranched,
            cancelable,
            transferable,
            streamStartTime,
            tranchesWithPercentages,
            aggregateAmount,
            recipientCount
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

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            admin: admin,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedLT),
            baseParams: baseParams,
            lockupTranched: lockupTranched,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_ZERO(),
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
