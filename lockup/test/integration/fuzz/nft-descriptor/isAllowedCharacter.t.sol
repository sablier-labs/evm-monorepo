// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { NFTDescriptor_Integration_Shared_Test } from "../../shared/nft-descriptor/NFTDescriptor.t.sol";

contract IsAllowedCharacter_Integration_Fuzz_Test is NFTDescriptor_Integration_Shared_Test {
    bytes1 internal constant SPACE = 0x20; // ASCII 32
    bytes1 internal constant DASH = 0x2D; // ASCII 45
    bytes1 internal constant ZERO = 0x30; // ASCII 48
    bytes1 internal constant NINE = 0x39; // ASCII 57
    bytes1 internal constant A = 0x41; // ASCII 65
    bytes1 internal constant Z = 0x5A; // ASCII 90
    bytes1 internal constant a = 0x61; // ASCII 97
    bytes1 internal constant z = 0x7A; // ASCII 122

    modifier whenNotEmptyString() {
        _;
    }

    /// @dev Given enough fuzz runs, all the following scenarios will be fuzzed:
    ///
    /// - String with only alphanumerical characters
    /// - String with only non-alphanumerical characters
    /// - String with both alphanumerical and non-alphanumerical characters
    function testFuzz_IsAllowedCharacter(string memory symbol) external view whenNotEmptyString {
        bytes memory b = bytes(symbol);
        uint256 length = b.length;
        bool expectedResult = true;
        for (uint256 i = 0; i < length; ++i) {
            bytes1 char = b[i];
            if (!isAlphanumericOrSpaceChar(char)) {
                expectedResult = false;
                break;
            }
        }
        bool actualResult = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertEq(actualResult, expectedResult, "isAllowedCharacter");
    }

    function isAlphanumericOrSpaceChar(bytes1 char) internal pure returns (bool) {
        bool isSpace = char == SPACE;
        bool isDash = char == DASH;
        bool isDigit = char >= ZERO && char <= NINE;
        bool isUppercaseLetter = char >= A && char <= Z;
        bool isLowercaseLetter = char >= a && char <= z;
        return isSpace || isDash || isDigit || isUppercaseLetter || isLowercaseLetter;
    }
}
