// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

interface USDTLike {
    function isBlackListed(address) external view returns (bool);
}
