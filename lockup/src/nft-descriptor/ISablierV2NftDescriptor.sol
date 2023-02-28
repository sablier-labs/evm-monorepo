// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { ISablierV2Lockup } from "../interfaces/ISablierV2Lockup.sol";

/// @title ISablierV2NftDescriptor
interface ISablierV2NftDescriptor {
    function tokenURI(ISablierV2Lockup lockup, uint256 streamId) external view returns (string memory uri);
}
