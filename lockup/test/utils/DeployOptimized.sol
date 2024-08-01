// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockupDynamic } from "../../src/core/interfaces/ISablierLockupDynamic.sol";
import { ISablierLockupLinear } from "../../src/core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../../src/core/interfaces/ISablierLockupTranched.sol";
import { ISablierBatchLockup } from "../../src/periphery/interfaces/ISablierBatchLockup.sol";
import { ISablierMerkleLockupFactory } from "../../src/periphery/interfaces/ISablierMerkleLockupFactory.sol";

abstract contract DeployOptimized is StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                        CORE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploys {SablierLockupDynamic} from an optimized source compiled with `--via-ir`.
    function deployOptimizedLockupDynamic(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor_,
        uint256 maxSegmentCount
    )
        internal
        returns (ISablierLockupDynamic)
    {
        return ISablierLockupDynamic(
            deployCode(
                "out-optimized/SablierLockupDynamic.sol/SablierLockupDynamic.json",
                abi.encode(initialAdmin, address(nftDescriptor_), maxSegmentCount)
            )
        );
    }

    /// @dev Deploys {SablierLockupLinear} from an optimized source compiled with `--via-ir`.
    function deployOptimizedLockupLinear(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor_
    )
        internal
        returns (ISablierLockupLinear)
    {
        return ISablierLockupLinear(
            deployCode(
                "out-optimized/SablierLockupLinear.sol/SablierLockupLinear.json",
                abi.encode(initialAdmin, address(nftDescriptor_))
            )
        );
    }

    /// @dev Deploys {SablierLockupTranched} from an optimized source compiled with `--via-ir`.
    function deployOptimizedLockupTranched(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor_,
        uint256 maxTrancheCount
    )
        internal
        returns (ISablierLockupTranched)
    {
        return ISablierLockupTranched(
            deployCode(
                "out-optimized/SablierLockupTranched.sol/SablierLockupTranched.json",
                abi.encode(initialAdmin, address(nftDescriptor_), maxTrancheCount)
            )
        );
    }

    /// @dev Deploys {LockupNFTDescriptor} from an optimized source compiled with `--via-ir`.
    function deployOptimizedNFTDescriptor() internal returns (ILockupNFTDescriptor) {
        return ILockupNFTDescriptor(deployCode("out-optimized/LockupNFTDescriptor.sol/LockupNFTDescriptor.json"));
    }

    /// @notice Deploys all Lockup contracts from an optimized source compiled with `--via-ir` in the following order:
    ///
    /// 1. {LockupNFTDescriptor}
    /// 2. {SablierLockupDynamic}
    /// 3. {SablierLockupLinear}
    /// 4. {SablierLockupTranched}
    function deployOptimizedCore(
        address initialAdmin,
        uint256 maxSegmentCount,
        uint256 maxTrancheCount
    )
        internal
        returns (
            ILockupNFTDescriptor nftDescriptor_,
            ISablierLockupDynamic lockupDynamic_,
            ISablierLockupLinear lockupLinear_,
            ISablierLockupTranched lockupTranched_
        )
    {
        nftDescriptor_ = deployOptimizedNFTDescriptor();
        lockupDynamic_ = deployOptimizedLockupDynamic(initialAdmin, nftDescriptor_, maxSegmentCount);
        lockupLinear_ = deployOptimizedLockupLinear(initialAdmin, nftDescriptor_);
        lockupTranched_ = deployOptimizedLockupTranched(initialAdmin, nftDescriptor_, maxTrancheCount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     PERIPHERY
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploys {SablierBatchLockup} from an optimized source compiled with `--via-ir`.
    function deployOptimizedBatchLockup() internal returns (ISablierBatchLockup) {
        return ISablierBatchLockup(deployCode("out-optimized/SablierBatchLockup.sol/SablierBatchLockup.json"));
    }

    /// @dev Deploys {SablierMerkleLockupFactory} from an optimized source compiled with `--via-ir`.
    function deployOptimizedMerkleLockupFactory() internal returns (ISablierMerkleLockupFactory) {
        return ISablierMerkleLockupFactory(
            deployCode("out-optimized/SablierMerkleLockupFactory.sol/SablierMerkleLockupFactory.json")
        );
    }

    /// @notice Deploys all  Periphery contracts from an optimized source in the following order:
    ///
    /// 1. {SablierBatchLockup}
    /// 2. {SablierMerkleLockupFactory}
    function deployOptimizedPeriphery() internal returns (ISablierBatchLockup, ISablierMerkleLockupFactory) {
        return (deployOptimizedBatchLockup(), deployOptimizedMerkleLockupFactory());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      PROTOCOL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys all Lockup and Periphery contracts from an optimized source in the following order:
    ///
    /// 1. {LockupNFTDescriptor}
    /// 2. {SablierLockupDynamic}
    /// 3. {SablierLockupLinear}
    /// 4. {SablierLockupTranched}
    /// 5. {SablierBatchLockup}
    /// 6. {SablierMerkleLockupFactory}
    function deployOptimizedProtocol(
        address initialAdmin,
        uint256 maxSegmentCount,
        uint256 maxTrancheCount
    )
        internal
        returns (
            ILockupNFTDescriptor nftDescriptor_,
            ISablierLockupDynamic lockupDynamic_,
            ISablierLockupLinear lockupLinear_,
            ISablierLockupTranched lockupTranched_,
            ISablierBatchLockup batchLockup_,
            ISablierMerkleLockupFactory merkleLockupFactory_
        )
    {
        (nftDescriptor_, lockupDynamic_, lockupLinear_, lockupTranched_) =
            deployOptimizedCore(initialAdmin, maxSegmentCount, maxTrancheCount);
        (batchLockup_, merkleLockupFactory_) = deployOptimizedPeriphery();
    }
}
