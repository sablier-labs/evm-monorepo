// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

/// This file simply re-exports all PRBMath types needed in v2-core. It is provided for convenience to
/// users so that they don't have to install PRBMath separately.

import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
