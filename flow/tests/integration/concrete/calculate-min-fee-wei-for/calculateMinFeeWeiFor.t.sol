// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract CalculateMinFeeWeiFor_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(flow.calculateMinFeeWei, nullStreamId) });
    }

    function test_GivenCustomFeeSet() external givenNotNull {
        setMsgSender(admin);

        uint256 customFeeUSD = 100e8; // 100 USD.

        // Set the custom fee.
        comptroller.setCustomFeeUSDFor({
            protocol: ISablierComptroller.Protocol.Flow,
            user: users.sender,
            customFeeUSD: customFeeUSD
        });

        uint256 expectedFeeWei = (1e18 * customFeeUSD) / ETH_PRICE_USD;

        // It should return the custom fee in wei.
        assertEq(flow.calculateMinFeeWei(defaultStreamId), expectedFeeWei, "customFeeWei");
    }

    function test_GivenCustomFeeNotSet() external view givenNotNull {
        // It should return the minimum fee in wei.
        assertEq(flow.calculateMinFeeWei(defaultStreamId), FLOW_MIN_FEE_WEI, "minFeeWei");
    }
}
