// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommonBase } from "forge-std/src/Base.sol";
import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { BaseScript } from "script/Base.sol";

contract BaseScriptMock is BaseScript { }

contract BaseScript_Test is StdAssertions, CommonBase {
    using Strings for uint256;

    BaseScriptMock internal baseScript;

    uint256[10] internal supportedChainIds;

    function setUp() public {
        baseScript = new BaseScriptMock();

        supportedChainIds = [1, 42_161, 43_114, 8453, 56, 100, 59_144, 10, 137, 534_352];
    }

    function test_ConstructCreate2Salt() public view {
        string memory chainId = block.chainid.toString();
        string memory version = "1.3.0";
        string memory salt = string.concat("ChainID ", chainId, ", Version ", version);

        bytes32 actualSalt = baseScript.SALT();
        bytes32 expectedSalt = bytes32(abi.encodePacked(salt));
        assertEq(actualSalt, expectedSalt, "CREATE2 salt mismatch");
    }

    function test_ChainlinkOracle() public {
        for (uint256 i; i < supportedChainIds.length; i++) {
            vm.chainId(supportedChainIds[i]);

            // Assert that the Chainlink oracle is not 0 for supported chains.
            assertNotEq(baseScript.chainlinkOracle(), address(0), "Chainlink oracle mismatch");
        }
    }

    function test_InitialMinimumFee() public {
        for (uint256 i; i < supportedChainIds.length; ++i) {
            vm.chainId(supportedChainIds[i]);

            // Assert that the initial minimum fee is 1e8 for supported chains.
            assertEq(baseScript.initialMinimumFee(), 1e8, "Initial minimum fee mismatch");
        }

        // Assert that the initial minimum fee is 0 for unsupported chains.
        vm.chainId(999);
        assertEq(baseScript.initialMinimumFee(), 0, "Initial minimum fee mismatch");
    }
}
