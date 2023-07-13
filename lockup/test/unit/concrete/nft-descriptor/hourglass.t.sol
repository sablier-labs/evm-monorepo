// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LibString } from "solady/utils/LibString.sol";

import { SVGElements } from "src/libraries/SVGElements.sol";

import { NFTDescriptor_Unit_Concrete_Test } from "./NFTDescriptor.t.sol";

contract Hourglass_Unit_Concrete_Test is NFTDescriptor_Unit_Concrete_Test {
    using LibString for string;

    function test_Hourglass_Pending() external {
        string memory hourglass = nftDescriptorMock.hourglass_("pending");
        uint256 index = hourglass.indexOf(SVGElements.HOURGLASS_UPPER_BULB);
        assertNotEq(index, LibString.NOT_FOUND, "hourglass upper bulb should be present");
    }

    function test_Hourglass_Streaming() external {
        string memory hourglass = nftDescriptorMock.hourglass_("Streaming");
        uint256 index = hourglass.indexOf(SVGElements.HOURGLASS_UPPER_BULB);
        assertNotEq(index, LibString.NOT_FOUND, "hourglass upper bulb should be present");
    }

    function test_Hourglass_Settled() external {
        string memory hourglass = nftDescriptorMock.hourglass_("Settled");
        uint256 index = hourglass.indexOf(SVGElements.HOURGLASS_UPPER_BULB);
        assertEq(index, LibString.NOT_FOUND, "hourglass upper bulb should NOT be present");
    }

    function test_Hourglass_Canceled() external {
        string memory hourglass = nftDescriptorMock.hourglass_("Canceled");
        uint256 index = hourglass.indexOf(SVGElements.HOURGLASS_UPPER_BULB);
        assertNotEq(index, LibString.NOT_FOUND, "hourglass upper bulb should be present");
    }

    function test_Hourglass_Depleted() external {
        string memory hourglass = nftDescriptorMock.hourglass_("Depleted");
        uint256 index = hourglass.indexOf(SVGElements.HOURGLASS_UPPER_BULB);
        assertEq(index, LibString.NOT_FOUND, "hourglass upper bulb should NOT be present");
    }
}
