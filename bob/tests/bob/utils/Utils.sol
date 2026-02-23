// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";

abstract contract Utils is BaseUtils {
    using Strings for uint256;

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
        return string.concat(
            tokenSymbol, "-", targetPrice.toString(), "-", uint256(expiry).toString(), "-", vaultId.toString()
        );
    }
}
