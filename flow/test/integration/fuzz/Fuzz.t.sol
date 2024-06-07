// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../Integration.t.sol";

abstract contract Shared_Integration_Fuzz_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     FIXTURES
    //////////////////////////////////////////////////////////////////////////*/

    // 40% of fuzz tests will load input parameters from the below fixtures.
    address[3] public fixtureFunder = [users.sender, users.recipient, users.eve];
    uint256[19] public fixtureStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                        SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Integration_Test.setUp();

        _setupStreamsWithAllDecimals();
    }

    function _setupStreamsWithAllDecimals() private {
        for (uint8 decimal; decimal < 19; ++decimal) {
            uint256 nextStreamId = flow.nextStreamId();

            // Hash the next stream ID and the decimal to generate a seed.
            uint256 ratePerSecondSeed = uint256(keccak256(abi.encodePacked(nextStreamId, decimal)));

            // Bound the rate per second between a realistic range.
            uint128 ratePerSecond = uint128(_bound(ratePerSecondSeed, 0.001e18, 10e18));

            // Create asset, create stream and deposit.
            IERC20 asset = createAsset(decimal);
            uint256 streamId = createDefaultStreamWithRatePerSecondAndAsset(ratePerSecond, asset);
            depositDefaultAmountToStream(streamId);

            fixtureStreamId[decimal] = streamId;
        }
    }
}
