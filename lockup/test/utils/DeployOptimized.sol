// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierV2Comptroller } from "../../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "../../src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "../../src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "../../src/interfaces/ISablierV2NFTDescriptor.sol";

abstract contract DeployOptimized is StdCheats {
    /// @dev Deploys {SablierV2Comptroller} from an optimized source compiled with `--via-ir`.
    function deployOptimizedComptroller(address initialAdmin) internal returns (ISablierV2Comptroller) {
        return ISablierV2Comptroller(
            deployCode("out-optimized/SablierV2Comptroller.sol/SablierV2Comptroller.json", abi.encode(initialAdmin))
        );
    }

    /// @dev Deploys {SablierV2LockupDynamic} from an optimized source compiled with `--via-ir`.
    function deployOptimizedLockupDynamic(
        address initialAdmin,
        ISablierV2Comptroller comptroller_,
        ISablierV2NFTDescriptor nftDescriptor_,
        uint256 maxSegmentCount
    )
        internal
        returns (ISablierV2LockupDynamic)
    {
        return ISablierV2LockupDynamic(
            deployCode(
                "out-optimized/SablierV2LockupDynamic.sol/SablierV2LockupDynamic.json",
                abi.encode(initialAdmin, address(comptroller_), address(nftDescriptor_), maxSegmentCount)
            )
        );
    }

    /// @dev Deploys {SablierV2LockupLinear} from an optimized source compiled with `--via-ir`.
    function deployOptimizedLockupLinear(
        address initialAdmin,
        ISablierV2Comptroller comptroller_,
        ISablierV2NFTDescriptor nftDescriptor_
    )
        internal
        returns (ISablierV2LockupLinear)
    {
        return ISablierV2LockupLinear(
            deployCode(
                "out-optimized/SablierV2LockupLinear.sol/SablierV2LockupLinear.json",
                abi.encode(initialAdmin, address(comptroller_), address(nftDescriptor_))
            )
        );
    }

    /// @dev Deploys {SablierV2NFTDescriptor} from an optimized source compiled with `--via-ir`.
    function deployOptimizedNFTDescriptor() internal returns (ISablierV2NFTDescriptor) {
        return
            ISablierV2NFTDescriptor(deployCode("out-optimized/SablierV2NFTDescriptor.sol/SablierV2NFTDescriptor.json"));
    }

    function deployOptimizedCore(
        address initialAdmin,
        uint256 maxSegmentCount
    )
        internal
        returns (
            ISablierV2Comptroller comptroller_,
            ISablierV2LockupDynamic lockupDynamic_,
            ISablierV2LockupLinear lockupLinear_,
            ISablierV2NFTDescriptor nftDescriptor_
        )
    {
        comptroller_ = deployOptimizedComptroller(initialAdmin);
        nftDescriptor_ = deployOptimizedNFTDescriptor();
        lockupDynamic_ = deployOptimizedLockupDynamic(initialAdmin, comptroller_, nftDescriptor_, maxSegmentCount);
        lockupLinear_ = deployOptimizedLockupLinear(initialAdmin, comptroller_, nftDescriptor_);
    }
}
