// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleBase, MerkleLL } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract CreateMerkleLL_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertWhen_CampaignNameTooLong() external {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        MerkleLL.Schedule memory schedule = defaults.schedule();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        baseParams.name = "this string is longer than 32 characters";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CampaignNameTooLong.selector, bytes(baseParams.name).length, 32
            )
        );

        merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            cancelable: cancelable,
            transferable: transferable,
            schedule: schedule,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount
        });
    }

    modifier whenCampaignNameNotTooLong() {
        _;
    }

    /// @dev This test works because a default MerkleLL contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CreatedAlready() external whenCampaignNameNotTooLong {
        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams();
        bool cancelable = defaults.CANCELABLE();
        bool transferable = defaults.TRANSFERABLE();
        MerkleLL.Schedule memory schedule = defaults.schedule();
        uint256 aggregateAmount = defaults.AGGREGATE_AMOUNT();
        uint256 recipientCount = defaults.RECIPIENT_COUNT();

        // Expect a revert due to CREATE2.
        vm.expectRevert();
        merkleFactory.createMerkleLL({
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            cancelable: cancelable,
            transferable: transferable,
            schedule: schedule,
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

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            admin: admin,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        vm.expectEmit({ emitter: address(merkleFactory) });
        emit CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        address actualLL = address(createMerkleLL(admin, expiration));
        assertGt(actualLL.code.length, 0, "MerkleLL contract not created");
        assertEq(actualLL, expectedLL, "MerkleLL contract does not match computed address");
    }
}
