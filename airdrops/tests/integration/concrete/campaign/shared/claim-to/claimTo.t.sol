// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ClaimTo_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        // Make `users.recipient` the caller for this test.
        setMsgSender(users.recipient);
    }

    function test_RevertWhen_ToAddressZero() external {
        vm.expectRevert(Errors.SablierMerkleBase_ToZeroAddress.selector);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: address(0),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertGiven_CallerClaimed() external whenToAddressNotZero {
        claimTo();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, getIndexInMerkleTree()));
        claimTo();
    }

    function test_RevertWhen_CallerNotEligible() external whenToAddressNotZero givenCallerNotClaimed {
        setMsgSender(address(1337));

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claimTo();
    }

    /// @dev Since the implementation of `claimTo()` differs in each Merkle campaign, we declare this virtual dummy
    /// test. The child contracts implement it.
    function test_WhenMerkleProofValid()
        external
        virtual
        whenToAddressNotZero
        givenCallerNotClaimed
        whenCallerEligible
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }
}
