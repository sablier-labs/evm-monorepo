// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title SafeTokenSymbol
/// @notice Library with helper functions for safely retrieving an ERC-20 token symbols, preventing JS injection.
library SafeTokenSymbol {
    /// @notice Checks whether the provided string contains only alphanumeric characters, spaces, and dashes.
    /// @dev Note that this returns true for empty strings.
    function isAllowedCharacter(string memory str) internal pure returns (bool) {
        // Convert the string to bytes to iterate over its characters.
        bytes memory b = bytes(str);

        uint256 length = b.length;
        for (uint256 i = 0; i < length; ++i) {
            bytes1 char = b[i];

            // Check if it's a space, dash, or an alphanumeric character.
            bool isSpace = char == 0x20; // space
            bool isDash = char == 0x2D; // dash
            bool isDigit = char >= 0x30 && char <= 0x39; // 0-9
            bool isUppercaseLetter = char >= 0x41 && char <= 0x5A; // A-Z
            bool isLowercaseLetter = char >= 0x61 && char <= 0x7A; // a-z
            if (!(isSpace || isDash || isDigit || isUppercaseLetter || isLowercaseLetter)) {
                return false;
            }
        }
        return true;
    }

    /// @notice Sanitizes the token symbol to prevent security threats from malicious tokens injecting scripts in the
    /// symbol string.
    function sanitizedTokenSymbol(string memory symbol) internal pure returns (string memory) {
        // Check if the symbol is too long or contains disallowed characters. This measure helps mitigate potential
        // security threats from malicious tokens injecting scripts in the symbol string.
        if (bytes(symbol).length > 30) {
            return "Long Symbol";
        }
        if (!isAllowedCharacter(symbol)) {
            return "Unsupported Symbol";
        }
        return symbol;
    }

    /// @notice Retrieves the token's symbol safely, defaulting to a hard-coded value if an error occurs.
    /// @dev Performs a low-level call to handle tokens in which the symbol is not implemented or it is a bytes32
    /// instead of a string.
    function safeTokenSymbol(address token) internal view returns (string memory) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeCall(IERC20Metadata.symbol, ()));

        // Non-empty strings have a length greater than 64, and bytes32 has length 32.
        if (!success || returnData.length <= 64) {
            return "ERC20";
        }

        string memory symbol = abi.decode(returnData, (string));

        return sanitizedTokenSymbol(symbol);
    }
}
