// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-console
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Sphinx } from "@sphinx-labs/contracts/SphinxPlugin.sol";

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";

contract BaseScript is Script, Sphinx {
    using Strings for uint256;

    /// @dev The Avalanche chain ID.
    uint256 internal constant AVALANCHE_CHAIN_ID = 43_114;

    /// @dev The project name for the Sphinx plugin.
    string internal constant SPHINX_PROJECT_NAME = "test-test";

    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev The address of the transaction broadcaster.
    address internal broadcaster;

    /// @dev The upper limit on the length of data structures to ensure that transactions stay within the
    /// block gas limit.
    uint256 internal maxCount;

    /// @dev Used to derive the broadcaster's address if $EOA is not defined.
    string internal mnemonic;

    /// @dev The project name for the Sphinx plugin.
    string internal sphinxProjectName;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $EOA is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    /// - If $SPHINX_PROJECT_NAME is not defined, default to a test project name.
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
        sphinxProjectName = vm.envOr({ name: "SPHINX_PROJECT_NAME", defaultValue: SPHINX_PROJECT_NAME });

        // Sets `maxCount` to 300 for Avalanche, and 500 for all other chains.
        if (block.chainid == AVALANCHE_CHAIN_ID) {
            maxCount = 300;
        } else {
            maxCount = 500;
        }
    }

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    /// @dev Configures the Sphinx plugin to use Sphinx managed deployment for smart contracts.
    /// Refer to https://github.com/sphinx-labs/sphinx/tree/main/docs.
    /// CLI example:
    /// - bun sphinx propose script/DeployCore.s.sol --networks testnets --sig "runSphinx(address)" $ADMIN
    function configureSphinx() public override {
        sphinxConfig.mainnets = ["arbitrum", "avalanche", "bnb", "gnosis", "ethereum", "optimism", "polygon"];
        sphinxConfig.orgId = vm.envOr({ name: "SPHINX_ORG_ID", defaultValue: TEST_MNEMONIC });
        sphinxConfig.owners = [broadcaster];
        sphinxConfig.projectName = sphinxProjectName;
        sphinxConfig.testnets = ["sepolia"];
        sphinxConfig.threshold = 1;
    }

    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    ///
    /// Notes:
    /// - The salt format is "ChainID <chainid>, Version <version>".
    /// - The version is obtained from `package.json` using the `ffi` cheatcode:
    /// https://book.getfoundry.sh/cheatcodes/ffi
    /// - Requires `jq` CLI tool installed: https://jqlang.github.io/jq/
    function constructCreate2Salt() public returns (bytes32) {
        string memory chainId = block.chainid.toString();
        string[] memory inputs = new string[](4);
        inputs[0] = "jq";
        inputs[1] = "-r";
        inputs[2] = ".version";
        inputs[3] = "./package.json";
        bytes memory result = vm.ffi(inputs);
        string memory version = string(result);
        string memory create2Salt = string.concat("ChainID ", chainId, ", Version ", version);
        console2.log("The CREATE2 salt is \"%s\"", create2Salt);
        return bytes32(abi.encodePacked(create2Salt));
    }
}
