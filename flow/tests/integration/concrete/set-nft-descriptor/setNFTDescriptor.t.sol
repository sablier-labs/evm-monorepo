// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { SablierFlowNFTDescriptor } from "src/SablierFlowNFTDescriptor.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract SetNFTDescriptor_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        flow.setNFTDescriptor(SablierFlowNFTDescriptor(users.eve));
    }

    function test_WhenNewAndOldNFTDescriptorsAreSame() external whenCallerAdmin {
        // It should emit 1 {SetNFTDescriptor} and 1 {BatchMetadataUpdate} events
        vm.expectEmit({ emitter: address(flow) });
        emit SetNFTDescriptor(users.admin, nftDescriptor, nftDescriptor);
        vm.expectEmit({ emitter: address(flow) });
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        // It should re-set the NFT descriptor
        flow.setNFTDescriptor(nftDescriptor);
        vm.expectCall(address(nftDescriptor), abi.encodeCall(SablierFlowNFTDescriptor.tokenURI, (flow, 1)));
        flow.tokenURI({ streamId: defaultStreamId });
    }

    function test_WhenNewAndOldNFTDescriptorsAreNotSame() external whenCallerAdmin {
        // Deploy another NFT descriptor.
        SablierFlowNFTDescriptor newNFTDescriptor = new SablierFlowNFTDescriptor();

        // It should emit 1 {SetNFTDescriptor} and 1 {BatchMetadataUpdate} events
        vm.expectEmit({ emitter: address(flow) });
        emit SetNFTDescriptor(users.admin, nftDescriptor, newNFTDescriptor);
        vm.expectEmit({ emitter: address(flow) });
        emit BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        // It should set the new NFT descriptor
        flow.setNFTDescriptor(newNFTDescriptor);
        address actualNFTDescriptor = address(flow.nftDescriptor());
        address expectedNFTDescriptor = address(newNFTDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");
    }
}
