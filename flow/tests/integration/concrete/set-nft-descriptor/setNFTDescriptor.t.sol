// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { ISablierFlowBase } from "src/interfaces/ISablierFlowBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../Integration.t.sol";

contract SetNFTDescriptor_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        flow.setNFTDescriptor(FlowNFTDescriptor(users.eve));
    }

    function test_WhenNewAndOldNFTDescriptorsAreSame() external whenCallerAdmin {
        // It should emit 1 {SetNFTDescriptor} and 1 {BatchMetadataUpdate} events
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.SetNFTDescriptor(users.admin, nftDescriptor, nftDescriptor);
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        // It should re-set the NFT descriptor
        flow.setNFTDescriptor(nftDescriptor);
        vm.expectCall(address(nftDescriptor), abi.encodeCall(FlowNFTDescriptor.tokenURI, (flow, 1)));
        flow.tokenURI({ streamId: defaultStreamId });
    }

    function test_WhenNewAndOldNFTDescriptorsAreNotSame() external whenCallerAdmin {
        // Deploy another NFT descriptor.
        FlowNFTDescriptor newNFTDescriptor = new FlowNFTDescriptor();

        // It should emit 1 {SetNFTDescriptor} and 1 {BatchMetadataUpdate} events
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.SetNFTDescriptor(users.admin, nftDescriptor, newNFTDescriptor);
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        // It should set the new NFT descriptor
        flow.setNFTDescriptor(newNFTDescriptor);
        address actualNFTDescriptor = address(flow.nftDescriptor());
        address expectedNFTDescriptor = address(newNFTDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");
    }
}
