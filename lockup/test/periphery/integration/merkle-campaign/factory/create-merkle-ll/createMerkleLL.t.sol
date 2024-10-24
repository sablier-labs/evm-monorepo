// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";
import { MerkleBase, MerkleLL } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract CreateMerkleLL_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertWhen_NameTooLong() external {
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

    modifier whenNameNotTooLong() {
        _;
    }

    /// @dev This test works because a default MerkleLL contract is deployed in {Integration_Test.setUp}
    function test_RevertGiven_CampaignAlreadyExists() external whenNameNotTooLong {
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

    modifier givenCampaignNotExists() {
        _;
    }

    function test_GivenCustomFeeSet(
        address campaignOwner,
        uint40 expiration,
        uint256 customFee
    )
        external
        whenNameNotTooLong
        givenCampaignNotExists
    {
        // Set the Sablier fee to 0 for this test.
        resetPrank(users.admin);
        merkleFactory.setSablierFeeByUser(users.campaignOwner, customFee);

        resetPrank(users.campaignOwner);
        address expectedLL = computeMerkleLLAddress(campaignOwner, expiration, customFee);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            sablierFee: customFee
        });

        ISablierMerkleLL actualLL = createMerkleLL(campaignOwner, expiration);
        assertGt(address(actualLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualLL.SABLIER_FEE(), customFee, "sablier fee");

        // It should set the current factory address.
        assertEq(actualLL.FACTORY(), address(merkleFactory), "factory");
    }

    function test_GivenCustomFeeNotSet(
        address campaignOwner,
        uint40 expiration
    )
        external
        whenNameNotTooLong
        givenCampaignNotExists
    {
        address expectedLL = computeMerkleLLAddress(campaignOwner, expiration);

        MerkleBase.ConstructorParams memory baseParams = defaults.baseParams({
            campaignOwner: campaignOwner,
            asset_: dai,
            merkleRoot: defaults.MERKLE_ROOT(),
            expiration: expiration
        });

        // It should emit a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedLL),
            baseParams: baseParams,
            lockupLinear: lockupLinear,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: defaults.schedule(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT(),
            sablierFee: defaults.DEFAULT_SABLIER_FEE()
        });

        ISablierMerkleLL actualLL = createMerkleLL(campaignOwner, expiration);
        assertGt(address(actualLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(actualLL), expectedLL, "MerkleLL contract does not match computed address");

        // It should create the campaign with custom fee.
        assertEq(actualLL.SABLIER_FEE(), defaults.DEFAULT_SABLIER_FEE(), "default sablier fee");

        // It should set the current factory address.
        assertEq(actualLL.FACTORY(), address(merkleFactory), "factory");
    }
}
