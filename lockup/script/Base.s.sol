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

    /// @dev The default value for `maxCountMap`.
    uint256 internal constant DEFAULT_MAX_COUNT = 500;

    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev Used to derive the broadcaster's address if $EOA is not defined.
    string internal mnemonic;

    /// @dev Maximum count for segments and tranches mapped by the chain Id.
    mapping(uint256 chainId => uint256 count) internal maxCountMap;

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

        // Populate the max count map for segments and tranches.
        populateMaxCountMap();

        // If there is no maximum value set for a specific chain, use the default value.
        if (maxCountMap[block.chainid] == 0) {
            maxCountMap[block.chainid] = DEFAULT_MAX_COUNT;
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
    function constructCreate2Salt() public view returns (bytes32) {
        string memory chainId = block.chainid.toString();
        string memory version = getVersion();
        string memory create2Salt = string.concat("ChainID ", chainId, ", Version ", version);
        console2.log("The CREATE2 salt is \"%s\"", create2Salt);
        return bytes32(abi.encodePacked(create2Salt));
    }

    /// @dev The version is obtained from `package.json`.
    function getVersion() internal view returns (string memory) {
        string memory json = vm.readFile("package.json");
        return json.readString(".version");
    }

    /// @dev Updates max values for segments and tranches. Values can be updated using the `update-counts.sh` script.
    function populateMaxCountMap() internal {
        // forgefmt: disable-start

        // Arbitrum chain ID
        maxCountMap[42161] = 1080;

        // Avalanche chain ID.
        maxCountMap[43114] = 490;

        // Base chain ID.
        maxCountMap[8453] = 2010;

        // Blast chain ID.
        maxCountMap[81457] = 1010;

        // BNB chain ID.
        maxCountMap[56] = 4430;

        // Ethereum chain ID.
        maxCountMap[1] = 1010;

        // Gnosis chain ID.
        maxCountMap[100] = 560;

        // Optimism chain ID.
        maxCountMap[10] = 1010;

        // Polygon chain ID.
        maxCountMap[137] = 1010;

        // Scroll chain ID.
        maxCountMap[534352] = 310;

        // Sepolia chain ID.
        maxCountMap[11155111] = 1010;

        // forgefmt: disable-end
    }
}
