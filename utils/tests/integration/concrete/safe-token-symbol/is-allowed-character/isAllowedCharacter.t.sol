// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Base_Test } from "../../../../Base.t.sol";

contract IsAllowedCharacter_SafeTokenSymbol_Concrete_Test is Base_Test {
    function test_WhenEmptyString() external view {
        // It should return true.
        string memory symbol = "";
        bool result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");
    }

    function test_GivenUnsupportedCharacters() external view whenNotEmptyString {
        // It should return false.
        string memory symbol = "<foo/>";
        bool result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo/";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo\\";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo%";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo&";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo(";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo)";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo\"";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo'";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo`";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo;";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");

        symbol = "foo%20"; // URL-encoded empty space
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertFalse(result, "isAllowedCharacter");
    }

    function test_GivenSupportedCharacters() external view whenNotEmptyString {
        // It should return true.
        string memory symbol = "foo";
        bool result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Foo";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Foo ";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Foo Bar";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "Bar-Foo";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "  ";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "foo01234";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");

        symbol = "123456789";
        result = safeTokenSymbolMock.isAllowedCharacter_(symbol);
        assertTrue(result, "isAllowedCharacter");
    }
}
