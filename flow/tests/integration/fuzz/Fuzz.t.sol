// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Base_Test } from "../../Base.t.sol";
import { Integration_Test } from "../Integration.t.sol";

abstract contract Shared_Integration_Fuzz_Test is Integration_Test {
    IERC20 internal token;
    uint128 internal depositedAmount;

    /*//////////////////////////////////////////////////////////////////////////
                                     FIXTURES
    //////////////////////////////////////////////////////////////////////////*/

    // 40% of fuzz tests will load input parameters from the below fixtures.
    address[4] public fixtureCaller = [users.sender, users.recipient, users.operator, users.eve];
    uint256[19] public fixtureStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                      SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        // Base setup is used because stream created and time warp by Integration setup are not required.
        Base_Test.setUp();

        // Create streams with all possible decimals.
        _setupStreamsWithAllDecimals();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev An internal function to fuzz the stream id and decimals based on whether the stream ID exists or not.
    ///
    /// @param streamId The stream ID to fuzz.
    /// @param decimals The decimals to fuzz.
    ///
    /// @return uint256 The fuzzed stream ID of either a stream picked from the fixture or a new stream.
    /// @return uint8 The fuzzed decimals.
    /// @return uint128 The fuzzed deposit amount.
    function useFuzzedStreamOrCreate(uint256 streamId, uint8 decimals) internal returns (uint256, uint8, uint128) {
        // Check if stream id is picked from the fixtures.
        if (!flow.isStream(streamId)) {
            // If not, create a new stream.
            decimals = boundUint8(decimals, 0, 18);

            // Create stream.
            (token, streamId) = createTokenAndStream(decimals);

            // Hash the next stream ID and the decimal to generate a seed.
            uint128 amountSeed = uint128(uint256(keccak256(abi.encodePacked(flow.nextStreamId(), decimals))));
            // Bound the amount between a realistic range.
            uint128 amount = boundUint128(amountSeed, 1e18, 200_000e18);
            uint128 depositAmount = uint128(getDescaledAmount(amount, decimals));

            // Deposit into the stream.
            deposit(streamId, depositAmount);

            return (streamId, decimals, depositAmount);
        }

        token = flow.getToken(streamId);
        decimals = flow.getTokenDecimals(streamId);
        return (streamId, decimals, getDefaultDepositAmount(decimals));
    }

    /// @dev Helper function to return the address of either recipient or operator depending on the value of `timeJump`.
    /// This function is used to prank the caller in {withdraw}, {withdrawMax} and {void} calls.
    function useRecipientOrOperator(uint256 streamId, uint40 timeJump) internal returns (address) {
        if (timeJump % 2 != 0) {
            return users.recipient;
        } else {
            resetPrank({ msgSender: users.recipient });
            flow.approve({ to: users.operator, tokenId: streamId });
            return users.operator;
        }
    }

    function _setupStreamsWithAllDecimals() private {
        for (uint8 decimal; decimal < 19; ++decimal) {
            // Create token, create stream and deposit.
            (token, fixtureStreamId[decimal]) = createTokenAndStream(decimal);

            depositDefaultAmount(fixtureStreamId[decimal]);
        }
    }
}
