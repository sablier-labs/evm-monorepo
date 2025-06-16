// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable event-name-capwords
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/utils/Assertions.sol";

import { ISablierLockup } from "../../src/interfaces/ISablierLockup.sol";
import { Lockup } from "../../src/types/Lockup.sol";
import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupLinear } from "../../src/types/LockupLinear.sol";
import { LockupTranched } from "../../src/types/LockupTranched.sol";

abstract contract Assertions is PRBMathAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event log_named_array(string key, LockupDynamic.Segment[] segments);

    event log_named_array(string key, LockupTranched.Tranche[] tranches);

    /*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compares two {Lockup.Amounts} struct entities.
    function assertEq(Lockup.Amounts memory a, Lockup.Amounts memory b) internal pure {
        assertEq(a.deposited, b.deposited, "amounts.deposited");
        assertEq(a.refunded, b.refunded, "amounts.refunded");
        assertEq(a.withdrawn, b.withdrawn, "amounts.withdrawn");
    }

    /// @dev Compares two {IERC20} values.
    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    /// @dev Compares two {Lockup.Model} enum values.
    function assertEq(Lockup.Model a, Lockup.Model b) internal pure {
        assertEq(uint256(a), uint256(b), "Lockup.Model");
    }

    /// @dev Compares two {Lockup.Timestamps} struct entities.
    function assertEq(Lockup.Timestamps memory a, Lockup.Timestamps memory b) internal pure {
        assertEq(a.end, b.end, "timestamps.end");
        assertEq(a.start, b.start, "timestamps.start");
    }

    /// @dev Compares two {LockupDynamic.Segment} arrays.
    function assertEq(LockupDynamic.Segment[] memory a, LockupDynamic.Segment[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [LockupDynamic.Segment[]]");
            emit log_named_array("   Left", a);
            emit log_named_array("  Right", b);
            fail();
        }
    }

    /// @dev Compares two {LockupLinear.UnlockAmounts} structs.
    function assertEq(LockupLinear.UnlockAmounts memory a, LockupLinear.UnlockAmounts memory b) internal pure {
        assertEq(a.start, b.start, "unlockAmounts.start");
        assertEq(a.cliff, b.cliff, "unlockAmounts.cliff");
    }

    /// @dev Compares two {LockupTranched.Tranche} arrays.
    function assertEq(LockupTranched.Tranche[] memory a, LockupTranched.Tranche[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [LockupTranched.Tranche[]]");
            emit log_named_array("   Left", a);
            emit log_named_array("  Right", b);
            fail();
        }
    }

    /// @dev Compares two {Lockup.Status} enum values.
    function assertEq(Lockup.Status a, Lockup.Status b) internal pure {
        assertEq(uint256(a), uint256(b), "status");
    }

    /// @dev Compares two {Lockup.Status} enum values.
    function assertEq(Lockup.Status a, Lockup.Status b, string memory err) internal pure {
        assertEq(uint256(a), uint256(b), err);
    }

    /// @dev Compares two {Lockup.Status} enum values.
    function assertNotEq(Lockup.Status a, Lockup.Status b) internal pure {
        assertNotEq(uint256(a), uint256(b), "status");
    }

    /// @dev Compares two {Lockup.Status} enum values.
    function assertNotEq(Lockup.Status a, Lockup.Status b, string memory err) internal pure {
        assertNotEq(uint256(a), uint256(b), err);
    }

    /// @dev Compares common states between models with {Lockup.CreateWithTimestamps} parameters for a given stream ID.
    function assertEq(
        ISablierLockup lockup,
        uint256 streamId,
        Lockup.CreateWithTimestamps memory expectedLockup
    )
        internal
        view
    {
        assertEq(lockup.getDepositedAmount(streamId), expectedLockup.depositAmount, "depositedAmount");
        assertEq(lockup.getEndTime(streamId), expectedLockup.timestamps.end, "endTime");
        assertEq(lockup.getRecipient(streamId), expectedLockup.recipient, "recipient");
        assertEq(lockup.getSender(streamId), expectedLockup.sender, "sender");
        assertEq(lockup.getStartTime(streamId), expectedLockup.timestamps.start, "startTime");
        assertEq(lockup.getUnderlyingToken(streamId), expectedLockup.token, "underlyingToken");
        assertEq(lockup.getWithdrawnAmount(streamId), 0, "withdrawnAmount");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertEq(lockup.isTransferable(streamId), expectedLockup.transferable, "isTransferable");
        assertEq(lockup.nextStreamId(), streamId + 1, "post-create nextStreamId");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");
        assertEq(lockup.ownerOf(streamId), expectedLockup.recipient, "post-create NFT owner");
    }
}
