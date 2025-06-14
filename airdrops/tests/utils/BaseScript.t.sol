// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { StdAssertions } from "forge-std/src/StdAssertions.sol";

contract BaseScriptMock is EvmUtilsBaseScript { }

contract BaseScript_Test is StdAssertions {
    using Strings for uint256;

    BaseScriptMock internal baseScript;

    uint256[10] internal supportedChainIds;

    function setUp() public {
        baseScript = new BaseScriptMock();
    }

    function test_ConstructCreate2Salt() public view {
        string memory chainId = block.chainid.toString();
        string memory version = "1.3.0";
        string memory salt = string.concat("ChainID ", chainId, ", Version ", version);

        bytes32 actualSalt = baseScript.SALT();
        bytes32 expectedSalt = bytes32(abi.encodePacked(salt));
        assertEq(actualSalt, expectedSalt, "CREATE2 salt mismatch");
    }
}
