// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

library ChainId {
    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns `true` if the given chain ID is supported.
    function isSupported(uint256 chainId) internal pure returns (bool) {
        bool isMainnet = chainId == ABSTRACT || chainId == ARBITRUM || chainId == AVALANCHE || chainId == BASE
            || chainId == BERACHAIN || chainId == BLAST || chainId == BSC || chainId == CHILIZ || chainId == COREDAO
            || chainId == ETHEREUM || chainId == GNOSIS || chainId == HYPEREVM || chainId == LIGHTLINK || chainId == LINEA
            || chainId == MODE || chainId == MORPH || chainId == OPTIMISM || chainId == POLYGON || chainId == SCROLL
            || chainId == SEI || chainId == SOPHON || chainId == SUPERSEED || chainId == SONIC || chainId == UNICHAIN
            || chainId == XDC || chainId == ZKSYNC;

        bool isTestnet = chainId == ARBITRUM_SEPOLIA || chainId == BASE_SEPOLIA || chainId == MODE_SEPOLIA
            || chainId == OPTIMISM_SEPOLIA || chainId == SEPOLIA;

        return isMainnet || isTestnet;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MAINNETS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant ABSTRACT = 2741;
    uint256 public constant ARBITRUM = 42_161;
    uint256 public constant AVALANCHE = 43_114;
    uint256 public constant BASE = 8453;
    uint256 public constant BERACHAIN = 80_094;
    uint256 public constant BLAST = 81_457;
    uint256 public constant BSC = 56;
    uint256 public constant CHILIZ = 88_888;
    uint256 public constant COREDAO = 1116;
    uint256 public constant ETHEREUM = 1;
    uint256 public constant GNOSIS = 100;
    uint256 public constant HYPEREVM = 999;
    uint256 public constant LIGHTLINK = 1890;
    uint256 public constant LINEA = 59_144;
    uint256 public constant MODE = 34_443;
    uint256 public constant MORPH = 2818;
    uint256 public constant OPTIMISM = 10;
    uint256 public constant POLYGON = 137;
    uint256 public constant SCROLL = 534_352;
    uint256 public constant SEI = 1329;
    uint256 public constant SONIC = 146;
    uint256 public constant SOPHON = 50_104;
    uint256 public constant SUPERSEED = 5330;
    uint256 public constant TANGLE = 5845;
    uint256 public constant UNICHAIN = 130;
    uint256 public constant XDC = 50;
    uint256 public constant ZKSYNC = 324;

    /*//////////////////////////////////////////////////////////////////////////
                                      TESTNETS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant ARBITRUM_SEPOLIA = 421_614;
    uint256 public constant BASE_SEPOLIA = 84_532;
    uint256 public constant MODE_SEPOLIA = 919;
    uint256 public constant OPTIMISM_SEPOLIA = 11_155_420;
    uint256 public constant SEPOLIA = 11_155_111;
}
