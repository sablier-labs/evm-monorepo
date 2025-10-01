// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable code-complexity
pragma solidity >=0.8.22;

import { ChainId } from "@sablier/evm-utils/src/tests/ChainId.sol";

abstract contract LockupNFTDescriptorAddresses {
    /// @notice Returns the LockupNFTDescriptor for the supported chains.
    /// @dev If the chain does not have a LockupNFTDescriptor contract, return 0.
    function nftDescriptorAddress() public view returns (address addr) {
        uint256 chainId = block.chainid;

        // Mainnets.
        if (chainId == ChainId.ABSTRACT) return 0x63Ff2E370788C163D5a1909B5FCb299DB327AEF9;
        if (chainId == ChainId.ARBITRUM) return 0xd5c6a0Dd2E1822865c308850b8b3E2CcE762D061;
        if (chainId == ChainId.AVALANCHE) return 0x906A4BD5dD0EF13654eA29bFD6185d0d64A4b674;
        if (chainId == ChainId.BASE) return 0x87e437030b7439150605a641483de98672E26317;
        if (chainId == ChainId.BERACHAIN) return 0x3bbE0a21792564604B0fDc00019532Adeffa70eb;
        if (chainId == ChainId.BLAST) return 0x959c412d5919b1Ec5D07bee3443ea68c91d57dd7;
        if (chainId == ChainId.BSC) return 0x56831a5a932793E02251126831174Ab8Bf2f7695;
        if (chainId == ChainId.CHILIZ) return 0x8A96f827082FB349B6e268baa0a7A5584c4Ccda6;
        if (chainId == ChainId.COREDAO) return 0xac0cF0F2A96Ed7ec3cfA4D0Be621C67ADC9Dd903;
        if (chainId == ChainId.ETHEREUM) return 0xA9dC6878C979B5cc1d98a1803F0664ad725A1f56;
        if (chainId == ChainId.GNOSIS) return 0x3140a6900AA2FF3186730741ad8255ee4e6d8Ff1;
        if (chainId == ChainId.LIGHTLINK) return 0xCFB5F90370A7884DEc59C55533782B45FA24f4d1;
        if (chainId == ChainId.LINEA) return 0x1514a869D29a8B22961e8F9eBa3DC64000b96BCe;
        if (chainId == ChainId.MODE) return 0x64e7879558b6dfE2f510bd4b9Ad196ef0371EAA8;
        if (chainId == ChainId.MORPH) return 0x660314f09ac3B65E216B6De288aAdc2599AF14e2;
        if (chainId == ChainId.OPTIMISM) return 0x41dBa1AfBB6DF91b3330dc009842327A9858Cbae;
        if (chainId == ChainId.POLYGON) return 0xf5e12d0bA25FCa0D738Ec57f149736B2e4C46980;
        if (chainId == ChainId.SCROLL) return 0x00Ff6443E902874924dd217c1435e3be04f57431;
        if (chainId == ChainId.SEI) return 0xeaFB40669fe3523b073904De76410b46e79a56D7;
        if (chainId == ChainId.SOPHON) return 0xAc2E42b520364940c90Ce164412Ca9BA212d014B;
        if (chainId == ChainId.SUPERSEED) return 0xa4576b58Ec760A8282D081dc94F3dc716DFc61e9;
        if (chainId == ChainId.TANGLE) return 0x92FC05e49c27884d554D98a5C01Ff0894a9DC29a;
        if (chainId == ChainId.UNICHAIN) return 0xa5F12D63E18a28C9BE27B6f3d91ce693320067ba;
        if (chainId == ChainId.XDC) return 0x4c1311a9d88BFb7023148aB04F7321C2E91c29bf;

        // Testnets.
        if (chainId == ChainId.ARBITRUM_SEPOLIA) return 0x8224eb5D7d76B2D7Df43b868D875E79B11500eA8;
        if (chainId == ChainId.BASE_SEPOLIA) return 0xCA2593027BA24856c292Fdcb5F987E0c25e755a4;
        if (chainId == ChainId.MODE_SEPOLIA) return 0xDd695E927b97460C8d454D8f6d8Cd797Dcf1FCfD;
        if (chainId == ChainId.OPTIMISM_SEPOLIA) return 0xDf6163ddD3Ebcb552Cc1379a9c65AFe68683534e;

        // Return address zero for unsupported chain.
        return address(0);
    }
}
