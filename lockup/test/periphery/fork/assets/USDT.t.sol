// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { CreateWithTimestampsLD_BatchLockup_Fork_Test } from "../batch-lockup/createWithTimestampsLD.t.sol";
import { CreateWithTimestampsLL_BatchLockup_Fork_Test } from "../batch-lockup/createWithTimestampsLL.t.sol";
import { CreateWithTimestampsLT_BatchLockup_Fork_Test } from "../batch-lockup/createWithTimestampsLT.t.sol";
import { MerkleInstant_Fork_Test } from "../merkle-campaign/MerkleInstant.t.sol";
import { MerkleLL_Fork_Test } from "../merkle-campaign/MerkleLL.t.sol";
import { MerkleLT_Fork_Test } from "../merkle-campaign/MerkleLT.t.sol";

/// @dev An ERC-20 asset that suffers from the missing return value bug.
IERC20 constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

contract USDT_CreateWithTimestampsLD_BatchLockup_Fork_Test is CreateWithTimestampsLD_BatchLockup_Fork_Test(usdt) { }

contract USDT_CreateWithTimestampsLL_BatchLockup_Fork_Test is CreateWithTimestampsLL_BatchLockup_Fork_Test(usdt) { }

contract USDT_CreateWithTimestampsLT_BatchLockup_Fork_Test is CreateWithTimestampsLT_BatchLockup_Fork_Test(usdt) { }

contract USDT_MerkleInstant_Fork_Test is MerkleInstant_Fork_Test(usdt) { }

contract USDT_MerkleLL_Fork_Test is MerkleLL_Fork_Test(usdt) { }

contract USDT_MerkleLT_Fork_Test is MerkleLT_Fork_Test(usdt) { }
