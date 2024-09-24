// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 internal immutable DECIMAL;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        DECIMAL = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return DECIMAL;
    }
}
