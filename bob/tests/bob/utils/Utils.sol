// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";

abstract contract Utils is BaseUtils {
    using Strings for uint256;

    /// @dev Calculates the minimum ETH output after applying slippage tolerance.
    function calculateMinEthOut(uint256 amount, UD60x18 slippageTolerance) internal pure returns (uint128) {
        return ud(amount).mul(UNIT.sub(slippageTolerance)).intoUint128();
    }

    /// @dev Decomposes a yield-bearing redemption into fee and net amount.
    function calculateYieldBreakdown(
        uint128 wethRedeemed,
        uint128 depositAmount,
        UD60x18 yieldFee
    )
        internal
        pure
        returns (uint128 fee, uint128 netAmount)
    {
        uint128 yield_ = wethRedeemed - depositAmount;
        fee = ud(yield_).mul(yieldFee).intoUint128();
        netAmount = wethRedeemed - fee;
    }

    /// @dev Calculates the expected WETH received from unwrapping wstETH using the provided exchange rate.
    function expectedWethFromWstEth(uint128 wstEthAmount, UD60x18 exchangeRate) internal pure returns (uint128) {
        return ud(wstEthAmount).div(exchangeRate).intoUint128();
    }

    /// @dev Generates the expected vault share token name.
    function generateVaultName(string memory tokenSymbol, uint256 vaultId) internal pure returns (string memory) {
        return string.concat("Sablier Bob ", tokenSymbol, " Vault #", vaultId.toString());
    }

    /// @dev Generates the expected vault share token symbol.
    function generateVaultSymbol(
        string memory tokenSymbol,
        uint256 targetPrice,
        uint256 expiry,
        uint256 vaultId
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(tokenSymbol, "-", targetPrice.toString(), "-", expiry.toString(), "-", vaultId.toString());
    }
}
