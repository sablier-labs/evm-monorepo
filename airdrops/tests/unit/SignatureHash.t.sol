// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SignatureHash } from "src/libraries/SignatureHash.sol";

import { Base_Test } from "../Base.t.sol";

contract SignatureHash_Integration_Test is Base_Test {
    function test_Constants() external pure {
        assertEq(SignatureHash.PROTOCOL_NAME, keccak256("Sablier Airdrops Protocol"));
        assertEq(
            SignatureHash.CLAIM_TYPEHASH, keccak256("Claim(uint256 index,address recipient,address to,uint128 amount)")
        );
        assertEq(
            SignatureHash.DOMAIN_TYPEHASH,
            keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
        );
    }
}
