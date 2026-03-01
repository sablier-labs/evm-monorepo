// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { ICurveStETHPool } from "src/interfaces/external/ICurveStETHPool.sol";
import { IStETH } from "src/interfaces/external/IStETH.sol";

/// @notice Mock Curve stETH/ETH pool for testing with configurable slippage simulation.
contract MockCurvePool is ICurveStETHPool {
    address public immutable STETH;

    /// @dev Slippage in UD60x18, where 1e18 = 100%.
    UD60x18 public actualSlippage;

    /// @dev A private variable to simulate a scenario where the amount exchanged is less than the output received by
    /// the `get_dy` function.
    uint256 private _diff;

    constructor(address stETH_) {
        STETH = stETH_;
    }

    function exchange(int128, int128, uint256 dx, uint256) external payable override returns (uint256) {
        IStETH(STETH).transferFrom(msg.sender, address(this), dx);

        uint256 actualOutput = get_dy(int128(1), int128(0), dx) - _diff;

        (bool success,) = msg.sender.call{ value: actualOutput }("");
        require(success, "ETH transfer failed");
        return actualOutput;
    }

    function get_dy(int128, int128, uint256 dx) public view override returns (uint256) {
        return ud(dx).mul(UNIT.sub(actualSlippage)).intoUint256();
    }

    function setActualSlippage(UD60x18 newSlippage) external {
        actualSlippage = newSlippage;
    }

    function setDiff(uint256 diff) external {
        _diff = diff;
    }

    receive() external payable { }
}
