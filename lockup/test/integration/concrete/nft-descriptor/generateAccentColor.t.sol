// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { NFTDescriptor_Integration_Concrete_Test } from "./NFTDescriptor.t.sol";

contract GenerateAccentColor_Integration_Concrete_Test is NFTDescriptor_Integration_Concrete_Test {
    function test_GenerateAccentColor() external {
        // Passing a dummy contract instead of a real Sablier contract to make this test easy to maintain.
        string memory actualColor = nftDescriptorMock.generateAccentColor_({ sablier: address(noop), streamId: 1337 });
        string memory expectedColor = "hsl(6,51%,82%)";
        assertEq(actualColor, expectedColor, "accentColor");
    }
}
