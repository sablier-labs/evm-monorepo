// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

contract TargetPanic {
    function failedAssertion() external pure {
        assert(false);
    }

    function arithmeticOverflow() external pure returns (uint256) {
        return type(uint256).max + 1;
    }

    function divisionByZero() external pure returns (uint256) {
        uint256 x = 0;
        return type(uint256).max / x;
    }

    function indexOOB() external pure returns (uint256) {
        uint256[] memory x = new uint256[](1);
        return x[5];
    }
}
