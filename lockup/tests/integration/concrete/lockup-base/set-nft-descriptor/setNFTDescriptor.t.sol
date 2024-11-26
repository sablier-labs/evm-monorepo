// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { ILockupNFTDescriptor } from "src/interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockupBase } from "src/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { LockupNFTDescriptor } from "src/LockupNFTDescriptor.sol";
import { Integration_Test } from "../../../Integration.t.sol";

contract SetNFTDescriptor_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        resetPrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        lockup.setNFTDescriptor(ILockupNFTDescriptor(users.eve));
    }

    function test_WhenProvidedAddressMatchesCurrentNFTDescriptor() external whenCallerAdmin {
        // It should emit {SetNFTDescriptor} and {BatchMetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.SetNFTDescriptor(users.admin, nftDescriptor, nftDescriptor);
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: lockup.nextStreamId() - 1 });

        // Re-set the NFT descriptor.
        lockup.setNFTDescriptor(nftDescriptor);

        // It should re-set the NFT descriptor.
        vm.expectCall(address(nftDescriptor), abi.encodeCall(ILockupNFTDescriptor.tokenURI, (lockup, defaultStreamId)));
        lockup.tokenURI({ tokenId: defaultStreamId });
    }

    function test_WhenProvidedAddressNotMatchCurrentNFTDescriptor() external whenCallerAdmin {
        // Deploy another NFT descriptor.
        ILockupNFTDescriptor newNFTDescriptor = new LockupNFTDescriptor();

        // It should emit {SetNFTDescriptor} and {BatchMetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.SetNFTDescriptor(users.admin, nftDescriptor, newNFTDescriptor);
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: lockup.nextStreamId() - 1 });

        // Set the new NFT descriptor.
        lockup.setNFTDescriptor(newNFTDescriptor);

        // It should set the new NFT descriptor.
        vm.expectCall(address(newNFTDescriptor), abi.encodeCall(ILockupNFTDescriptor.tokenURI, (lockup, 1)));
        lockup.tokenURI({ tokenId: defaultStreamId });
    }
}
