// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract GetStream_Linear_Unit_Test is Linear_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        linear.getStream(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        LockupLinear.Stream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
