// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ERC20Bytes32 } from "src/mocks/erc20/ERC20Bytes32.sol";
import { ERC20Mock } from "src/mocks/erc20/ERC20Mock.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SafeTokenSymbol_SafeTokenSymbol_Concrete_Test is Base_Test {
    function test_WhenTokenNotContract() external view {
        // It should return ERC20.
        address eoa = vm.addr({ privateKey: 1 });
        string memory actualSymbol = safeTokenSymbolMock.safeTokenSymbol_(address(eoa));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolNotImplemented() external view whenTokenContract {
        // It should return ERC20.
        string memory actualSymbol = safeTokenSymbolMock.safeTokenSymbol_(address(noop));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolAsBytes32() external whenTokenContract givenSymbolImplemented {
        // It should return ERC20.
        ERC20Bytes32 token = new ERC20Bytes32();
        string memory actualSymbol = safeTokenSymbolMock.safeTokenSymbol_(address(token));
        string memory expectedSymbol = "ERC20";
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }

    function test_GivenSymbolLongerThan30Chars() external whenTokenContract givenSymbolImplemented givenSymbolAsString {
        // It should return Long Symbol.
        ERC20Mock token = new ERC20Mock({
            name_: "Token",
            symbol_: "This symbol is has more than 30 characters and it should be ignored",
            decimals_: 18
        });
        string memory actualSymbol = safeTokenSymbolMock.safeTokenSymbol_(address(token));
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
        // It should return Unsupported Symbol.
        ERC20Mock token = new ERC20Mock({ name_: "Token", symbol_: "<svg/onload=alert(\"xss\")>", decimals_: 18 });
        string memory actualSymbol = safeTokenSymbolMock.safeTokenSymbol_(address(token));
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
        // It should return the symbol.
        string memory actualSymbol = safeTokenSymbolMock.safeTokenSymbol_(address(dai));
        string memory expectedSymbol = dai.symbol();
        assertEq(actualSymbol, expectedSymbol, "symbol");
    }
}
