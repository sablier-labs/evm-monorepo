// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { StdConstants, Vm } from "forge-std/src/StdConstants.sol";

import { BaseScript } from "src/tests/BaseScript.sol";
import { ChainId } from "src/tests/ChainId.sol";

contract BaseScriptMock is BaseScript { }

contract BaseScript_Fuzz_Test is StdAssertions {
    BaseScriptMock internal baseScript;

    string public constant PACKAGE_VERSION = "1.0.0";

    Vm internal vm = StdConstants.VM;

    /// @dev Sets the `block.chainid` to the given chain ID.
    modifier setChainId(uint64 chainId) {
        vm.assume(chainId != 0);

        // Set the `block.chainid` to the given chain ID.
        vm.chainId(chainId);

        // Deploy the `BaseScriptMock` contract on the given chain ID.
        baseScript = new BaseScriptMock();
        _;
    }

    function testFuzz_Constructor(uint64 chainId) external setChainId(chainId) {
        string memory salt = string.concat("ChainID ", vm.toString(chainId), ", Version ", PACKAGE_VERSION);
        bytes32 expectedSalt = bytes32(abi.encodePacked(salt));

        assertEq(baseScript.DEFAULT_SABLIER_ADMIN(), 0xb1bEF51ebCA01EB12001a639bDBbFF6eEcA12B9F, "default admin");
        assertEq(baseScript.chainId(), chainId, "chainId");
        assertEq(baseScript.SALT(), expectedSalt, "salt");
    }

    function testFuzz_ConstructCreate2Salt(uint64 chainId) external setChainId(chainId) {
        string memory salt = string.concat("ChainID ", vm.toString(chainId), ", Version ", PACKAGE_VERSION);
        bytes32 expectedSalt = bytes32(abi.encodePacked(salt));

        assertEq(baseScript.constructCreate2Salt(), expectedSalt, "create2 salt");
    }

    function testFuzz_GetAdmin(uint64 chainId) external setChainId(chainId) {
        if (chainId == ChainId.ARBITRUM) {
            assertEq(baseScript.getAdmin(), 0xF34E41a6f6Ce5A45559B1D3Ee92E141a3De96376, "arbitrum admin");
        } else if (chainId == ChainId.AVALANCHE) {
            assertEq(baseScript.getAdmin(), 0x4735517616373c5137dE8bcCDc887637B8ac85Ce, "avalanche admin");
        } else if (chainId == ChainId.BASE) {
            assertEq(baseScript.getAdmin(), 0x83A6fA8c04420B3F9C7A4CF1c040b63Fbbc89B66, "base admin");
        } else if (chainId == ChainId.BSC) {
            assertEq(baseScript.getAdmin(), 0x6666cA940D2f4B65883b454b7Bc7EEB039f64fa3, "bsc admin");
        } else if (chainId == ChainId.CHILIZ) {
            assertEq(baseScript.getAdmin(), 0x74A234DcAdFCB395b37C8c2B3Edf7A13Be78c935, "chiliz admin");
        } else if (chainId == ChainId.ETHEREUM) {
            assertEq(baseScript.getAdmin(), 0x79Fb3e81aAc012c08501f41296CCC145a1E15844, "ethereum admin");
        } else if (chainId == ChainId.GNOSIS) {
            assertEq(baseScript.getAdmin(), 0x72ACB57fa6a8fa768bE44Db453B1CDBa8B12A399, "gnosis admin");
        } else if (chainId == ChainId.LINEA) {
            assertEq(baseScript.getAdmin(), 0x72dCfa0483d5Ef91562817C6f20E8Ce07A81319D, "linea admin");
        } else if (chainId == ChainId.OPTIMISM) {
            assertEq(baseScript.getAdmin(), 0x43c76FE8Aec91F63EbEfb4f5d2a4ba88ef880350, "optimism admin");
        } else if (chainId == ChainId.POLYGON) {
            assertEq(baseScript.getAdmin(), 0x40A518C5B9c1d3D6d62Ba789501CE4D526C9d9C6, "polygon admin");
        } else if (chainId == ChainId.SCROLL) {
            assertEq(baseScript.getAdmin(), 0x0F7Ad835235Ede685180A5c611111610813457a9, "scroll admin");
        } else if (chainId == ChainId.ZKSYNC) {
            assertEq(baseScript.getAdmin(), 0xaFeA787Ef04E280ad5Bb907363f214E4BAB9e288, "zksync admin");
        } else {
            assertEq(baseScript.getAdmin(), baseScript.DEFAULT_SABLIER_ADMIN(), "default admin");
        }
    }

    function testFuzz_GetChainlinkOracle(uint64 chainId) external setChainId(chainId) {
        if (chainId == ChainId.ARBITRUM) {
            assertEq(baseScript.getChainlinkOracle(), 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612, "arbitrum oracle");
        } else if (chainId == ChainId.AVALANCHE) {
            assertEq(baseScript.getChainlinkOracle(), 0x0A77230d17318075983913bC2145DB16C7366156, "avalanche oracle");
        } else if (chainId == ChainId.BASE) {
            assertEq(baseScript.getChainlinkOracle(), 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70, "base oracle");
        } else if (chainId == ChainId.BASE_SEPOLIA) {
            assertEq(baseScript.getChainlinkOracle(), 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1, "base sepolia oracle");
        } else if (chainId == ChainId.BSC) {
            assertEq(baseScript.getChainlinkOracle(), 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE, "bsc oracle");
        } else if (chainId == ChainId.ETHEREUM) {
            assertEq(baseScript.getChainlinkOracle(), 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, "ethereum oracle");
        } else if (chainId == ChainId.GNOSIS) {
            assertEq(baseScript.getChainlinkOracle(), 0x678df3415fc31947dA4324eC63212874be5a82f8, "gnosis oracle");
        } else if (chainId == ChainId.LINEA) {
            assertEq(baseScript.getChainlinkOracle(), 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA, "linea oracle");
        } else if (chainId == ChainId.OPTIMISM) {
            assertEq(baseScript.getChainlinkOracle(), 0x13e3Ee699D1909E989722E753853AE30b17e08c5, "optimism oracle");
        } else if (chainId == ChainId.OPTIMISM_SEPOLIA) {
            assertEq(
                baseScript.getChainlinkOracle(), 0x61Ec26aA57019C486B10502285c5A3D4A4750AD7, "optimism sepolia oracle"
            );
        } else if (chainId == ChainId.POLYGON) {
            assertEq(baseScript.getChainlinkOracle(), 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0, "polygon oracle");
        } else if (chainId == ChainId.SCROLL) {
            assertEq(baseScript.getChainlinkOracle(), 0x6bF14CB0A831078629D993FDeBcB182b21A8774C, "scroll oracle");
        } else if (chainId == ChainId.SEPOLIA) {
            assertEq(baseScript.getChainlinkOracle(), 0x694AA1769357215DE4FAC081bf1f309aDC325306, "sepolia oracle");
        } else if (chainId == ChainId.SONIC) {
            assertEq(baseScript.getChainlinkOracle(), 0xc76dFb89fF298145b417d221B2c747d84952e01d, "sonic oracle");
        } else if (chainId == ChainId.ZKSYNC) {
            assertEq(baseScript.getChainlinkOracle(), 0x6D41d1dc818112880b40e26BD6FD347E41008eDA, "zksync oracle");
        } else {
            assertEq(baseScript.getChainlinkOracle(), address(0), "default oracle");
        }
    }

    function testFuzz_GetComptroller(uint64 chainId) external setChainId(chainId) {
        if (ChainId.isSupported(chainId)) {
            if (chainId == ChainId.LINEA) {
                assertEq(baseScript.getComptroller(), 0xF21b304A08993f98A79C7Eb841f812CCeab49B8b, "comptroller");
            } else {
                assertEq(baseScript.getComptroller(), 0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399, "comptroller");
            }
        } else {
            // It should revert.
            vm.expectRevert("Comptroller: not found");
            baseScript.getComptroller();
        }
    }

    function testFuzz_GetInitialMinFeeUSD(uint64 chainId) external setChainId(chainId) {
        if (baseScript.getChainlinkOracle() != address(0)) {
            assertEq(baseScript.getInitialMinFeeUSD(), 1e8, "initial min fee");
        } else {
            assertEq(baseScript.getInitialMinFeeUSD(), 0, "initial min fee");
        }
    }

    function testFuzz_GetVersion(uint64 chainId) external setChainId(chainId) {
        assertEq(baseScript.getVersion(), PACKAGE_VERSION, "version");
    }
}
