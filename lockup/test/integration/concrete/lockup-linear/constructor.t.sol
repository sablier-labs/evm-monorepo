// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";

import { LockupLinear_Integration_Concrete_Test } from "./LockupLinear.t.sol";

contract Constructor_LockupLinear_Integration_Concrete_Test is LockupLinear_Integration_Concrete_Test {
    function test_Constructor() external {
        // Expect the relevant event to be emitted.
        vm.expectEmit();
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the contract.
        SablierV2LockupLinear constructedLockupLinear = new SablierV2LockupLinear({
            initialAdmin: users.admin,
            initialComptroller: comptroller,
            initialNFTDescriptor: nftDescriptor
        });

        // {SablierV2Base.constructor}
        address actualAdmin = constructedLockupLinear.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(constructedLockupLinear.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        // {SablierV2Lockup.constructor}
        uint256 actualStreamId = constructedLockupLinear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");
    }
}
