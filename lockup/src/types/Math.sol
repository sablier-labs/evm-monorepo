// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

// This file simply re-exports all PRBMath types needed in v2-core. It is provided for convenience so
// that users don't have to install PRBMath separately.

import { SD59x18, sd, sd59x18 } from "@prb/math/SD59x18.sol";
import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud, ud60x18 } from "@prb/math/UD60x18.sol";
