// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface USDTLike {
    function isBlackListed(address) external view returns (bool);
}
