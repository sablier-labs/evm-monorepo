// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupLinear } from "src/core/types/DataTypes.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { ISablierV2MerkleLL } from "src/periphery/interfaces/ISablierV2MerkleLL.sol";
import { MerkleLockup } from "src/periphery/types/DataTypes.sol";

import { MerkleLockup_Integration_Test } from "../../MerkleLockup.t.sol";

contract CreateMerkleLL_Integration_Test is MerkleLockup_Integration_Test {
    function test_RevertWhen_CampaignNameTooLong() external {
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        LockupLinear.Durations memory streamDurations = defaults.durations();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        baseParams.name = "this string is longer than 32 characters";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2MerkleLockup_CampaignNameTooLong.selector, bytes(baseParams.name).length, 32
            )
        );

        merkleLockupFactory.createMerkleLL({
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            streamDurations: streamDurations,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    modifier whenCampaignNameNotTooLong() {
        _;
    }

    /// @dev This test works because a default MerkleLockup contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CreatedAlready() external whenCampaignNameNotTooLong {
        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams();
        LockupLinear.Durations memory streamDurations = defaults.durations();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleLockupFactory.createMerkleLL({
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            streamDurations: streamDurations,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    modifier givenNotCreatedAlready() {
        _;
    }

    function testFuzz_CreateMerkleLL(
        address admin,
        uint40 expiration
    )
        external
        whenCampaignNameNotTooLong
        givenNotCreatedAlready
    {
        vm.assume(admin != users.admin);
        address expectedLL = computeMerkleLLAddress(admin, expiration);

        MerkleLockup.ConstructorParams memory baseParams = defaults.baseParams({
            admin: admin,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleLockupFactory) });
        emit CreateMerkleLL({
            merkleLL: ISablierV2MerkleLL(expectedLL),
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            streamDurations: defaults.durations(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        address actualLL = address(createMerkleLL(admin, expiration));
        assertGt(actualLL.code.length, 0, "MerkleLL contract not created");
        assertEq(actualLL, expectedLL, "MerkleLL contract does not match computed address");
    }
}
