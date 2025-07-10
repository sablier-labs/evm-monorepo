// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

contract TargetReverter {
    error SomeError();

    function withNothing() external pure {
        // solhint-disable-next-line reason-string
        revert();
    }

    function withCustomError() external pure {
        revert SomeError();
    }

    function withRequire() external pure {
        require(false, "You shall not pass");
    }

    function withReasonString() external pure {
        revert("You shall not pass");
    }
}
