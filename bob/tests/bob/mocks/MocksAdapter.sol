// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ICurveStETHPool } from "src/interfaces/external/ICurveStETHPool.sol";
import { IStETH } from "src/interfaces/external/IStETH.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IWstETH } from "src/interfaces/external/IWstETH.sol";

/*//////////////////////////////////////////////////////////////////////////
                                  MOCK WETH9
//////////////////////////////////////////////////////////////////////////*/

/// @title MockWETH9
/// @notice Mock WETH9 for testing.
contract MockWETH9 is ERC20, IWETH9 {
    constructor() ERC20("Wrapped Ether", "WETH") { }

    function deposit() external payable override {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external override {
        _burn(msg.sender, amount);
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                  MOCK STETH
//////////////////////////////////////////////////////////////////////////*/

/// @title MockStETH
/// @notice Mock stETH for testing.
contract MockStETH is ERC20, IStETH {
    constructor() ERC20("Liquid staked Ether 2.0", "stETH") { }

    function submit(address) external payable override returns (uint256) {
        _mint(msg.sender, msg.value);
        return msg.value;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                 MOCK WSTETH
//////////////////////////////////////////////////////////////////////////*/

/// @title MockWstETH
/// @notice Mock wstETH for testing with configurable exchange rate.
contract MockWstETH is ERC20, IWstETH {
    address public immutable STETH;
    uint256 public exchangeRate = 0.9e18;

    constructor(address stETH_) ERC20("Wrapped liquid staked Ether 2.0", "wstETH") {
        STETH = stETH_;
    }

    function wrap(uint256 stETHAmount) external override returns (uint256 wstETHAmount) {
        IStETH(STETH).transferFrom(msg.sender, address(this), stETHAmount);
        wstETHAmount = (stETHAmount * exchangeRate) / 1e18;
        _mint(msg.sender, wstETHAmount);
    }

    function unwrap(uint256 wstETHAmount) external override returns (uint256 stETHAmount) {
        _burn(msg.sender, wstETHAmount);
        stETHAmount = (wstETHAmount * 1e18) / exchangeRate;
        MockStETH(payable(STETH)).mint(msg.sender, stETHAmount);
    }

    function getStETHByWstETH(uint256 wstETHAmount) external view override returns (uint256) {
        return (wstETHAmount * 1e18) / exchangeRate;
    }

    function getWstETHByStETH(uint256 stETHAmount) external view override returns (uint256) {
        return (stETHAmount * exchangeRate) / 1e18;
    }

    function setExchangeRate(uint256 rate) external {
        exchangeRate = rate;
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                  MOCK CURVE POOL
//////////////////////////////////////////////////////////////////////////*/

/// @title MockCurvePool
/// @notice Mock Curve stETH/ETH pool for testing with configurable slippage simulation.
contract MockCurvePool is ICurveStETHPool {
    address public immutable STETH;

    /// @dev Slippage in basis points (e.g., 100 = 1% less than expected).
    uint256 public actualSlippage;

    constructor(address stETH_) {
        STETH = stETH_;
    }

    function exchange(int128, int128, uint256 dx, uint256) external payable override returns (uint256) {
        IStETH(STETH).transferFrom(msg.sender, address(this), dx);

        // Calculate actual output with slippage simulation.
        uint256 actualOutput = (dx * (10_000 - actualSlippage)) / 10_000;

        (bool success,) = msg.sender.call{ value: actualOutput }("");
        require(success, "ETH transfer failed");
        return actualOutput;
    }

    function get_dy(int128, int128, uint256 dx) external pure override returns (uint256) {
        // Always returns the expected 1:1 rate (no slippage in the quote).
        return dx;
    }

    /// @notice Sets the slippage to simulate during exchanges.
    /// @param slippageBps Slippage in basis points (e.g., 100 = 1% less output).
    function setActualSlippage(uint256 slippageBps) external {
        actualSlippage = slippageBps;
    }

    receive() external payable { }
}
