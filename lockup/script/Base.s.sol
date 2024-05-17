// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-console
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { stdJson } from "forge-std/src/StdJson.sol";

contract BaseScript is Script {
    using Strings for uint256;
    using stdJson for string;

    /// @dev The default value for `segmentCountMap` and `trancheCountMap`.
    uint256 internal constant DEFAULT_MAX_COUNT = 500;

    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $EOA is not defined.
    string internal mnemonic;

    /// @dev Maximum segment count mapped by the chain Id.
    mapping(uint256 chainId => uint256 count) internal segmentCountMap;

    /// @dev Maximum tranche count mapped by the chain Id.
    mapping(uint256 chainId => uint256 count) internal trancheCountMap;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $EOA is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $EOA is to specify the broadcaster key and its address via the command line.
    constructor() {
        address from = vm.envOr({ name: "EOA", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        // Populate the segment and tranche count map.
        populateSegmentAndTranchCountMap();

        // If there is no maximum value set for a specific chain, set a default value.
        if (segmentCountMap[block.chainid] == 0) {
            segmentCountMap[block.chainid] = DEFAULT_MAX_COUNT;
        }
        if (trancheCountMap[block.chainid] == 0) {
            trancheCountMap[block.chainid] = DEFAULT_MAX_COUNT;
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    ///
    /// Notes:
    /// - The salt format is "ChainID <chainid>, Version <version>".
    /// - The version is obtained from `package.json`.
    function constructCreate2Salt() public view returns (bytes32) {
        string memory chainId = block.chainid.toString();
        string memory json = vm.readFile("package.json");
        string memory version = json.readString(".version");
        string memory create2Salt = string.concat("ChainID ", chainId, ", Version ", version);
        console2.log("The CREATE2 salt is \"%s\"", create2Salt);
        return bytes32(abi.encodePacked(create2Salt));
    }

    /// @dev Populates the segment & tranche count map. Values are auto updated by the `update-script-counts.sh` script.
    function populateSegmentAndTranchCountMap() internal {
        // Arbitrum chain ID
        segmentCountMap[42_161] = 1170;
        trancheCountMap[42_161] = 1210;

        // Avalanche chain ID.
        segmentCountMap[43_114] = 530;
        trancheCountMap[43_114] = 540;

        // Base chain ID.
        segmentCountMap[8453] = 2200;
        trancheCountMap[8453] = 2290;

        // Blast chain ID.
        segmentCountMap[238] = 1100;
        trancheCountMap[238] = 1130;

        // BSC chain ID.
        segmentCountMap[56] = 4870;
        trancheCountMap[56] = 5180;

        // Ethereum chain ID.
        segmentCountMap[1] = 1100;
        trancheCountMap[1] = 1130;

        // Gnosis chain ID.
        segmentCountMap[100] = 610;
        trancheCountMap[100] = 620;

        // Optimism chain ID.
        segmentCountMap[10] = 1100;
        trancheCountMap[10] = 1130;

        // Polygon chain ID.
        segmentCountMap[137] = 1100;
        trancheCountMap[137] = 1130;

        // Scroll chain ID.
        segmentCountMap[534_352] = 340;
        trancheCountMap[534_352] = 350;

        // Sepolia chain ID.
        segmentCountMap[11_155_111] = 1100;
        trancheCountMap[11_155_111] = 1130;
    }
}
