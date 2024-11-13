// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { CommonBase } from "forge-std/src/Base.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockup } from "../../src/core/interfaces/ISablierLockup.sol";
import { ISablierBatchLockup } from "../../src/periphery/interfaces/ISablierBatchLockup.sol";
import { ISablierMerkleFactory } from "../../src/periphery/interfaces/ISablierMerkleFactory.sol";

abstract contract DeployOptimized is StdCheats, CommonBase {
    /*//////////////////////////////////////////////////////////////////////////
                                        CORE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploys the optimized {Helpers} and {VestingMath} libraries and assign them to linked addresses.
    function deployOptimizedLibraries() internal {
        address helpers = deployCode("out-optimized/Helpers.sol/Helpers.json");
        address vestingMath = deployCode("out-optimized/VestingMath.sol/VestingMath.json");
        vm.etch(0x7715bE116061E014Bb721b46Dc78Dd57C91FDF9b, helpers.code);
        vm.etch(0x26F9d826BDed47Fc472526aE8095B75ac336963C, vestingMath.code);
    }

    /// @dev Deploys {SablierLockup} from an optimized source compiled with `--via-ir`.
    function deployOptimizedLockup(
        address initialAdmin,
        ILockupNFTDescriptor nftDescriptor_,
        uint256 maxCount
    )
        internal
        returns (ISablierLockup)
    {
        // Deploy the libraries.
        deployOptimizedLibraries();

        // Deploy the Lockup contract.
        return ISablierLockup(
            deployCode(
                "out-optimized/SablierLockup.sol/SablierLockup.json",
                abi.encode(initialAdmin, address(nftDescriptor_), maxCount)
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
    /// 2. {SablierLockup}
    function deployOptimizedCore(
        address initialAdmin,
        uint256 maxCount
    )
        internal
        returns (ILockupNFTDescriptor nftDescriptor_, ISablierLockup lockup_)
    {
        nftDescriptor_ = deployOptimizedNFTDescriptor();
        lockup_ = deployOptimizedLockup(initialAdmin, nftDescriptor_, maxCount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     PERIPHERY
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploys {SablierBatchLockup} from an optimized source compiled with `--via-ir`.
    function deployOptimizedBatchLockup() internal returns (ISablierBatchLockup) {
        return ISablierBatchLockup(deployCode("out-optimized/SablierBatchLockup.sol/SablierBatchLockup.json"));
    }

    /// @dev Deploys {SablierMerkleFactory} from an optimized source compiled with `--via-ir`.
    function deployOptimizedMerkleFactory(address initialAdmin) internal returns (ISablierMerkleFactory) {
        return ISablierMerkleFactory(
            deployCode("out-optimized/SablierMerkleFactory.sol/SablierMerkleFactory.json", abi.encode(initialAdmin))
        );
    }

    /// @notice Deploys all  Periphery contracts from an optimized source in the following order:
    ///
    /// 1. {SablierBatchLockup}
    /// 2. {SablierMerkleFactory}
    function deployOptimizedPeriphery(address initialAdmin)
        internal
        returns (ISablierBatchLockup, ISablierMerkleFactory)
    {
        return (deployOptimizedBatchLockup(), deployOptimizedMerkleFactory(initialAdmin));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      PROTOCOL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys all Lockup and Periphery contracts from an optimized source in the following order:
    ///
    /// 1. {LockupNFTDescriptor}
    /// 2. {SablierLockup}
    /// 5. {SablierBatchLockup}
    /// 6. {SablierMerkleFactory}
    function deployOptimizedProtocol(
        address initialAdmin,
        uint256 maxCount
    )
        internal
        returns (
            ILockupNFTDescriptor nftDescriptor_,
            ISablierLockup lockup_,
            ISablierBatchLockup batchLockup_,
            ISablierMerkleFactory merkleFactory_
        )
    {
        (nftDescriptor_, lockup_) = deployOptimizedCore(initialAdmin, maxCount);
        (batchLockup_, merkleFactory_) = deployOptimizedPeriphery(initialAdmin);
    }
}
