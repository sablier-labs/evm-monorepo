// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable code-complexity
// solhint-disable no-console
pragma solidity >=0.8.22;

import { Script } from "forge-std/src/Script.sol";
import { stdJson } from "forge-std/src/StdJson.sol";

abstract contract BaseScript is Script {
    using stdJson for string;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////////////////
                                        HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the Chainlink oracle for the supported chains. These addresses can be verified on
    /// https://docs.chain.link/data-feeds/price-feeds/addresses.
    /// @dev If the chain does not have a Chainlink oracle, return 0.
    function chainlinkOracle() public view returns (address addr) {
        uint256 chainId = block.chainid;

        // Ethereum Mainnet
        if (chainId == 1) return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        // Arbitrum One
        if (chainId == 42_161) return 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        // Avalanche
        if (chainId == 43_114) return 0x0A77230d17318075983913bC2145DB16C7366156;
        // Base
        if (chainId == 8453) return 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        // BNB Smart Chain
        if (chainId == 56) return 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        // Gnosis Chain
        if (chainId == 100) return 0x678df3415fc31947dA4324eC63212874be5a82f8;
        // Linea
        if (chainId == 59_144) return 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        // Optimism
        if (chainId == 10) return 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        // Polygon
        if (chainId == 137) return 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        // Scroll
        if (chainId == 534_352) return 0x6bF14CB0A831078629D993FDeBcB182b21A8774C;

        // Return address zero for unsupported chain.
        return address(0);
    }

    function comptrollerAddress() public view returns (address) {
        /// Mainnets
        // Ethereum Mainnet
        /// TODO: Update the addresses to the actual Sablier Comptroller addresses for each chain.
        if (block.chainid == 1) return address(0xCAFE);
        // Arbitrum One
        if (block.chainid == 42_161) return address(0xCAFE);
        // Avalanche
        if (block.chainid == 43_114) return address(0xCAFE);
        // Base
        if (block.chainid == 8453) return address(0xCAFE);
        // Berachain
        if (block.chainid == 80_094) return address(0xCAFE);
        // Blast
        if (block.chainid == 81_457) return address(0xCAFE);
        // BNB Smart Chain
        if (block.chainid == 56) return address(0xCAFE);
        // Chiliz
        if (block.chainid == 88_888) return address(0xCAFE);
        // Core Dao
        if (block.chainid == 1116) return address(0xCAFE);
        // Form
        if (block.chainid == 478) return address(0xCAFE);
        // Gnosis
        if (block.chainid == 100) return address(0xCAFE);
        // Lightlink
        if (block.chainid == 1890) return address(0xCAFE);
        // Linea
        if (block.chainid == 59_144) return address(0xCAFE);
        // Mode
        if (block.chainid == 34_443) return address(0xCAFE);
        // Morph
        if (block.chainid == 2818) return address(0xCAFE);
        // Optimism
        if (block.chainid == 10) return address(0xCAFE);
        // Polygon
        if (block.chainid == 137) return address(0xCAFE);
        // Scroll
        if (block.chainid == 534_352) return address(0xCAFE);
        // Superseed
        if (block.chainid == 5330) return address(0xCAFE);
        // Taiko Mainnet
        if (block.chainid == 167_000) return address(0xCAFE);
        // XDC
        if (block.chainid == 50) return address(0xCAFE);

        /// Testnets
        // Sepolia
        if (block.chainid == 11_155_111) return address(0xCAFE);
        // Arbitrum Sepolia
        if (block.chainid == 421_614) return address(0xCAFE);
        // Base Sepolia
        if (block.chainid == 84_532) return address(0xCAFE);
        // Blast Sepolia
        if (block.chainid == 168_587_773) return address(0xCAFE);
        // Linea Sepolia
        if (block.chainid == 59_141) return address(0xCAFE);
        // Mode Sepolia
        if (block.chainid == 919) return address(0xCAFE);
        // Monad Testnet
        if (block.chainid == 10_143) return address(0xCAFE);
        // Optimism Sepolia
        if (block.chainid == 11_155_420) return address(0xCAFE);
        // Superseed Sepolia
        if (block.chainid == 53_302) return address(0xCAFE);
        // Taiko Hekla
        if (block.chainid == 167_009) return address(0xCAFE);

        // Return address zero for unsupported chain.
        return address(0);
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

    /// @notice Returns the initial min USD fee as $1. If the chain does not have Chainlink, return 0.
    function initialMinFeeUSD() public view returns (uint256) {
        if (chainlinkOracle() != address(0)) {
            return 1e8;
        }
        return 0;
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
