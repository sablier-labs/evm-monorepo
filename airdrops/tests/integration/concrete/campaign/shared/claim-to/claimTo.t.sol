// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimTo_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Make `users.recipient1` the caller for this test.
        setMsgSender(users.recipient1);
    }

    function test_RevertWhen_ToAddressZero() external {
        if (Strings.equal(campaignType, "instant")) {
            vm.expectRevert(Errors.SablierMerkleInstant_ToZeroAddress.selector);
        } else if (Strings.equal(campaignType, "ll")) {
            vm.expectRevert(Errors.SablierMerkleLL_ToZeroAddress.selector);
        } else if (Strings.equal(campaignType, "lt")) {
            vm.expectRevert(Errors.SablierMerkleLT_ToZeroAddress.selector);
        } else if (Strings.equal(campaignType, "vca")) {
            vm.expectRevert(Errors.SablierMerkleVCA_ToZeroAddress.selector);
        }
        claimTo({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            to: address(0),
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_RevertGiven_CallerClaimed() external whenToAddressNotZero {
        claimTo();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, INDEX1));
        claimTo();
    }

    function test_RevertWhen_CallerNotEligible() external whenToAddressNotZero givenCallerNotClaimed {
        setMsgSender(address(1337));

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo();
    }

    /// @dev Since the implementation of `claimTo()` differs in each Merkle campaign, we declare this dummy test. The
    /// child contracts implement the rest of the tests.
    function test_WhenMerkleProofValid() external whenToAddressNotZero givenCallerNotClaimed whenCallerEligible {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }
}
