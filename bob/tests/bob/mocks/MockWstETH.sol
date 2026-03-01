// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { IStETH } from "src/interfaces/external/IStETH.sol";
import { IWstETH } from "src/interfaces/external/IWstETH.sol";

import { MockStETH } from "./MockStETH.sol";

/// @notice Mock wstETH token contract with configurable exchange rate.
contract MockWstETH is ERC20, IWstETH {
    address public immutable STETH;

    /// @dev Exchange rate of wstETH to stETH, where 1e18 = 100%.
    UD60x18 public exchangeRate = UD60x18.wrap(0.9e18);

    constructor(address stETH_) ERC20("Wrapped liquid staked Ether 2.0", "wstETH") {
        STETH = stETH_;
    }

    function wrap(uint256 stETHAmount) external override returns (uint256 wstETHAmount) {
        IStETH(STETH).transferFrom(msg.sender, address(this), stETHAmount);
        wstETHAmount = ud(stETHAmount).mul(exchangeRate).intoUint256();
        _mint(msg.sender, wstETHAmount);
    }

    function unwrap(uint256 wstETHAmount) external override returns (uint256 stETHAmount) {
        _burn(msg.sender, wstETHAmount);
        stETHAmount = ud(wstETHAmount).div(exchangeRate).intoUint256();
        MockStETH(payable(STETH)).mint(msg.sender, stETHAmount);
    }

    function getStETHByWstETH(uint256 wstETHAmount) external view override returns (uint256) {
        return ud(wstETHAmount).div(exchangeRate).intoUint256();
    }

    function getWstETHByStETH(uint256 stETHAmount) external view override returns (uint256) {
        return ud(stETHAmount).mul(exchangeRate).intoUint256();
    }

    function setExchangeRate(UD60x18 newExchangeRate) external {
        exchangeRate = newExchangeRate;
    }
}
