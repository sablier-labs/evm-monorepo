// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Base_Test } from "tests/Base.t.sol";

contract GenerateAccentColor_Integration_Concrete_Test is Base_Test {
    function test_GenerateAccentColor() external view {
        // Passing a dummy contract instead of a real Lockup contract to make this test easy to maintain.
        // Note: the address of `noop` depends on the order of the state variables in {Base_Test}.
        string memory actualColor = nftDescriptorMock.generateAccentColor_({ sablier: address(noop), streamId: 1337 });
        string memory expectedColor = "hsl(115,39%,48%)";
        assertEq(actualColor, expectedColor, "accentColor");
    }
}
