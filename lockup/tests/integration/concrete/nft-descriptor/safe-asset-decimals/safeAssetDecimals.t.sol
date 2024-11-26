// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Base_Test } from "tests/Base.t.sol";

contract SafeAssetDecimals_Integration_Concrete_Test is Base_Test {
    function test_WhenAssetNotContract() external view {
        address eoa = vm.addr({ privateKey: 1 });
        uint8 actualDecimals = nftDescriptorMock.safeAssetDecimals_(address(eoa));
        uint8 expectedDecimals = 0;
        assertEq(actualDecimals, expectedDecimals, "decimals");
    }

    function test_WhenDecimalsNotImplemented() external view whenAssetContract {
        uint8 actualDecimals = nftDescriptorMock.safeAssetDecimals_(address(noop));
        uint8 expectedDecimals = 0;
        assertEq(actualDecimals, expectedDecimals, "decimals");
    }

    function test_WhenDecimalsImplemented() external view whenAssetContract {
        uint8 actualDecimals = nftDescriptorMock.safeAssetDecimals_(address(dai));
        uint8 expectedDecimals = dai.decimals();
        assertEq(actualDecimals, expectedDecimals, "decimals");
    }
}
