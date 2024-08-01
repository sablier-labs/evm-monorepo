// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SablierMerkleLL } from "src/periphery/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/periphery/SablierMerkleLT.sol";

import { Base_Test } from "../Base.t.sol";

contract Periphery_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/
    function setUp() public virtual override {
        Base_Test.setUp();
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
            return bytes.concat(type(SablierMerkleLL).creationCode, constructorArgs);
        } else {
            return bytes.concat(vm.getCode("out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json"), constructorArgs);
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
            return bytes.concat(type(SablierMerkleLT).creationCode, constructorArgs);
        } else {
            return bytes.concat(vm.getCode("out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json"), constructorArgs);
        }
    }
}
