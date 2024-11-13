// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { CreateWithTimestampsLD_BatchLockup_Fork_Test } from "../batch-lockup/createWithTimestampsLD.t.sol";
import { CreateWithTimestampsLL_BatchLockup_Fork_Test } from "../batch-lockup/createWithTimestampsLL.t.sol";
import { CreateWithTimestampsLT_BatchLockup_Fork_Test } from "../batch-lockup/createWithTimestampsLT.t.sol";
import { MerkleInstant_Fork_Test } from "../merkle-campaign/MerkleInstant.t.sol";
import { MerkleLL_Fork_Test } from "../merkle-campaign/MerkleLL.t.sol";
import { MerkleLT_Fork_Test } from "../merkle-campaign/MerkleLT.t.sol";

/// @dev An ERC-20 asset with 6 decimals.
IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

contract USDC_CreateWithTimestampsLD_BatchLockup_Fork_Test is CreateWithTimestampsLD_BatchLockup_Fork_Test(usdc) { }

contract USDC_CreateWithTimestampsLL_BatchLockup_Fork_Test is CreateWithTimestampsLL_BatchLockup_Fork_Test(usdc) { }

contract USDC_CreateWithTimestampsLT_BatchLockup_Fork_Test is CreateWithTimestampsLT_BatchLockup_Fork_Test(usdc) { }

contract USDC_MerkleInstant_Fork_Test is MerkleInstant_Fork_Test(usdc) { }

contract USDC_MerkleLL_Fork_Test is MerkleLL_Fork_Test(usdc) { }

contract USDC_MerkleLT_Fork_Test is MerkleLT_Fork_Test(usdc) { }
