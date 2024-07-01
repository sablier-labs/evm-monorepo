// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { NFTDescriptor_Integration_Shared_Test } from "../../../shared/nft-descriptor/NFTDescriptor.t.sol";

contract IsAllowedCharacter_Integration_Concrete_Test is NFTDescriptor_Integration_Shared_Test {
    function test_IsAllowedCharacter_EmptyString() external view {
        string memory symbol = "";
        bool result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");
    }

    modifier whenNotEmptyString() {
        _;
    }

    function test_IsAllowedCharacter_ContainsUnsupportedCharacters() external view whenNotEmptyString {
        string memory symbol = "<foo/>";
        bool result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo/";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo\\";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo%";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo&";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo(";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo)";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo\"";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo'";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo`";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo;";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo%20"; // URL-encoded empty space
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");
    }

    modifier whenOnlySupportedCharacters() {
        _;
    }

    function test_IsAllowedCharacter() external view whenNotEmptyString whenOnlySupportedCharacters {
        string memory symbol = "foo";
        bool result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Foo";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Foo ";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Foo Bar";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Bar-Foo";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "  ";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "foo01234";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "123456789";
        result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");
    }
}
