// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <=0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Script } from "forge-std/Script.sol";
import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "../../src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "../../src/interfaces/ISablierV2LockupLinear.sol";
import { Broker, LockupLinear, LockupDynamic } from "../../src/types/DataTypes.sol";
import { ud2x18, ud60x18 } from "../../src/types/Math.sol";

import { BaseScript } from "../shared/Base.s.sol";

interface IERC20Mint {
    function mint(address beneficiary, uint256 amount) external;
}

/// @notice Bootstraps the protocol by setting up the comptroller and creating some streams.
contract BootstrapProtocol is BaseScript {
    function run(
        ISablierV2Comptroller comptroller,
        ISablierV2LockupLinear linear,
        ISablierV2LockupDynamic dynamic,
        IERC20 asset
    )
        public
        broadcaster
    {
        address sender = deployer;
        address recipient = vm.addr(vm.deriveKey(mnemonic, 1));

        /*//////////////////////////////////////////////////////////////////////////
                                        COMPTROLLER
        //////////////////////////////////////////////////////////////////////////*/

        // Enable the ERC-20 asset for flash loaning.
        if (!comptroller.isFlashAsset(asset)) {
            comptroller.toggleFlashAsset(asset);
        }

        // Set the flash fee to 0.05%.
        comptroller.setFlashFee({ newFlashFee: ud60x18(0.0005e18) });

        /*//////////////////////////////////////////////////////////////////////////
                                          LINEAR
        //////////////////////////////////////////////////////////////////////////*/

        // Mint enough assets to the sender.
        IERC20Mint(address(asset)).mint({ beneficiary: sender, amount: 131_601.1e18 + 10_000e18 });

        // Approve the Sablier contracts to transfer the ERC-20 assets from the sender.
        asset.approve({ spender: address(linear), amount: type(uint256).max });
        asset.approve({ spender: address(dynamic), amount: type(uint256).max });

        // Create 7 linear streams with various amounts and durations.
        //
        // - 1st stream: meant to be depleted.
        // - 2th to 4th streams: warm.
        // - 5th stream: meant to be renounced.
        // - 6th stream: meant to canceled.
        // - 7th stream: meant to be transferred to a third party.
        uint128[] memory totalAmounts = Solarray.uint128s(0.1e18, 1e18, 100e18, 1000e18, 5000e18, 25_000e18, 100_000e18);
        uint40[] memory cliffDurations = Solarray.uint40s(0, 0, 0, 0, 24 hours, 1 weeks, 12 weeks);
        uint40[] memory totalDurations =
            Solarray.uint40s(1 seconds, 1 hours, 24 hours, 1 weeks, 4 weeks, 12 weeks, 48 weeks);
        for (uint256 i = 0; i < totalDurations.length; ++i) {
            linear.createWithDurations(
                LockupLinear.CreateWithDurations({
                    sender: sender,
                    recipient: recipient,
                    totalAmount: totalAmounts[i],
                    asset: asset,
                    cancelable: true,
                    durations: LockupLinear.Durations({ cliff: cliffDurations[i], total: totalDurations[i] }),
                    broker: Broker(address(0), ud60x18(0))
                })
            );
        }

        // Renounce the 5th stream.
        linear.renounce({ streamId: 5 });

        // Cancel the 6th stream.
        linear.cancel({ streamId: 6 });

        /*//////////////////////////////////////////////////////////////////////////
                                          DYNAMIC
        //////////////////////////////////////////////////////////////////////////*/

        // Create the default dynamic stream.
        LockupDynamic.SegmentWithDelta[] memory segments = new LockupDynamic.SegmentWithDelta[](2);
        segments[0] = LockupDynamic.SegmentWithDelta({ amount: 2500e18, exponent: ud2x18(3.14e18), delta: 1 hours });
        segments[1] = LockupDynamic.SegmentWithDelta({ amount: 7500e18, exponent: ud2x18(0.5e18), delta: 1 weeks });
        dynamic.createWithDeltas(
            LockupDynamic.CreateWithDeltas({
                asset: asset,
                broker: Broker(address(0), ud60x18(0)),
                cancelable: true,
                recipient: recipient,
                sender: sender,
                segments: segments,
                totalAmount: 10_000e18
            })
        );
    }
}
