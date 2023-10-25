// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO: add Broker

library Payroll {
    struct Stream {
        uint128 amountPerSecond;
        uint128 balance;
        address recipient;
        uint40 lastTimeUpdate;
        bool isStream;
        bool wasCanceled;
        address sender;
        IERC20 asset;
    }
}
