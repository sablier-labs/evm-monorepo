// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

/// This file simply re-exports all token interfaces needed in v2-core. It is provided for convenience to
/// users so that they don't have to install openzeppelin-contracts and prb-contracts separately.

import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
