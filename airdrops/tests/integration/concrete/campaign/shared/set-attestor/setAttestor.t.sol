// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleSignature } from "src/interfaces/ISablierMerkleSignature.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetAttestor_Integration_Concrete_Test is Integration_Test {
    address internal newAttestor = makeAddr("newAttestor");

    function test_RevertWhen_CallerNotComptroller() external whenCallerNotCampaignCreator {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleSignature_CallerNotAuthorized.selector,
                users.eve,
                users.campaignCreator,
                address(comptroller)
            )
        );
        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);
    }

    function test_WhenCallerComptroller() external whenCallerNotCampaignCreator {
        setMsgSender(address(comptroller));

        // It should emit a {SetAttestor} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleSignature.SetAttestor({
            caller: address(comptroller),
            previousAttestor: attestor,
            newAttestor: newAttestor
        });

        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);

        // It should set the attestor.
        assertEq(ISablierMerkleSignature(address(merkleBase)).attestor(), newAttestor, "attestor");
    }

    function test_WhenCallerCampaignCreator() external {
        // It should emit a {SetAttestor} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleSignature.SetAttestor({
            caller: users.campaignCreator,
            previousAttestor: attestor,
            newAttestor: newAttestor
        });

        ISablierMerkleSignature(address(merkleBase)).setAttestor(newAttestor);

        // It should set the attestor.
        assertEq(ISablierMerkleSignature(address(merkleBase)).attestor(), newAttestor, "attestor");
    }
}
