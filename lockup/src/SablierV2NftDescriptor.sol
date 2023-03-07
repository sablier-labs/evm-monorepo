// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2NftDescriptor } from "src/interfaces/ISablierV2NftDescriptor.sol";

/// @title SablierV2NftDescriptor
/// @dev This is an example of an NFT descriptor, used in our scripts and tests.
contract SablierV2NftDescriptor is ISablierV2NftDescriptor {
    function tokenURI(ISablierV2Lockup lockup, uint256 streamId) external view override returns (string memory uri) {
        lockup.getStartTime(streamId);
        string memory symbol = lockup.symbol();
        uri = string.concat("This is the NFT descriptor for ", symbol);
    }
}
