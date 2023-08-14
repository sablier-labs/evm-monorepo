// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-unused-import
pragma solidity >=0.8.19;

// Math.sol
//
// This file re-exports all PRBMath types used in V2 Core. It is provided for convenience so
// that users don't have to install PRBMath separately.

import { SD59x18, sd, sd59x18 } from "@prb/math/src/SD59x18.sol";
import { UD2x18, ud2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud, ud60x18 } from "@prb/math/src/UD60x18.sol";
