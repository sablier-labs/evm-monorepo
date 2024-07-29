// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2LockupDynamic } from "src/core/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "src/core/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupTranched } from "src/core/interfaces/ISablierV2LockupTranched.sol";
import { LockupDynamic, LockupLinear, LockupTranched } from "src/core/types/DataTypes.sol";
import { ISablierV2MerkleLL } from "src/periphery/interfaces/ISablierV2MerkleLL.sol";
import { ISablierV2MerkleLT } from "src/periphery/interfaces/ISablierV2MerkleLT.sol";
import { SablierV2MerkleLL } from "src/periphery/SablierV2MerkleLL.sol";
import { SablierV2MerkleLT } from "src/periphery/SablierV2MerkleLT.sol";

import { Base_Test } from "../Base.t.sol";

contract Periphery_Test is Base_Test {
    ISablierV2MerkleLL internal merkleLL;
    ISablierV2MerkleLT internal merkleLT;

    /*//////////////////////////////////////////////////////////////////////////
                                     SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve `spender` to spend assets from `from`.
    function approveContract(IERC20 asset_, address from, address spender) internal {
        resetPrank({ msgSender: from });
        (bool success,) = address(asset_).call(abi.encodeCall(IERC20.approve, (spender, MAX_UINT256)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EXPECT-CALLS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects multiple calls to {ISablierV2LockupDynamic.createWithDurations}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithDurationsLD(
        uint64 count,
        LockupDynamic.CreateWithDurations memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupDynamic),
            count: count,
            data: abi.encodeCall(ISablierV2LockupDynamic.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupLinear.createWithDurations}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithDurationsLL(
        uint64 count,
        LockupLinear.CreateWithDurations memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupLinear),
            count: count,
            data: abi.encodeCall(ISablierV2LockupLinear.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupTranched.createWithDurations}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithDurationsLT(
        uint64 count,
        LockupTranched.CreateWithDurations memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupTranched),
            count: count,
            data: abi.encodeCall(ISablierV2LockupTranched.createWithDurations, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupDynamic.createWithTimestamps}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLD(
        uint64 count,
        LockupDynamic.CreateWithTimestamps memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupDynamic),
            count: count,
            data: abi.encodeCall(ISablierV2LockupDynamic.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupLinear.createWithTimestamps}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLL(
        uint64 count,
        LockupLinear.CreateWithTimestamps memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupLinear),
            count: count,
            data: abi.encodeCall(ISablierV2LockupLinear.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {ISablierV2LockupTranched.createWithTimestamps}, each with the specified
    /// `params`.
    function expectMultipleCallsToCreateWithTimestampsLT(
        uint64 count,
        LockupTranched.CreateWithTimestamps memory params
    )
        internal
    {
        vm.expectCall({
            callee: address(lockupTranched),
            count: count,
            data: abi.encodeCall(ISablierV2LockupTranched.createWithTimestamps, (params))
        });
    }

    /// @dev Expects multiple calls to {IERC20.transfer}.
    function expectMultipleCallsToTransfer(uint64 count, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), count: count, data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects multiple calls to {IERC20.transferFrom}.
    function expectMultipleCallsToTransferFrom(uint64 count, address from, address to, uint256 value) internal {
        expectMultipleCallsToTransferFrom(dai, count, from, to, value);
    }

    /// @dev Expects multiple calls to {IERC20.transferFrom}.
    function expectMultipleCallsToTransferFrom(
        IERC20 asset,
        uint64 count,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        vm.expectCall({
            callee: address(asset),
            count: count,
            data: abi.encodeCall(IERC20.transferFrom, (from, to, value))
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLLAddress(
        address caller,
        address admin,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                caller,
                address(asset_),
                defaults.CANCELABLE(),
                expiration,
                admin,
                abi.encode(defaults.IPFS_CID()),
                merkleRoot,
                defaults.NAME_BYTES32(),
                defaults.TRANSFERABLE(),
                lockupLinear,
                abi.encode(defaults.durations())
            )
        );
        bytes32 creationBytecodeHash = keccak256(getMerkleLLBytecode(admin, asset_, merkleRoot, expiration));
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleLockupFactory)
        });
    }

    function computeMerkleLTAddress(
        address caller,
        address admin,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                caller,
                address(asset_),
                defaults.CANCELABLE(),
                expiration,
                admin,
                abi.encode(defaults.IPFS_CID()),
                merkleRoot,
                defaults.NAME_BYTES32(),
                defaults.TRANSFERABLE(),
                lockupTranched,
                abi.encode(defaults.tranchesWithPercentages())
            )
        );
        bytes32 creationBytecodeHash = keccak256(getMerkleLTBytecode(admin, asset_, merkleRoot, expiration));
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleLockupFactory)
        });
    }

    function getMerkleLLBytecode(
        address admin,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (bytes memory)
    {
        bytes memory constructorArgs =
            abi.encode(defaults.baseParams(admin, asset_, expiration, merkleRoot), lockupLinear, defaults.durations());
        if (!isTestOptimizedProfile()) {
            return bytes.concat(type(SablierV2MerkleLL).creationCode, constructorArgs);
        } else {
            return
                bytes.concat(vm.getCode("out-optimized/SablierV2MerkleLL.sol/SablierV2MerkleLL.json"), constructorArgs);
        }
    }

    function getMerkleLTBytecode(
        address admin,
        IERC20 asset_,
        bytes32 merkleRoot,
        uint40 expiration
    )
        internal
        view
        returns (bytes memory)
    {
        bytes memory constructorArgs = abi.encode(
            defaults.baseParams(admin, asset_, expiration, merkleRoot),
            lockupTranched,
            defaults.tranchesWithPercentages()
        );
        if (!isTestOptimizedProfile()) {
            return bytes.concat(type(SablierV2MerkleLT).creationCode, constructorArgs);
        } else {
            return
                bytes.concat(vm.getCode("out-optimized/SablierV2MerkleLT.sol/SablierV2MerkleLT.json"), constructorArgs);
        }
    }
}
