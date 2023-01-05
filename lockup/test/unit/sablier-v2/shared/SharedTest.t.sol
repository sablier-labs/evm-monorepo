// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { SablierV2 } from "src/SablierV2.sol";

import { SablierV2Test } from "../SablierV2.t.sol";

/// @dev There is a lot of common logic between the SablierV2Linear and the SablierV2Pro contracts, so
/// we wrote this test contract to avoid duplicating tests.
abstract contract SharedTest is SablierV2Test {
    /// @dev A property that is meant to be overridden by the child test contract, which will be either the
    /// SablierV2Linear or the SablierV2Pro contract.
    ISablierV2 internal sablierV2;
}
