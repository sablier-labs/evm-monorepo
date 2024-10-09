// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { stdJson } from "forge-std/src/StdJson.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev This contract appends to the `script` directory a markdown file with the deployed addresses.
contract DeploymentLogger is BaseScript {
    using stdJson for string;
    using Strings for address;
    using Strings for string;
    using Strings for uint256;

    /// @dev The address of the default Sablier admin.
    address internal constant DEFAULT_SABLIER_ADMIN = 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F;

    /// @dev Admin address mapped by the chain Id.
    mapping(uint256 chainId => address admin) internal adminMap;

    /// @dev Chain names mapped by the chain Id.
    mapping(uint256 chainId => string name) internal chainNameMap;

    /// @dev The path to the file where the deployment addresses are stored.
    string internal deploymentFile;

    /// @dev Explorer URL mapped by the chain Id.
    mapping(uint256 chainId => string explorerUrl) internal explorerMap;

    constructor(string memory deterministicOrNot) {
        // Populate the admin map.
        populateAdminMap();

        // Populate the chain name map.
        populateChainNameMap();

        // Populate the explorer URLs.
        populateExplorerMap();

        // If there is no admin set for a specific chain, use the default Sablier admin.
        if (adminMap[block.chainid] == address(0)) {
            adminMap[block.chainid] = DEFAULT_SABLIER_ADMIN;
        }

        // If there is no explorer URL set for a specific chain, use a placeholder.
        if (explorerMap[block.chainid].equal("")) {
            explorerMap[block.chainid] = "N/A";
        }

        // If there is no chain name set for a specific chain, use the chain ID.
        if (chainNameMap[block.chainid].equal("")) {
            chainNameMap[block.chainid] = string.concat("Chain ID: ", block.chainid.toString());
        }

        // Set the deployment file path.
        deploymentFile = string.concat("script/", deterministicOrNot, ".md");

        // Append the chain name to the deployment file.
        _appendToFile(string.concat("## ", chainNameMap[block.chainid], "\n"));
    }

    /// @dev Function to append the deployed addresses to the deployment file.
    function appendToFileDeployedAddresses(address flow, address flowNFTDescriptor) internal {
        string memory firstTwoLines = "| Contract | Address | Deployment |\n | :------- | :------ | :----------|";
        _appendToFile(firstTwoLines);

        string memory flowLine = _getContractLine({ contractName: "SablierFlow", contractAddress: flow.toHexString() });
        _appendToFile(flowLine);

        string memory flowNFTDescriptorLine =
            _getContractLine({ contractName: "FlowNFTDescriptor", contractAddress: flowNFTDescriptor.toHexString() });
        _appendToFile(flowNFTDescriptorLine);

        _appendToFile("\n");
    }

    /// @dev Populates the admin map. The reason the chain IDs configured for the admin map do not match the other
    /// maps is that we only have multisigs for the chains listed below, otherwise, the default admin is used.​
    function populateAdminMap() internal {
        adminMap[42_161] = 0xF34E41a6f6Ce5A45559B1D3Ee92E141a3De96376; // Arbitrum
        adminMap[43_114] = 0x4735517616373c5137dE8bcCDc887637B8ac85Ce; // Avalanche
        adminMap[8453] = 0x83A6fA8c04420B3F9C7A4CF1c040b63Fbbc89B66; // Base
        adminMap[56] = 0x6666cA940D2f4B65883b454b7Bc7EEB039f64fa3; // BNB
        adminMap[100] = 0x72ACB57fa6a8fa768bE44Db453B1CDBa8B12A399; // Gnosis
        adminMap[1] = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844; // Mainnet
        adminMap[59_144] = 0x72dCfa0483d5Ef91562817C6f20E8Ce07A81319D; // Linea
        adminMap[10] = 0x43c76FE8Aec91F63EbEfb4f5d2a4ba88ef880350; // Optimism
        adminMap[137] = 0x40A518C5B9c1d3D6d62Ba789501CE4D526C9d9C6; // Polygon
        adminMap[534_352] = 0x0F7Ad835235Ede685180A5c611111610813457a9; // Scroll
    }

    /// @dev Populates the chain name map.
    function populateChainNameMap() internal {
        chainNameMap[42_161] = "Arbitrum";
        chainNameMap[43_114] = "Avalanche";
        chainNameMap[8453] = "Base";
        chainNameMap[84_532] = "Base Sepolia";
        chainNameMap[80_084] = "Berachain Bartio";
        chainNameMap[81_457] = "Blast";
        chainNameMap[168_587_773] = "Blast Sepolia";
        chainNameMap[56] = "BNB Smart Chain";
        chainNameMap[100] = "Gnosis";
        chainNameMap[1890] = "Lightlink";
        chainNameMap[59_144] = "Linea";
        chainNameMap[59_141] = "Linea Sepolia";
        chainNameMap[1] = "Mainnet";
        chainNameMap[333_000_333] = "Meld";
        chainNameMap[34_443] = "Mode";
        chainNameMap[919] = "Mode Sepolia";
        chainNameMap[2810] = "Morph Holesky";
        chainNameMap[10] = "Optimism";
        chainNameMap[11_155_420] = "Optimism Sepolia";
        chainNameMap[137] = "Polygon";
        chainNameMap[534_352] = "Scroll";
        chainNameMap[11_155_111] = "Sepolia";
        chainNameMap[53_302] = "Superseed Sepolia";
        chainNameMap[167_009] = "Taiko Hekla";
        chainNameMap[167_000] = "Taiko Mainnet";
    }

    /// @dev Populates the explorer map.
    function populateExplorerMap() internal {
        explorerMap[42_161] = "https://arbiscan.io/address/";
        explorerMap[43_114] = "https://snowtrace.io/address/";
        explorerMap[8453] = "https://basescan.org/address/";
        explorerMap[84_532] = "https://sepolia.basescan.org/address/";
        explorerMap[80_084] = "https://bartio.beratrail.io/address/";
        explorerMap[81_457] = "https://blastscan.io/address/";
        explorerMap[168_587_773] = "https://sepolia.blastscan.io/address/";
        explorerMap[56] = "https://bscscan.com/address/";
        explorerMap[1] = "https://etherscan.io/address/";
        explorerMap[100] = "https://gnosisscan.io/address/";
        explorerMap[59_144] = "https://lineascan.build/address/";
        explorerMap[59_141] = "https://sepolia.lineascan.build/address/";
        explorerMap[1890] = "https://phoenix.lightlink.io/address/";
        explorerMap[34_443] = "https://explorer.mode.network/address/";
        explorerMap[919] = "https://sepolia.explorer.mode.network/address/";
        explorerMap[2810] = "https://explorer-holesky.morphl2.io/address/";
        explorerMap[333_000_333] = "https://meldscan.io/address/";
        explorerMap[10] = "https://optimistic.etherscan.io/address/";
        explorerMap[11_155_420] = "https://sepolia-optimistic.etherscan.io/address/";
        explorerMap[137] = "https://polygonscan.com/address/";
        explorerMap[534_352] = "https://scrollscan.com/address/";
        explorerMap[11_155_111] = "https://sepolia.etherscan.io/address/";
        explorerMap[53_302] = "https://sepolia-explorer.superseed.xyz/address/";
        explorerMap[167_009] = "https://explorer.hekla.taiko.xyz/address/";
        explorerMap[167_000] = "https://taikoscan.io/address/";
    }

    /// @dev Append a line to the deployment file path.
    function _appendToFile(string memory line) private {
        vm.writeLine({ path: deploymentFile, data: line });
    }

    /// @dev Returns a string for a single contract line formatted according to the docs.
    function _getContractLine(
        string memory contractName,
        string memory contractAddress
    )
        private
        view
        returns (string memory)
    {
        string memory version = getVersion();
        version = string.concat("v", version);

        return string.concat(
            "| ",
            contractName,
            " | [",
            contractAddress,
            "](",
            explorerMap[block.chainid],
            contractAddress,
            ") | [",
            version,
            "](https://github.com/sablier-labs/v2-deployments/tree/main/",
            ") |"
        );
    }
}
