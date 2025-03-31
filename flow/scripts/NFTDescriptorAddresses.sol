// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;
// solhint-disable code-complexity

abstract contract NFTDescriptorAddresses {
    /// @notice Returns the FlowNFTDescriptor for the supported chains.
    /// @dev If the chain does not have a FlowNFTDescriptor contract, return 0.
    function nftDescriptorAddress() public view returns (address addr) {
        /// Mainnets
        // Ethereum Mainnet
        if (block.chainid == 1) return 0x24bE13897eE1F83367661B6bA616a72523fC55C9;
        // Arbitrum One
        if (block.chainid == 42_161) return 0x5F23eF12A7e861CB92c24B4314Af2A5F363CDD4F;
        // Avalanche
        if (block.chainid == 43_114) return 0xb09b714B0feC83675E09fc997B7D532cF6620326;
        // Base
        if (block.chainid == 8453) return 0x5b5e742305Be3A484EacCB124C83456463c24E6a;
        // Berachain
        if (block.chainid == 80_094) return 0x581250eE4311F7Dc1afCF965cF8024004B423e9E;
        // Blast
        if (block.chainid == 81_457) return 0x92f1dB592C771D9Ec7708abFEe79771AbC1b4fAd;
        // BNB Smart Chain
        if (block.chainid == 56) return 0xAE557c04B46d47Ecac24edA63F22cabB4571Da61;
        // Chiliz
        if (block.chainid == 88_888) return 0xC7fd18CA19938d559dC45aDE362a850015CF0bd8;
        // Core Dao
        if (block.chainid == 1116) return 0x7293F2D4A4e676EF67C085E92277AdF560AECb88;
        // Form
        if (block.chainid == 478) return 0x88E64227D4DcF8De1141bb0807A9DC04a5Be9251;
        // Gnosis
        if (block.chainid == 100) return 0x5A47FC8732d399a2f3845c4FC91aB91bb97da31F;
        // Lightlink
        if (block.chainid == 1890) return 0x9f7cF1d1F558E57ef88a59ac3D47214eF25B6A06;
        // Linea
        if (block.chainid == 59_144) return 0x294D7fceBa43C4507771707CeBBB7b6d81d0BFdE;
        // Mode
        if (block.chainid == 34_443) return 0xD9E2822a33606741BeDbA31614E68A745e430102;
        // Morph
        if (block.chainid == 2818) return 0x1dd4dcE2BB742908b4062E583d9c035973413A3F;
        // Optimism
        if (block.chainid == 10) return 0x7AD245b74bBC1B71Da1713D53238931F791b90A3;
        // Polygon
        if (block.chainid == 137) return 0x87B836a9e26673feB3E409A0da2EAf99C79f26C3;
        // Scroll
        if (block.chainid == 534_352) return 0x797Fe78c41d9cbE81BBEA2f420101be5e47d2aFf;
        // Superseed
        if (block.chainid == 5330) return 0xd932fDA016eE9d9F70f745544b4F56715b1E723b;
        // Taiko Mainnet
        if (block.chainid == 167_000) return 0x80Bde7C505eFE9960b673567CB25Cd8af85552BE;
        // XDC
        if (block.chainid == 50) return 0x9D3F0122b260D2218ecf681c416495882003deDd;

        /// Testnets
        // Sepolia
        if (block.chainid == 11_155_111) return 0xc9dBf2D207D178875b698e5f7493ce2d8BA88994;
        // Arbitrum Sepolia
        if (block.chainid == 421_614) return 0x3E64A31C3974b6ae9f09a8fbc784519bF551e795;
        // Base Sepolia
        if (block.chainid == 84_532) return 0xcb5591F6d0e0fFC03037ef7b006D1361C6D33D25;
        // Blast Sepolia
        if (block.chainid == 168_587_773) return 0x42Abaf2c1E36624FD0084998A9BeA4a753A93e45;
        // Linea Sepolia
        if (block.chainid == 59_141) return 0xbd17DFd74078dB49f12101Ca929b5153E924e9C7;
        // Mode Sepolia
        if (block.chainid == 919) return 0xe1eDdA64eea2173a015A3738171C3a1C263324C7;
        // Monad Testnet
        if (block.chainid == 10_143) return 0x80004e0b60c4aE862c405793FE684d43AdfdB905;
        // Optimism Sepolia
        if (block.chainid == 11_155_420) return 0x4739327acfb56E90177d44Cb0845e759276BCA88;
        // Superseed Sepolia
        if (block.chainid == 53_302) return 0xC373b8b68542c533B90f4A85a81b7D5F31F4E3eF;
        // Taiko Hekla
        if (block.chainid == 167_009) return 0xB197D4142b9DBf34979588cf8BF1222Ea3907916;

        // Return address zero for unsupported chain.
        return address(0);
    }
}
