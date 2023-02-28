// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

import { ISablierV2Lockup } from "../interfaces/ISablierV2Lockup.sol";
import { ISablierV2NftDescriptor } from "./ISablierV2NftDescriptor.sol";

/// @title SablierV2NftDescriptor
/// @dev This is an example of an NFT descriptor, used in our scripts and tests.
contract SablierV2NftDescriptor is ISablierV2NftDescriptor {
    function tokenURI(ISablierV2Lockup lockup, uint256 streamId) external view override returns (string memory uri) {
        lockup.getStartTime(streamId);
        uri = "This is an nft descriptor";
    }
}
