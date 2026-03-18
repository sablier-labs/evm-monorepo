// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable code-complexity
pragma solidity >=0.8.22;

library ChainId {
    /*//////////////////////////////////////////////////////////////////////////
                                      MAINNETS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant MAINNETS_COUNT = 24;

    uint256 public constant ABSTRACT = 2741;
    uint256 public constant ARBITRUM = 42_161;
    uint256 public constant AVALANCHE = 43_114;
    uint256 public constant BASE = 8453;
    uint256 public constant BERACHAIN = 80_094;
    uint256 public constant BSC = 56;
    uint256 public constant CHILIZ = 88_888;
    uint256 public constant DENERGY = 369_369;
    uint256 public constant ETHEREUM = 1;
    uint256 public constant GNOSIS = 100;
    uint256 public constant HYPEREVM = 999;
    uint256 public constant LIGHTLINK = 1890;
    uint256 public constant LINEA = 59_144;
    uint256 public constant MODE = 34_443;
    uint256 public constant MONAD = 143;
    uint256 public constant MORPH = 2818;
    uint256 public constant OPTIMISM = 10;
    uint256 public constant POLYGON = 137;
    uint256 public constant SCROLL = 534_352;
    uint256 public constant SONIC = 146;
    uint256 public constant SUPERSEED = 5330;
    uint256 public constant UNICHAIN = 130;
    uint256 public constant XDC = 50;
    uint256 public constant ZKSYNC = 324;

    /*//////////////////////////////////////////////////////////////////////////
                                      TESTNETS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant TESTNETS_COUNT = 4;

    uint256 public constant ARBITRUM_SEPOLIA = 421_614;
    uint256 public constant BASE_SEPOLIA = 84_532;
    uint256 public constant OPTIMISM_SEPOLIA = 11_155_420;
    uint256 public constant SEPOLIA = 11_155_111;

    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the full list of supported mainnet chain IDs.
    function getAllMainnets() internal pure returns (uint256[] memory supportedIds) {
        supportedIds = new uint256[](MAINNETS_COUNT);

        supportedIds[0] = ABSTRACT;
        supportedIds[1] = ARBITRUM;
        supportedIds[2] = AVALANCHE;
        supportedIds[3] = BASE;
        supportedIds[4] = BERACHAIN;
        supportedIds[5] = BSC;
        supportedIds[6] = CHILIZ;
        supportedIds[7] = DENERGY;
        supportedIds[8] = ETHEREUM;
        supportedIds[9] = GNOSIS;
        supportedIds[10] = HYPEREVM;
        supportedIds[11] = LIGHTLINK;
        supportedIds[12] = LINEA;
        supportedIds[13] = MODE;
        supportedIds[14] = MONAD;
        supportedIds[15] = MORPH;
        supportedIds[16] = OPTIMISM;
        supportedIds[17] = POLYGON;
        supportedIds[18] = SCROLL;
        supportedIds[19] = SONIC;
        supportedIds[20] = SUPERSEED;
        supportedIds[21] = UNICHAIN;
        supportedIds[22] = XDC;
        supportedIds[23] = ZKSYNC;
    }

    /// @notice Returns the full list of supported testnet chain IDs.
    function getAllTestnets() internal pure returns (uint256[] memory supportedIds) {
        supportedIds = new uint256[](TESTNETS_COUNT);

        supportedIds[0] = ARBITRUM_SEPOLIA;
        supportedIds[1] = BASE_SEPOLIA;
        supportedIds[2] = OPTIMISM_SEPOLIA;
        supportedIds[3] = SEPOLIA;
    }

    /// @notice Returns the chain name for the given chain ID.
    function getName(uint256 chainId) internal pure returns (string memory chainName) {
        // Mainnets.
        if (chainId == ChainId.ABSTRACT) return "abstract";
        if (chainId == ChainId.ARBITRUM) return "arbitrum";
        if (chainId == ChainId.AVALANCHE) return "avalanche";
        if (chainId == ChainId.BASE) return "base";
        if (chainId == ChainId.BERACHAIN) return "berachain";
        if (chainId == ChainId.BSC) return "bsc";
        if (chainId == ChainId.CHILIZ) return "chiliz";
        if (chainId == ChainId.DENERGY) return "denergy";
        if (chainId == ChainId.ETHEREUM) return "ethereum";
        if (chainId == ChainId.GNOSIS) return "gnosis";
        if (chainId == ChainId.HYPEREVM) return "hyperevm";
        if (chainId == ChainId.LIGHTLINK) return "lightlink";
        if (chainId == ChainId.LINEA) return "linea";
        if (chainId == ChainId.MODE) return "mode";
        if (chainId == ChainId.MONAD) return "monad";
        if (chainId == ChainId.MORPH) return "morph";
        if (chainId == ChainId.OPTIMISM) return "optimism";
        if (chainId == ChainId.POLYGON) return "polygon";
        if (chainId == ChainId.SCROLL) return "scroll";
        if (chainId == ChainId.SONIC) return "sonic";
        if (chainId == ChainId.SUPERSEED) return "superseed";
        if (chainId == ChainId.UNICHAIN) return "unichain";
        if (chainId == ChainId.XDC) return "xdc";
        if (chainId == ChainId.ZKSYNC) return "zksync";

        // Testnets.
        if (chainId == ChainId.ARBITRUM_SEPOLIA) return "arbitrum_sepolia";
        if (chainId == ChainId.BASE_SEPOLIA) return "base_sepolia";
        if (chainId == ChainId.OPTIMISM_SEPOLIA) return "optimism_sepolia";
        if (chainId == ChainId.SEPOLIA) return "sepolia";
    }

    /// @notice Returns `true` if the given chain ID is supported.
    function isSupported(uint256 chainId) internal pure returns (bool) {
        // Return true if the chain ID is in the mainnet list.
        uint256[] memory mainnets = getAllMainnets();
        for (uint256 i = 0; i < mainnets.length; ++i) {
            if (mainnets[i] == chainId) return true;
        }

        // Return true if the chain ID is in the testnet list.
        uint256[] memory testnets = getAllTestnets();
        for (uint256 i = 0; i < testnets.length; ++i) {
            if (testnets[i] == chainId) return true;
        }

        return false;
    }
}
