// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface USDCLike {
    function isBlacklisted(address) external view returns (bool);
}
