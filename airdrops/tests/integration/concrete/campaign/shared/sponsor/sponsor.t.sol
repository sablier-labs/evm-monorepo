// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Sponsor_Integration_Test is Integration_Test {
    uint128 internal constant SPONSOR_AMOUNT = 200e6;

    function test_RevertWhen_BillerZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_ToZeroAddress.selector));
        merkleBase.sponsor({ token: usdc, amount: SPONSOR_AMOUNT, biller: address(0) });
    }

    function test_RevertWhen_AmountZero() external whenBillerNotZeroAddress {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_SponsorAmountZero.selector));
        merkleBase.sponsor({ token: usdc, amount: 0, biller: address(comptroller) });
    }

    function test_WhenAmountNotZero() external whenBillerNotZeroAddress whenTokenNotZeroAddress {
        // Approve the merkle base to transfer the sponsor amount.
        setMsgSender(users.campaignCreator);
        usdc.approve(address(merkleBase), SPONSOR_AMOUNT);

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({
            token: usdc,
            from: users.campaignCreator,
            to: address(comptroller),
            value: SPONSOR_AMOUNT
        });

        // It should emit a {Sponsor} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.Sponsor({
            caller: users.campaignCreator,
            token: usdc,
            amount: SPONSOR_AMOUNT,
            biller: address(comptroller)
        });

        merkleBase.sponsor({ token: usdc, amount: SPONSOR_AMOUNT, biller: address(comptroller) });
    }
}
