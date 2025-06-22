// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable code-complexity
// solhint-disable no-console
pragma solidity >=0.8.22;

import { Script } from "forge-std/src/Script.sol";
import { stdJson } from "forge-std/src/StdJson.sol";
import { ChainId } from "./ChainId.sol";

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

    /// @dev The address of the transaction broadcaster.
    address public broadcaster;

    uint64 public chainId;

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
        // Set the chain ID.
        chainId = uint64(block.chainid);

        address from = vm.envOr({ name: "ETH_FROM", defaultValue: address(0) });
        if (from != address(0)) {
            broadcaster = from;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (broadcaster,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        // Construct the salt for deterministic deployments.
        SALT = constructCreate2Salt();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the salt used for deterministic deployments, using the format "ChainID <chainID>, Version
    /// <version>".
    /// @dev The salt instructs Foundry to deploy contracts via the deterministic CREATE2 factory.
    function constructCreate2Salt() public view virtual returns (bytes32) {
        string memory chainIdStr = vm.toString(chainId);
        string memory version = getVersion();
        string memory create2Salt = string.concat("ChainID ", chainIdStr, ", Version ", version);
        return bytes32(abi.encodePacked(create2Salt));
    }

    /// @notice Returns the admin address to be used for the comptroller.
    /// @dev The chains listed below use multisig. In all other cases, the default admin is used.
    function getAdmin() public view returns (address) {
        if (chainId == ChainId.ARBITRUM) return 0xF34E41a6f6Ce5A45559B1D3Ee92E141a3De96376;
        if (chainId == ChainId.AVALANCHE) return 0x4735517616373c5137dE8bcCDc887637B8ac85Ce;
        if (chainId == ChainId.BASE) return 0x83A6fA8c04420B3F9C7A4CF1c040b63Fbbc89B66;
        if (chainId == ChainId.BSC) return 0x6666cA940D2f4B65883b454b7Bc7EEB039f64fa3;
        if (chainId == ChainId.CHILIZ) return 0x74A234DcAdFCB395b37C8c2B3Edf7A13Be78c935;
        if (chainId == ChainId.ETHEREUM) return 0x79Fb3e81aAc012c08501f41296CCC145a1E15844;
        if (chainId == ChainId.GNOSIS) return 0x72ACB57fa6a8fa768bE44Db453B1CDBa8B12A399;
        if (chainId == ChainId.LINEA) return 0x72dCfa0483d5Ef91562817C6f20E8Ce07A81319D;
        if (chainId == ChainId.OPTIMISM) return 0x43c76FE8Aec91F63EbEfb4f5d2a4ba88ef880350;
        if (chainId == ChainId.POLYGON) return 0x40A518C5B9c1d3D6d62Ba789501CE4D526C9d9C6;
        if (chainId == ChainId.SCROLL) return 0x0F7Ad835235Ede685180A5c611111610813457a9;
        if (chainId == ChainId.ZKSYNC) return 0xaFeA787Ef04E280ad5Bb907363f214E4BAB9e288;

        return DEFAULT_SABLIER_ADMIN;
    }

    /// @notice Returns the Chainlink oracle on each chain. Refer to
    /// https://docs.chain.link/data-feeds/price-feeds/addresses.
    /// @dev Return 0, if no Chainlink oracle is found.
    function getChainlinkOracle() public view returns (address addr) {
        if (chainId == ChainId.ARBITRUM) return 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        if (chainId == ChainId.AVALANCHE) return 0x0A77230d17318075983913bC2145DB16C7366156;
        if (chainId == ChainId.BASE) return 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        if (chainId == ChainId.BSC) return 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        if (chainId == ChainId.ETHEREUM) return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        if (chainId == ChainId.GNOSIS) return 0x678df3415fc31947dA4324eC63212874be5a82f8;
        if (chainId == ChainId.LINEA) return 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        if (chainId == ChainId.OPTIMISM) return 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        if (chainId == ChainId.POLYGON) return 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        if (chainId == ChainId.SCROLL) return 0x6bF14CB0A831078629D993FDeBcB182b21A8774C;
        if (chainId == ChainId.ZKSYNC) return 0x6D41d1dc818112880b40e26BD6FD347E41008eDA;

        return address(0);
    }

    /// @notice Returns the Sablier Comptroller on each chain. Revert if no comptroller is found.
    function getComptroller() public view returns (address) {
        // TODO: Update the addresses to the actual Sablier Comptroller addresses for each chain.
        // Mainnets
        if (chainId == ChainId.ABSTRACT) return address(0xCAFE);
        if (chainId == ChainId.ARBITRUM) return address(0xCAFE);
        if (chainId == ChainId.AVALANCHE) return address(0xCAFE);
        if (chainId == ChainId.BASE) return address(0xCAFE);
        if (chainId == ChainId.BERACHAIN) return address(0xCAFE);
        if (chainId == ChainId.BLAST) return address(0xCAFE);
        if (chainId == ChainId.BSC) return address(0xCAFE);
        if (chainId == ChainId.CHILIZ) return address(0xCAFE);
        if (chainId == ChainId.COREDAO) return address(0xCAFE);
        if (chainId == ChainId.ETHEREUM) return address(0xCAFE);
        if (chainId == ChainId.FORM) return address(0xCAFE);
        if (chainId == ChainId.GNOSIS) return address(0xCAFE);
        if (chainId == ChainId.IOTEX) return address(0xCAFE);
        if (chainId == ChainId.LIGHTLINK) return address(0xCAFE);
        if (chainId == ChainId.LINEA) return address(0xCAFE);
        if (chainId == ChainId.MODE) return address(0xCAFE);
        if (chainId == ChainId.MORPH) return address(0xCAFE);
        if (chainId == ChainId.OPTIMISM) return address(0xCAFE);
        if (chainId == ChainId.POLYGON) return address(0xCAFE);
        if (chainId == ChainId.SCROLL) return address(0xCAFE);
        if (chainId == ChainId.SEI) return address(0xCAFE);
        if (chainId == ChainId.SOPHON) return address(0xCAFE);
        if (chainId == ChainId.SUPERSEED) return address(0xCAFE);
        if (chainId == ChainId.TAIKO) return address(0xCAFE);
        if (chainId == ChainId.TANGLE) return address(0xCAFE);
        if (chainId == ChainId.ULTRA) return address(0xCAFE);
        if (chainId == ChainId.UNICHAIN) return address(0xCAFE);
        if (chainId == ChainId.XDC) return address(0xCAFE);
        if (chainId == ChainId.ZKSYNC) return address(0xCAFE);

        // Testnets
        if (chainId == ChainId.ARBITRUM_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.BASE_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.BLAST_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.ETHEREUM_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.LINEA_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.MODE_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.MONAD_TESTNET) return address(0xCAFE);
        if (chainId == ChainId.OPTIMISM_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.SUPERSEED_SEPOLIA) return address(0xCAFE);
        if (chainId == ChainId.TAIKO_HEKLA) return address(0xCAFE);
        if (chainId == ChainId.ZKSYNC_SEPOLIA) return address(0xCAFE);

        // Otherwise, revert.
        revert("Comptroller: not found");
    }

    /// @notice Returns the initial value of the min fee in USD.
    /// @dev If the chain does not have Chainlink, no fee is set.
    function getInitialMinFeeUSD() public view returns (uint256) {
        // If the chain has a Chainlink oracle, set the min fee to $1.
        if (getChainlinkOracle() != address(0)) {
            return 1e8;
        }

        // Otherwise, set the min fee to 0.
        return 0;
    }

    /// @notice Returns the version of the protocol, obtained from `package.json`.
    function getVersion() public view virtual returns (string memory) {
        string memory json = vm.readFile("package.json");
        return json.readString(".version");
    }
}
