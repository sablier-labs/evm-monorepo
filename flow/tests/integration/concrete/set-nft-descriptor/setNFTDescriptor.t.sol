// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract SetNFTDescriptor_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        flow.setNFTDescriptor(FlowNFTDescriptor(users.eve));
    }

    function test_WhenNewAndOldNFTDescriptorsAreSame() external whenCallerComptroller {
        // It should emit 1 {SetNFTDescriptor} and 1 {BatchMetadataUpdate} events
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.SetNFTDescriptor(comptroller, nftDescriptor, nftDescriptor);
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        // It should re-set the NFT descriptor
        flow.setNFTDescriptor(nftDescriptor);
        vm.expectCall(address(nftDescriptor), abi.encodeCall(FlowNFTDescriptor.tokenURI, (flow, 1)));
        flow.tokenURI(defaultStreamId);
    }

    function test_WhenNewAndOldNFTDescriptorsAreNotSame() external whenCallerComptroller {
        // Deploy another NFT descriptor.
        FlowNFTDescriptor newNFTDescriptor = new FlowNFTDescriptor();

        // It should emit 1 {SetNFTDescriptor} and 1 {BatchMetadataUpdate} events
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.SetNFTDescriptor(comptroller, nftDescriptor, newNFTDescriptor);
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        // It should set the new NFT descriptor
        flow.setNFTDescriptor(newNFTDescriptor);
        address actualNFTDescriptor = address(flow.nftDescriptor());
        address expectedNFTDescriptor = address(newNFTDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");
    }
}
