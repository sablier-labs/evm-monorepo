// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Unit_Test } from "../Dynamic.t.sol";

contract GetStream_Dynamic_Unit_Test is Dynamic_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        dynamic.getStream(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the stream.
    function test_GetStream() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
        LockupDynamic.Stream memory expectedStream = defaultStream;
        assertEq(actualStream, expectedStream);
    }
}
