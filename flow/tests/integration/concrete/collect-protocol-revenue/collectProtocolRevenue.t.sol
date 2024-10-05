// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlowBase } from "src/interfaces/ISablierFlowBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "./../../Integration.t.sol";

contract CollectProtocolRevenue_Integration_Concrete_Test is Integration_Test {
    uint256 internal streamIdWithProtocolFee;

    function setUp() public override {
        Integration_Test.setUp();

        // Go back in time to create a stream with a protocol fee.
        vm.warp({ newTimestamp: OCT_1_2024 });

        streamIdWithProtocolFee = createDefaultStream(tokenWithProtocolFee);
        depositDefaultAmount(streamIdWithProtocolFee);

        // Simulate one month of streaming.
        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        flow.collectProtocolRevenue(tokenWithProtocolFee, users.eve);
    }

    function test_RevertGiven_ProtocolRevenueZero() external whenCallerAdmin {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlowBase_NoProtocolRevenue.selector, address(tokenWithProtocolFee))
        );
        flow.collectProtocolRevenue(tokenWithProtocolFee, users.admin);
    }

    function test_GivenProtocolRevenueNotZero() external whenCallerAdmin {
        // Withdraw to generate protocol revenue.
        flow.withdraw({ streamId: streamIdWithProtocolFee, to: users.recipient, amount: WITHDRAW_AMOUNT_6D });

        uint256 previousAggregateAmount = flow.aggregateBalance(tokenWithProtocolFee);

        // It should transfer protocol revenue to provided address.
        expectCallToTransfer({ token: tokenWithProtocolFee, to: users.admin, amount: PROTOCOL_FEE_AMOUNT_6D });

        // It should emit {CollectProtocolRevenue} and {Transfer} events.
        vm.expectEmit({ emitter: address(tokenWithProtocolFee) });
        emit IERC20.Transfer({ from: address(flow), to: users.admin, value: PROTOCOL_FEE_AMOUNT_6D });
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.CollectProtocolRevenue(
            users.admin, tokenWithProtocolFee, users.admin, PROTOCOL_FEE_AMOUNT_6D
        );

        flow.collectProtocolRevenue(tokenWithProtocolFee, users.admin);

        // It should reduce the aggregate amount.
        assertEq(
            flow.aggregateBalance(tokenWithProtocolFee),
            previousAggregateAmount - PROTOCOL_FEE_AMOUNT_6D,
            "aggregate amount"
        );

        // It should set protocol revenue to zero.
        assertEq(flow.protocolRevenue(tokenWithProtocolFee), 0, "protocol revenue");
    }
}
