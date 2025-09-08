// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Base_Test } from "tests/Base.t.sol";

contract IsAllowedCharacter_Integration_Concrete_Test is Base_Test {
    function test_WhenEmptyString() external view {
        string memory symbol = "";
        bool result = nftDescriptorMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");
    }

    function test_GivenUnsupportedCharacters() external view whenNotEmptyString {
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

    function test_GivenSupportedCharacters() external view whenNotEmptyString {
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
