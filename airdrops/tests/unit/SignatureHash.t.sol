// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SignatureHash } from "src/libraries/SignatureHash.sol";

import { Base_Test } from "../Base.t.sol";

contract SignatureHash_Integration_Unit_Test is Base_Test {
    function test_Constants() external pure {
        assertEq(SignatureHash.PROTOCOL_NAME, keccak256("Sablier Airdrops Protocol"));
        assertEq(SignatureHash.CLAIM_TYPEHASH, vm.eip712HashType(SCHEMA_CLAIM));
        assertEq(SignatureHash.DOMAIN_TYPEHASH, vm.eip712HashType(SCHEMA_EIP712_DOMAIN));
    }
}
