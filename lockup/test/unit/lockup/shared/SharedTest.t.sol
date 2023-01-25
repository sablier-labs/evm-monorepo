// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { SablierV2Lockup } from "src/abstracts/SablierV2Lockup.sol";
import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Lockup_Test } from "../Lockup.t.sol";

/// @dev There is a lot of common logic between the {SablierV2LockupLinear} and the {SablierV2LockupPro} contracts,
/// specifically that both inherit from the {SablierV2} and the {SablierV2Lockup} contracts. We wrote this test
/// contract to avoid duplicating tests.
abstract contract Shared_Test is Lockup_Test {
    /// @dev A variable that is meant to be overridden by the child test contract, which will be either the
    /// {SablierV2LockupLinear} or the {SablierV2LockupPro} contract.
    ISablierV2 internal sablierV2;

    /// @dev A variable that is meant to be overridden by the child test contract, which will be either the
    /// {SablierV2LockupLinear} or the {SablierV2LockupPro} contract.
    ISablierV2Lockup internal lockup;
}
