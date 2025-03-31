// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { BaseScript } from "./Base.s.sol";

interface IERC20Mint {
    function mint(address beneficiary, uint256 value) external;
}

/// @notice Initializes the protocol by creating some streams and interacting with them.
contract Init is BaseScript {
    function run(ISablierFlow flow, IERC20 token) public broadcast {
        address sender = broadcaster;
        address recipient = broadcaster;

        // Approve the Flow contracts to transfer the ERC-20 tokens from the sender.
        token.approve({ spender: address(flow), value: type(uint256).max });

        for (uint256 i; i < 10; ++i) {
            flow.create({
                sender: sender,
                recipient: recipient,
                ratePerSecond: UD21x18.wrap(uint128(i + 1) * 0.0000001e18),
                token: token,
                transferable: true
            });
        }

        // Deposit into 1st stream.
        flow.deposit({ streamId: 1, amount: 2e18, sender: broadcaster, recipient: broadcaster });

        // Pause the 2nd and 3rd stream.
        flow.pause({ streamId: 2 });
        flow.pause({ streamId: 3 });

        // Partial refund from the 1st stream.
        flow.refund({ streamId: 1, amount: 0.1e18 });

        // Restart the 3rd stream.
        flow.restart({ streamId: 3, ratePerSecond: UD21x18.wrap(0.01e18) });

        // Void the 10th stream.
        flow.void({ streamId: 10 });
    }
}
