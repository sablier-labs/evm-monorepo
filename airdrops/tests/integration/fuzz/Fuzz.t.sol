// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LeafData, MerkleBuilder } from "../../utils/MerkleBuilder.sol";
import { Integration_Test } from "../Integration.t.sol";

/// @notice Common logic needed by all fuzz tests.
abstract contract Shared_Fuzz_Test is Integration_Test {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE-VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    // Track claim fee earned in native tokens.
    uint256 internal feeEarned;

    // Store the first claim time to be used in clawback.
    uint40 internal firstClaimTime;

    // Store leaves as `uint256` in storage so that we can use OpenZeppelin's {Arrays.findUpperBound}.
    uint256[] internal leaves;

    // Store leaves data in storage so that we can use it across functions.
    LeafData[] internal leavesData;

    /*//////////////////////////////////////////////////////////////////////////
                               COMMON-TEST-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Test claiming multiple airdrops. For even values of `leafIndex`, it uses {claim} function, and for odd
    /// values, it uses {claimTo} function.
    function testClaimMultipleAirdrops(
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        address to
    )
        internal
        givenMsgValueNotLessThanFee
    {
        firstClaimTime = getBlockTimestamp();

        // Change `to` if it's zero.
        if (to == address(0)) to = vm.randomAddress();

        for (uint256 i = 0; i < indexesToClaim.length; ++i) {
            // Bound lead index so its valid.
            uint256 leafIndex = bound(indexesToClaim[i], 0, leavesData.length - 1);

            LeafData memory leafData = leavesData[leafIndex];

            // Claim the airdrop only if it has not been claimed.
            if (merkleBase.hasClaimed(leavesData[leafIndex].index)) {
                return;
            }

            // Bound `msgValue` so that it's >= min USD fee.
            msgValue = bound(msgValue, merkleBase.calculateMinFeeWei(), 1 ether);

            // If the claim amount for VCA airdrops is zero, skip this claim.
            if (merkleBase == merkleVCA && merkleVCA.calculateClaimAmount(leafData.amount, getBlockTimestamp()) == 0) {
                continue;
            }

            bytes32[] memory merkleProof = computeMerkleProof(leafData, leaves);

            // If `leafIndex` is even and the campaign type is not "vca", use {claim} function.
            if (leafIndex % 2 == 0 && !Strings.equal(campaignType, "vca")) {
                // Use a random address as the caller.
                address caller = vm.randomAddress();

                // If random address matches the factory address, change it.
                if (caller == address(factoryMerkleBase)) {
                    caller = users.recipient;
                }

                setMsgSender(caller);

                // Call the expect claim event function, implemented by the child contract.
                expectClaimEvent({ leafData: leafData, to: leafData.recipient });

                // Call the {claim} function.
                claim({
                    msgValue: msgValue,
                    index: leafData.index,
                    recipient: leafData.recipient,
                    amount: leafData.amount,
                    merkleProof: merkleProof
                });
            }
            // Otherwise use {claimTo} to claim the airdrop.
            else {
                // Change the caller to the eligible recipient.
                setMsgSender(leafData.recipient);

                // Call the expect claim event function, implemented by the child contract.
                expectClaimEvent(leafData, to);

                // Call the {claimTo} function.
                claimTo({
                    msgValue: msgValue,
                    index: leafData.index,
                    to: to,
                    amount: leafData.amount,
                    merkleProof: merkleProof
                });
            }

            // It should mark the leaf index as claimed.
            assertTrue(merkleBase.hasClaimed(leafData.index));

            // Update the fee earned.
            feeEarned += msgValue;

            // Warp to a new time.
            uint40 timeJumpSeed = uint40(uint256(keccak256(abi.encode(leafData))));
            uint40 timeJump = boundUint40(timeJumpSeed, 0, 7 days);
            skip(timeJump);

            // Break loop if the campaign has expired.
            if (merkleBase.EXPIRATION() > 0 && getBlockTimestamp() >= merkleBase.EXPIRATION()) {
                break;
            }
        }
    }

    /// @dev Test clawbacking funds.
    function testClawback(uint128 amount) internal {
        amount = boundUint128(amount, 0, uint128(dai.balanceOf(address(merkleBase))));

        setMsgSender(users.campaignCreator);

        // It should emit event if the campaign has not expired or is within the grace period of 7 days.
        if (merkleBase.EXPIRATION() > 0 || getBlockTimestamp() <= firstClaimTime + 7 days) {
            vm.warp({ newTimestamp: merkleBase.EXPIRATION() });

            expectCallToTransfer({ token: dai, to: users.campaignCreator, value: amount });
            vm.expectEmit({ emitter: address(merkleBase) });
            emit ISablierMerkleBase.Clawback({ to: users.campaignCreator, admin: users.campaignCreator, amount: amount });
        }
        // It should revert otherwise.
        else {
            vm.expectRevert(
                abi.encodeWithSelector(
                    Errors.SablierMerkleBase_ClawbackNotAllowed.selector,
                    getBlockTimestamp(),
                    merkleBase.EXPIRATION(),
                    firstClaimTime
                )
            );
        }

        // Clawback the funds.
        merkleBase.clawback({ to: users.campaignCreator, amount: amount });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function constructMerkleTree(LeafData[] memory rawLeavesData)
        internal
        returns (uint256 aggregateAmount, bytes32 merkleRoot)
    {
        // Exclude the factory contract from being the recipient. Otherwise, the fee accrued may not be equal to the sum
        // of all `msg.value`.
        address[] memory excludedAddresses = new address[](1);
        excludedAddresses[0] = address(factoryMerkleBase);

        // Fuzz the leaves data.
        aggregateAmount = fuzzMerkleData({ leavesData: rawLeavesData, excludedAddresses: excludedAddresses });

        // Store the merkle tree leaves in storage.
        for (uint256 i = 0; i < rawLeavesData.length; ++i) {
            leavesData.push(rawLeavesData[i]);
        }

        // Compute the Merkle leaves.
        MerkleBuilder.computeLeaves(leaves, rawLeavesData);

        // If there is only one leaf, the Merkle root is the hash of the leaf itself.
        merkleRoot = leaves.length == 1 ? bytes32(leaves[0]) : getRoot(leaves.toBytes32());
    }

    /// @dev Expect claim event. This function should be overridden in the child contract.
    function expectClaimEvent(LeafData memory leafData, address to) internal virtual { }

    function prepareCommonCreateParams(
        LeafData[] memory rawLeavesData,
        uint40 expiration,
        uint256 indexesCount
    )
        internal
        returns (uint256 aggregateAmount, uint40 expiration_, bytes32 merkleRoot)
    {
        vm.assume(rawLeavesData.length > 0 && indexesCount < rawLeavesData.length);

        // Bound expiration so that the campaign is still active at the creation.
        if (expiration > 0) expiration_ = boundUint40(expiration, getBlockTimestamp() + 365 days, MAX_UNIX_TIMESTAMP);

        // Construct merkle root for the given tree leaves.
        (aggregateAmount, merkleRoot) = constructMerkleTree(rawLeavesData);
    }
}
