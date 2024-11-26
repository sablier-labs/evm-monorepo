// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Base_Test } from "tests/Base.t.sol";

contract SafeTokenDecimals_Integration_Concrete_Test is Base_Test {
    function test_WhenTokenNotContract() external view {
        address eoa = vm.addr({ privateKey: 1 });
        uint8 actualDecimals = nftDescriptorMock.safeTokenDecimals_(address(eoa));
        uint8 expectedDecimals = 0;
        assertEq(actualDecimals, expectedDecimals, "decimals");
    }

    function test_WhenDecimalsNotImplemented() external view whenTokenContract {
        uint8 actualDecimals = nftDescriptorMock.safeTokenDecimals_(address(noop));
        uint8 expectedDecimals = 0;
        assertEq(actualDecimals, expectedDecimals, "decimals");
    }

    function test_WhenDecimalsImplemented() external view whenTokenContract {
        uint8 actualDecimals = nftDescriptorMock.safeTokenDecimals_(address(dai));
        uint8 expectedDecimals = dai.decimals();
        assertEq(actualDecimals, expectedDecimals, "decimals");
    }
}
