// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { StdAssertions } from "forge-std/src/StdAssertions.sol";

import { BaseScript } from "src/tests/BaseScript.sol";

contract BaseScriptMock is BaseScript { }

contract BaseScript_Test is StdAssertions {
    using Strings for uint256;

    BaseScriptMock internal baseScript;

    function setUp() public {
        baseScript = new BaseScriptMock();
    }

    function test_AdminMap() public view {
        assertEq(baseScript.protocolAdmin(), baseScript.DEFAULT_SABLIER_ADMIN(), "default admin mismatch");
    }

    function test_ConstructCreate2Salt() public view {
        string memory salt = string.concat("ChainID ", block.chainid.toString(), ", Version 1.0.0");
        bytes32 expectedSalt = bytes32(abi.encodePacked(salt));

        assertEq(baseScript.constructCreate2Salt(), expectedSalt, "constructCreate2Salt mismatch");
        assertEq(baseScript.SALT(), expectedSalt, "SALT mismatch");
    }

    function test_GetVersion() public view {
        assertEq(baseScript.getVersion(), "1.0.0", "version mismatch");
    }
}
