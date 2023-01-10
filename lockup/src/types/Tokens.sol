// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

/// This file simply re-exports all token interfaces needed in v2-core. It is provided for convenience to
/// users so that they don't have to install openzeppelin-contracts and prb-contracts separately.

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
