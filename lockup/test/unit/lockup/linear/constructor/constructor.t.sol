// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract Constructor_Linear_Unit_Test is Linear_Unit_Test {
    function test_Constructor() external {
        // Expect a {TransferEvent} to be emitted.
        vm.expectEmit();
        emit TransferAdmin({ oldAdmin: address(0), newAdmin: users.admin });

        // Construct the linear contract.
        SablierV2LockupLinear constructedLinear = new SablierV2LockupLinear({
            initialAdmin: users.admin,
            initialComptroller: comptroller,
            initialNFTDescriptor: nftDescriptor
        });

        // {SablierV2-constructor}
        address actualAdmin = constructedLinear.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualComptroller = address(constructedLinear.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");

        // {SablierV2Lockup-constructor}
        uint256 actualStreamId = constructedLinear.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");
    }
}
