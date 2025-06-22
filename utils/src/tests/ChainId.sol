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
            || chainId == ETHEREUM || chainId == FORM || chainId == GNOSIS || chainId == IOTEX || chainId == LIGHTLINK
            || chainId == LINEA || chainId == MODE || chainId == MORPH || chainId == OPTIMISM || chainId == POLYGON
            || chainId == SCROLL || chainId == SEI || chainId == SOPHON || chainId == SUPERSEED || chainId == TAIKO
            || chainId == TANGLE || chainId == ULTRA || chainId == UNICHAIN || chainId == XDC || chainId == ZKSYNC;

        bool isTestnet = chainId == ARBITRUM_SEPOLIA || chainId == BASE_SEPOLIA || chainId == BLAST_SEPOLIA
            || chainId == ETHEREUM_SEPOLIA || chainId == LINEA_SEPOLIA || chainId == MODE_SEPOLIA
            || chainId == MONAD_TESTNET || chainId == OPTIMISM_SEPOLIA || chainId == SUPERSEED_SEPOLIA
            || chainId == TAIKO_HEKLA || chainId == ZKSYNC_SEPOLIA;

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
    uint256 public constant FORM = 478;
    uint256 public constant GNOSIS = 100;
    uint256 public constant IOTEX = 4689;
    uint256 public constant LIGHTLINK = 1890;
    uint256 public constant LINEA = 59_144;
    uint256 public constant MODE = 34_443;
    uint256 public constant MORPH = 2818;
    uint256 public constant OPTIMISM = 10;
    uint256 public constant POLYGON = 137;
    uint256 public constant SCROLL = 534_352;
    uint256 public constant SEI = 1329;
    uint256 public constant SOPHON = 50_104;
    uint256 public constant SUPERSEED = 5330;
    uint256 public constant TAIKO = 167_000;
    uint256 public constant TANGLE = 5845;
    uint256 public constant ULTRA = 19_991;
    uint256 public constant UNICHAIN = 130;
    uint256 public constant XDC = 50;
    uint256 public constant ZKSYNC = 324;

    /*//////////////////////////////////////////////////////////////////////////
                                      TESTNETS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant ARBITRUM_SEPOLIA = 421_614;
    uint256 public constant BASE_SEPOLIA = 84_532;
    uint256 public constant BLAST_SEPOLIA = 168_587_773;
    uint256 public constant ETHEREUM_SEPOLIA = 11_155_111;
    uint256 public constant LINEA_SEPOLIA = 59_141;
    uint256 public constant MODE_SEPOLIA = 919;
    uint256 public constant MONAD_TESTNET = 10_143;
    uint256 public constant OPTIMISM_SEPOLIA = 11_155_420;
    uint256 public constant SUPERSEED_SEPOLIA = 53_302;
    uint256 public constant TAIKO_HEKLA = 167_009;
    uint256 public constant ZKSYNC_SEPOLIA = 300;
}
