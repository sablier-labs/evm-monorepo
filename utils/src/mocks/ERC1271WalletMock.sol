// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Adminable } from "../../src/Adminable.sol";

contract ERC1271WalletMock is Adminable {
    constructor(address initialAdmin) Adminable(initialAdmin) { }

    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4 magicValue) {
        return
            ECDSA.recover(hash, signature) == admin ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : bytes4(0);
    }
}
