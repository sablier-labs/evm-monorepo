// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                        SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStream(IERC20 token_) internal returns (uint256) {
        return createDefaultStream(RATE_PER_SECOND, token_);
    }

    function createDefaultStream(UD21x18 ratePerSecond, IERC20 token_) internal returns (uint256) {
        return flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: ratePerSecond,
            token: token_,
            transferable: TRANSFERABLE
        });
    }

    /// @dev Helper function to create an token with the `decimals` and then a stream using the newly created token.
    function createTokenAndStream(uint8 decimals) internal returns (IERC20 token, uint256 streamId) {
        token = createToken(decimals);

        // Hash the next stream ID and the decimal to generate a seed.
        UD21x18 ratePerSecond =
            boundRatePerSecond(ud21x18(uint128(uint256(keccak256(abi.encodePacked(flow.nextStreamId(), decimals))))));

        // Create stream.
        streamId = createDefaultStream(ratePerSecond, token);
    }

    function deposit(uint256 streamId, uint128 amount) internal {
        IERC20 token = flow.getToken(streamId);

        deal({ token: address(token), to: users.sender, give: UINT128_MAX });
        token.approve(address(flow), UINT128_MAX);

        flow.deposit(streamId, amount, users.sender, users.recipient);
    }

    function depositDefaultAmount(uint256 streamId) internal {
        uint8 decimals = flow.getTokenDecimals(streamId);
        uint128 depositAmount = getDefaultDepositAmount(decimals);

        deposit(streamId, depositAmount);
    }

    /// @dev Update the snapshot using `adjustRatePerSecond` and then warp block timestamp to it.
    function updateSnapshotTimeAndWarp(uint256 streamId) internal {
        resetPrank(users.sender);
        UD21x18 ratePerSecond = flow.getRatePerSecond(streamId);

        // Updates the snapshot time via `adjustRatePerSecond`.
        flow.adjustRatePerSecond(streamId, ud21x18(1));

        // Restores the rate per second.
        flow.adjustRatePerSecond(streamId, ratePerSecond);

        // Warp to the snapshot time.
        vm.warp({ newTimestamp: flow.getSnapshotTime(streamId) });
    }
}
