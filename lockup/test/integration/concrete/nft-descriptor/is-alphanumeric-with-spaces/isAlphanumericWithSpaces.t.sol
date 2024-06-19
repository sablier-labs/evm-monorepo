// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { NFTDescriptor_Integration_Shared_Test } from "../../../shared/nft-descriptor/NFTDescriptor.t.sol";

contract IsAlphanumericWithSpaces_Integration_Concrete_Test is NFTDescriptor_Integration_Shared_Test {
    function test_IsAlphanumericWithSpaces_EmptyString() external view {
        string memory symbol = "";
        bool result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");
    }

    modifier whenNotEmptyString() {
        _;
    }

    function test_IsAlphanumericWithSpaces_ContainsUnsupportedCharacters() external view whenNotEmptyString {
        string memory symbol = "<foo/>";
        bool result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo/";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo\\";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo%";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo&";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo(";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo)";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo\"";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo'";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo`";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo;";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");

        symbol = "foo%20"; // URL-encoded empty space
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertFalse(result, "isAlphanumericWithSpaces");
    }

    modifier whenOnlySupportedCharacters() {
        _;
    }

    function test_IsAlphanumericWithSpaces() external view whenNotEmptyString whenOnlySupportedCharacters {
        string memory symbol = "foo";
        bool result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");

        symbol = "Foo";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");

        symbol = "Foo ";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");

        symbol = "Foo Bar";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");

        symbol = "  ";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");

        symbol = "foo01234";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");

        symbol = "123456789";
        result = nftDescriptorMock.isAlphanumericWithSpaces_(symbol);
        assertTrue(result, "isAlphanumericWithSpaces");
    }
}
