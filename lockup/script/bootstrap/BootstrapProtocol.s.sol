// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ERC20GodMode } from "@prb/contracts/token/erc20/ERC20GodMode.sol";
import { ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Script } from "forge-std/Script.sol";
import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { Broker, LockupLinear, LockupPro } from "src/types/DataTypes.sol";

import { BaseScript } from "../shared/Base.s.sol";

/// @notice Bootstraps the protocol by setting up the comptroller and creating some streams.
contract BootstrapProtocol is BaseScript {
    // prettier-ignore
    // solhint-disable max-line-length
    function run(
        ISablierV2Comptroller comptroller,
        ISablierV2LockupLinear linear,
        ISablierV2LockupPro pro,
        IERC20 asset
    ) public broadcaster {
        address sender = deployer;
        address recipient = vm.addr(vm.deriveKey(mnemonic, 1));

        /*//////////////////////////////////////////////////////////////////////////
                                        COMPTROLLER
        //////////////////////////////////////////////////////////////////////////*/

        // Enable the ERC-20 asset for flash loaning.
        if (!comptroller.isFlashLoanable(asset)) {
            comptroller.toggleFlashAsset(asset);
        }

        // Set the flash fee to 0.05%.
        comptroller.setFlashFee({ newFlashFee: ud(0.0005e18) });

        /*//////////////////////////////////////////////////////////////////////////
                                          LINEAR
        //////////////////////////////////////////////////////////////////////////*/

        // Mint enough assets to the sender.
        ERC20GodMode(address(asset)).mint({ beneficiary: sender, amount: 131_601.1e18 + 10_000e18 });

        // Approve the Sablier contracts to transfer the ERC-20 assets from the sender.
        asset.approve(address(linear), type(uint256).max);
        asset.approve(address(pro), type(uint256).max);

        // Create 7 linear streams with various amounts and durations.
        //
        // - 1st stream: meant to be depleted.
        // - 2th to 4th streams: active.
        // - 5th stream: meant to be renounced.
        // - 6th stream: meant to canceled.
        // - 7th stream: meant to be transferred to a third-party.
        uint128[] memory totalAmounts = Solarray.uint128s(0.1e18, 1e18, 100e18, 1_000e18, 5_000e18, 25_000e18, 100_000e18 );
        uint40[] memory cliffDurations = Solarray.uint40s(0, 0, 0, 0, 1 days, 1 weeks, 12 weeks);
        uint40[] memory totalDurations = Solarray.uint40s(1 seconds, 1 hours, 1 days, 1 weeks, 4 weeks, 12 weeks, 48 weeks);
        for (uint256 i = 0; i < totalDurations.length; ++i) {
            linear.createWithDurations(LockupLinear.CreateWithDurations({
                sender: sender,
                recipient: recipient,
                totalAmount: totalAmounts[i],
                asset: asset,
                cancelable: true,
                durations: LockupLinear.Durations({ cliff: cliffDurations[i], total: totalDurations[i] }),
                broker: Broker(address(0), ud(0))
            }));
        }

        // Renounce the 5th stream.
        linear.renounce({ streamId: 5 });

        // Cancel the 6th stream.
        linear.cancel({ streamId: 6 });

        /*//////////////////////////////////////////////////////////////////////////
                                            PRO
        //////////////////////////////////////////////////////////////////////////*/

        // Create the default pro stream.
        LockupPro.SegmentWithDelta[] memory segments = new LockupPro.SegmentWithDelta[](2);
        segments[0] = LockupPro.SegmentWithDelta({ amount: 2_500e18, exponent: ud2x18(3.14e18), delta: 1 hours });
        segments[1] = LockupPro.SegmentWithDelta({ amount: 7_500e18, exponent: ud2x18(0.5e18), delta: 1 weeks });
        pro.createWithDeltas(LockupPro.CreateWithDeltas({
            sender: sender,
            recipient: recipient,
            totalAmount: 10_000e18,
            asset: asset,
            cancelable: true,
            segments: segments,
            broker: Broker(address(0), ud(0))
        }));
    }
}
