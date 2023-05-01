// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

interface USDCLike {
    function isBlacklisted(address) external view returns (bool);
}
