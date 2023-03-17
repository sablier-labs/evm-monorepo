// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetAsset_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return the zero address.
    function test_GetAsset_StreamNull() external {
        uint256 nullStreamId = 1729;
        IERC20 actualAsset = lockup.getAsset(nullStreamId);
        IERC20 expectedAsset = IERC20(address(0));
        assertEq(actualAsset, expectedAsset, "asset");
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct address of the ERC-20 asset.
    function test_GetAsset() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        IERC20 actualAsset = lockup.getAsset(streamId);
        IERC20 expectedAsset = DEFAULT_ASSET;
        assertEq(actualAsset, expectedAsset, "asset");
    }
}
