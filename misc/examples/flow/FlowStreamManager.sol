// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "@sablier/flow/src/interfaces/ISablierFlow.sol";

contract FlowStreamManager {
    // Mainnet address
    ISablierFlow public constant FLOW = ISablierFlow(0x7a86d3e6894f9c5B5f25FFBDAaE658CFc7569623);

    function adjustRatePerSecond(uint256 streamId) external {
        FLOW.adjustRatePerSecond({ streamId: streamId, newRatePerSecond: ud21x18(0.0001e18) });
    }

    function deposit(uint256 streamId) external {
        FLOW.deposit({ streamId: streamId, amount: 3.14159e18, sender: msg.sender, recipient: address(0xCAFE) });
    }

    function depositAndPause(uint256 streamId) external {
        FLOW.depositAndPause(streamId, 3.14159e18);
    }

    function pause(uint256 streamId) external {
        FLOW.pause(streamId);
    }

    function refund(uint256 streamId) external {
        FLOW.refund({ streamId: streamId, amount: 1.61803e18 });
    }

    function refundAndPause(uint256 streamId) external {
        FLOW.refundAndPause({ streamId: streamId, amount: 1.61803e18 });
    }

    function refundMax(uint256 streamId) external {
        FLOW.refundMax(streamId);
    }

    function restart(uint256 streamId) external {
        FLOW.restart({ streamId: streamId, ratePerSecond: ud21x18(0.0001e18) });
    }

    function restartAndDeposit(uint256 streamId) external {
        FLOW.restartAndDeposit({ streamId: streamId, ratePerSecond: ud21x18(0.0001e18), amount: 2.71828e18 });
    }

    function void(uint256 streamId) external {
        FLOW.void(streamId);
    }

    function withdraw(uint256 streamId) external payable {
        uint256 fee = FLOW.calculateMinFeeWei(streamId);
        FLOW.withdraw{ value: fee }({ streamId: streamId, to: address(0xCAFE), amount: 2.71828e18 });
    }

    function withdrawMax(uint256 streamId) external payable {
        uint256 fee = FLOW.calculateMinFeeWei(streamId);
        FLOW.withdrawMax{ value: fee }({ streamId: streamId, to: address(0xCAFE) });
    }
}
