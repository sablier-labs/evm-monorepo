// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable code-complexity
pragma solidity >=0.8.22;

import { ChainId } from "@sablier/evm-utils/src/tests/ChainId.sol";

abstract contract NFTDescriptorAddresses {
    /// @notice Returns the FlowNFTDescriptor for the supported chains.
    /// @dev If the chain does not have a FlowNFTDescriptor contract, return 0.
    function nftDescriptorAddress() public view returns (address addr) {
        uint256 chainId = block.chainid;

        // Mainnets.
        if (chainId == ChainId.ABSTRACT) return 0x6CefdBc5Ba80937235F012c83d6aA83F1200d6cC;
        if (chainId == ChainId.ARBITRUM) return 0x5F23eF12A7e861CB92c24B4314Af2A5F363CDD4F;
        if (chainId == ChainId.AVALANCHE) return 0xb09b714B0feC83675E09fc997B7D532cF6620326;
        if (chainId == ChainId.BASE) return 0x5b5e742305Be3A484EacCB124C83456463c24E6a;
        if (chainId == ChainId.BERACHAIN) return 0x581250eE4311F7Dc1afCF965cF8024004B423e9E;
        if (chainId == ChainId.BLAST) return 0x92f1dB592C771D9Ec7708abFEe79771AbC1b4fAd;
        if (chainId == ChainId.BSC) return 0xAE557c04B46d47Ecac24edA63F22cabB4571Da61;
        if (chainId == ChainId.CHILIZ) return 0xC7fd18CA19938d559dC45aDE362a850015CF0bd8;
        if (chainId == ChainId.COREDAO) return 0x7293F2D4A4e676EF67C085E92277AdF560AECb88;
        if (chainId == ChainId.ETHEREUM) return 0x24bE13897eE1F83367661B6bA616a72523fC55C9;
        if (chainId == ChainId.FORM) return 0x88E64227D4DcF8De1141bb0807A9DC04a5Be9251;
        if (chainId == ChainId.GNOSIS) return 0x5A47FC8732d399a2f3845c4FC91aB91bb97da31F;
        if (chainId == ChainId.IOTEX) return 0x91D7B990B1aCDfB2F38189c646371377416c641E;
        if (chainId == ChainId.LIGHTLINK) return 0xc58E948Cb0a010105467C92856bcd4842B759fb1;
        if (chainId == ChainId.LINEA) return 0x294D7fceBa43C4507771707CeBBB7b6d81d0BFdE;
        if (chainId == ChainId.MODE) return 0xD9E2822a33606741BeDbA31614E68A745e430102;
        if (chainId == ChainId.MORPH) return 0x1dd4dcE2BB742908b4062E583d9c035973413A3F;
        if (chainId == ChainId.OPTIMISM) return 0x7AD245b74bBC1B71Da1713D53238931F791b90A3;
        if (chainId == ChainId.POLYGON) return 0x87B836a9e26673feB3E409A0da2EAf99C79f26C3;
        if (chainId == ChainId.SCROLL) return 0x797Fe78c41d9cbE81BBEA2f420101be5e47d2aFf;
        if (chainId == ChainId.SEI) return 0xF3D18b06c87735a58DAb3baC45af058b3772fD54;
        if (chainId == ChainId.SOPHON) return 0x2F1eB117A87217E8bE9AA96795F69c9e380686Db;
        if (chainId == ChainId.SUPERSEED) return 0xd932fDA016eE9d9F70f745544b4F56715b1E723b;
        if (chainId == ChainId.TAIKO) return 0x80Bde7C505eFE9960b673567CB25Cd8af85552BE;
        if (chainId == ChainId.TANGLE) return 0xDf578C2c70A86945999c65961417057363530a1c;
        if (chainId == ChainId.ULTRA) return 0x9f5d28C8ed7F09e65519C1f6f394e523524cA38F;
        if (chainId == ChainId.UNICHAIN) return 0x89824A7e48dcf6B7AE9DeE6E566f62A5aDF037F2;
        if (chainId == ChainId.XDC) return 0x9D3F0122b260D2218ecf681c416495882003deDd;

        // Testnets.
        if (chainId == ChainId.ARBITRUM_SEPOLIA) return 0x3E64A31C3974b6ae9f09a8fbc784519bF551e795;
        if (chainId == ChainId.BASE_SEPOLIA) return 0xcb5591F6d0e0fFC03037ef7b006D1361C6D33D25;
        if (chainId == ChainId.BLAST_SEPOLIA) return 0x42Abaf2c1E36624FD0084998A9BeA4a753A93e45;
        if (chainId == ChainId.ETHEREUM_SEPOLIA) return 0xc9dBf2D207D178875b698e5f7493ce2d8BA88994;
        if (chainId == ChainId.LINEA_SEPOLIA) return 0xbd17DFd74078dB49f12101Ca929b5153E924e9C7;
        if (chainId == ChainId.MODE_SEPOLIA) return 0xe1eDdA64eea2173a015A3738171C3a1C263324C7;
        if (chainId == ChainId.MONAD_TESTNET) return 0x80004e0b60c4aE862c405793FE684d43AdfdB905;
        if (chainId == ChainId.OPTIMISM_SEPOLIA) return 0x4739327acfb56E90177d44Cb0845e759276BCA88;
        if (chainId == ChainId.SUPERSEED_SEPOLIA) return 0xC373b8b68542c533B90f4A85a81b7D5F31F4E3eF;
        if (chainId == ChainId.TAIKO_HEKLA) return 0xB197D4142b9DBf34979588cf8BF1222Ea3907916;

        // Return address zero for unsupported chain.
        return address(0);
    }
}
