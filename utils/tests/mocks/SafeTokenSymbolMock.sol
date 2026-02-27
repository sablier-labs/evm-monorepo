// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SafeTokenSymbol } from "src/libraries/SafeTokenSymbol.sol";

/// @dev This mock exposes the internal library functions as external for testing.
contract SafeTokenSymbolMock {
    function isAllowedCharacter_(string calldata str) external pure returns (bool) {
        return SafeTokenSymbol.isAllowedCharacter(str);
    }

    function safeTokenSymbol_(address token) external view returns (string memory) {
        return SafeTokenSymbol.safeTokenSymbol(token);
    }
}
