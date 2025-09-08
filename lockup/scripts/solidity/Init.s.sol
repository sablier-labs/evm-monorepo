// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockup } from "../../src/interfaces/ISablierLockup.sol";
import { Lockup } from "../../src/types/Lockup.sol";
import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupLinear } from "../../src/types/LockupLinear.sol";

interface IERC20Mint {
    function mint(address beneficiary, uint256 value) external;
}

/// @notice Initializes the protocol by creating some streams.
contract Init is BaseScript {
    function run(ISablierLockup lockup, IERC20 token) public broadcast {
        address sender = broadcaster;
        address recipient = vm.addr(vm.deriveKey({ mnemonic: mnemonic, index: 1 }));

        /*//////////////////////////////////////////////////////////////////////////
                                       LOCKUP-LINEAR
        //////////////////////////////////////////////////////////////////////////*/

        // Mint enough tokens to the sender.
        IERC20Mint(address(token)).mint({ beneficiary: sender, value: 131_601.1e18 + 10_000e18 });

        // Approve the Lockup contracts to transfer the ERC-20 tokens from the sender.
        token.approve({ spender: address(lockup), value: type(uint256).max });

        // Create 7 LL streams with various amounts and durations.
        //
        // - 1st stream: meant to be depleted.
        // - 2th to 4th streams: pending or streaming.
        // - 5th stream: meant to be renounced.
        // - 6th stream: meant to canceled.
        // - 7th stream: meant to be transferred to a third party.
        uint128[] memory depositAmounts =
            Solarray.uint128s(0.1e18, 1e18, 100e18, 1000e18, 5000e18, 25_000e18, 100_000e18);
        uint40[] memory cliffDurations = Solarray.uint40s(0, 0, 0, 0, 24 hours, 1 weeks, 12 weeks);
        uint40[] memory totalDurations =
            Solarray.uint40s(1 seconds, 1 hours, 24 hours, 1 weeks, 4 weeks, 12 weeks, 48 weeks);
        for (uint256 i = 0; i < totalDurations.length; ++i) {
            lockup.createWithDurationsLL(
                Lockup.CreateWithDurations({
                    sender: sender,
                    recipient: recipient,
                    depositAmount: depositAmounts[i],
                    token: token,
                    cancelable: true,
                    transferable: true,
                    shape: "Cliff Linear"
                }),
                LockupLinear.UnlockAmounts({ start: 0, cliff: 0 }),
                LockupLinear.Durations({ cliff: cliffDurations[i], total: totalDurations[i] })
            );
        }

        // Renounce the 5th stream.
        lockup.renounce({ streamId: 5 });

        // Cancel the 6th stream.
        lockup.cancel({ streamId: 6 });

        /*//////////////////////////////////////////////////////////////////////////
                                       LOCKUP-DYNAMIC
        //////////////////////////////////////////////////////////////////////////*/

        // Create the default lockupDynamic stream.
        LockupDynamic.SegmentWithDuration[] memory segments = new LockupDynamic.SegmentWithDuration[](2);
        segments[0] =
            LockupDynamic.SegmentWithDuration({ amount: 2500e18, exponent: ud2x18(3.14e18), duration: 1 hours });
        segments[1] =
            LockupDynamic.SegmentWithDuration({ amount: 7500e18, exponent: ud2x18(0.5e18), duration: 1 weeks });
        lockup.createWithDurationsLD(
            Lockup.CreateWithDurations({
                sender: sender,
                recipient: recipient,
                depositAmount: 10_000e18,
                token: token,
                cancelable: true,
                transferable: true,
                shape: "Exponential Dynamic"
            }),
            segments
        );
    }
}
