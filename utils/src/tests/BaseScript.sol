// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-console
pragma solidity >=0.8.22;

import { Script } from "forge-std/src/Script.sol";
import { stdJson } from "forge-std/src/StdJson.sol";

abstract contract BaseScript is Script {
    using stdJson for string;

    /// @dev The address of the default Sablier admin.
    address public constant DEFAULT_SABLIER_ADMIN = 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F;

    /// @dev The salt used for deterministic deployments.
    bytes32 public immutable SALT;

    /// @dev Included to enable compilation of the script without a $MNEMONIC environment variable.
    string public constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev Admin address mapped by the chain Id.
    mapping(uint256 chainId => address admin) private _adminMap;

    /// @dev The address of the transaction broadcaster.
    address public broadcaster;

    /// @dev Used to derive the broadcaster's address if $ETH_FROM is not defined.
    string public mnemonic;

    /// @dev Initializes the transaction broadcaster like this:
    ///
    /// - If $ETH_FROM is defined, use it.
    /// - Otherwise, derive the broadcaster address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    ///
    /// The use case for $ETH_FROM is to specify the broadcaster key and its address via the command line.
    constructor() {
        address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        // Construct the salt for deterministic deployments.
        SALT = constructCreate2Salt();

        // Populate the admin map.
        populateAdminMap();
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
    function constructCreate2Salt() public view virtual returns (bytes32) {
        string memory chainId = vm.toString(block.chainid);
        string memory version = getVersion();
        string memory create2Salt = string.concat("ChainID ", chainId, ", Version ", version);
        return bytes32(abi.encodePacked(create2Salt));
    }

    /// @dev The version is obtained from `package.json`.
    function getVersion() public view virtual returns (string memory) {
        string memory json = vm.readFile("package.json");
        return json.readString(".version");
    }

    /// @dev Populates the admin map. The reason the chain IDs configured for the admin map do not match the other
    /// maps is that we only have multisigs for the chains listed below, otherwise, the default admin is used.​
    function populateAdminMap() public virtual {
        _adminMap[42_161] = 0xF34E41a6f6Ce5A45559B1D3Ee92E141a3De96376; // Arbitrum
        _adminMap[43_114] = 0x4735517616373c5137dE8bcCDc887637B8ac85Ce; // Avalanche
        _adminMap[8453] = 0x83A6fA8c04420B3F9C7A4CF1c040b63Fbbc89B66; // Base
        _adminMap[56] = 0x6666cA940D2f4B65883b454b7Bc7EEB039f64fa3; // BNB
        _adminMap[100] = 0x72ACB57fa6a8fa768bE44Db453B1CDBa8B12A399; // Gnosis
        _adminMap[1] = 0x79Fb3e81aAc012c08501f41296CCC145a1E15844; // Mainnet
        _adminMap[59_144] = 0x72dCfa0483d5Ef91562817C6f20E8Ce07A81319D; // Linea
        _adminMap[10] = 0x43c76FE8Aec91F63EbEfb4f5d2a4ba88ef880350; // Optimism
        _adminMap[137] = 0x40A518C5B9c1d3D6d62Ba789501CE4D526C9d9C6; // Polygon
        _adminMap[534_352] = 0x0F7Ad835235Ede685180A5c611111610813457a9; // Scroll
    }

    /// @dev Returns the protocol admin address for the current chain.
    function protocolAdmin() public view returns (address) {
        if (_adminMap[block.chainid] == address(0)) {
            // If there is no admin set for a specific chain, use the default Sablier admin.
            return DEFAULT_SABLIER_ADMIN;
        }

        return _adminMap[block.chainid];
    }
}
