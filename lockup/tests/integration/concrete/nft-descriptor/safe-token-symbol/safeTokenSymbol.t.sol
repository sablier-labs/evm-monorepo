// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Base_Test } from "tests/Base.t.sol";
import { ERC20Bytes32 } from "tests/mocks/erc20/ERC20Bytes32.sol";
import { ERC20Mock } from "tests/mocks/erc20/ERC20Mock.sol";

contract SafeTokenSymbol_Integration_Concrete_Test is Base_Test {
    function test_WhenTokenNotContract() external view {
        address eoa = vm.addr({ privateKey: 1 });
        string memory actualSymbol = nftDescriptorMock.safeTokenSymbol_(address(eoa));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolNotImplemented() external view whenTokenContract {
        string memory actualSymbol = nftDescriptorMock.safeTokenSymbol_(address(noop));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolAsBytes32() external whenTokenContract givenSymbolImplemented {
        ERC20Bytes32 token = new ERC20Bytes32();
        string memory actualSymbol = nftDescriptorMock.safeTokenSymbol_(address(token));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolLongerThan30Chars()
        external
        whenTokenContract
        givenSymbolImplemented
        givenSymbolAsString
    {
        ERC20Mock token = new ERC20Mock({
            name: "Token",
            symbol: "This symbol is has more than 30 characters and it should be ignored"
        });
        string memory actualSymbol = nftDescriptorMock.safeTokenSymbol_(address(token));
        string memory expectedSymbol = "Long Symbol";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolContainsNon_alphanumericChars()
        external
        whenTokenContract
        givenSymbolImplemented
        givenSymbolAsString
        givenSymbolNotLongerThan30Chars
    {
        ERC20Mock token = new ERC20Mock({ name: "Token", symbol: "<svg/onload=alert(\"xss\")>" });
        string memory actualSymbol = nftDescriptorMock.safeTokenSymbol_(address(token));
        string memory expectedSymbol = "Unsupported Symbol";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolContainsAlphanumericChars()
        external
        view
        whenTokenContract
        givenSymbolImplemented
        givenSymbolAsString
        givenSymbolNotLongerThan30Chars
    {
        string memory actualSymbol = nftDescriptorMock.safeTokenSymbol_(address(dai));
        string memory expectedSymbol = dai.symbol();
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }
}
