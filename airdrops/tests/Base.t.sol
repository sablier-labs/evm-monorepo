// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "@sablier/lockup/src/LockupNFTDescriptor.sol";
import { SablierLockup } from "@sablier/lockup/src/SablierLockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "src/SablierMerkleFactoryVCA.sol";
import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";
import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";
import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "src/types/DataTypes.sol";
import { Assertions } from "./utils/Assertions.sol";
import { ChainlinkOracleMock } from "./utils/ChainlinkOracleMock.sol";
import { Constants } from "./utils/Constants.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { Fuzzers } from "./utils/Fuzzers.sol";
import { LeafData, MerkleBuilder } from "./utils/MerkleBuilder.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Constants, DeployOptimized, Merkle, Fuzzers {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierLockup internal lockup;
    /// @dev A test contract meant to be overridden by the implementing Merkle campaign contracts.
    ISablierMerkleBase internal merkleBase;
    /// @dev A test contract meant to be overridden by the implementing Merkle factory contracts.
    ISablierMerkleFactoryBase internal merkleFactoryBase;
    ISablierMerkleFactoryInstant internal merkleFactoryInstant;
    ISablierMerkleFactoryLL internal merkleFactoryLL;
    ISablierMerkleFactoryLT internal merkleFactoryLT;
    ISablierMerkleFactoryVCA internal merkleFactoryVCA;
    ISablierMerkleInstant internal merkleInstant;
    ISablierMerkleLL internal merkleLL;
    ISablierMerkleLT internal merkleLT;
    ISablierMerkleVCA internal merkleVCA;
    ChainlinkOracleMock internal oracle;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmUtilsBase.setUp();

        // Create the protocol admin.
        users.admin = payable(makeAddr({ name: "Admin" }));
        vm.startPrank({ msgSender: users.admin });

        // Deploy the Lockup contract.
        LockupNFTDescriptor nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(users.admin, nftDescriptor, 1000);

        // Deploy the mock Chainlink Oracle.
        oracle = new ChainlinkOracleMock();

        // Deploy the Merkle Factory contracts.
        deployMerkleFactoriesConditionally();

        address[] memory spenders = new address[](4);
        spenders[0] = address(merkleFactoryInstant);
        spenders[1] = address(merkleFactoryLL);
        spenders[2] = address(merkleFactoryLT);
        spenders[3] = address(merkleFactoryVCA);

        // Create users for testing.
        users.campaignCreator = createUser("CampaignCreator", spenders);
        users.eve = createUser("Eve", spenders);
        users.recipient = createUser("Recipient", spenders);
        users.recipient1 = createUser("Recipient1", spenders);
        users.recipient2 = createUser("Recipient2", spenders);
        users.recipient3 = createUser("Recipient3", spenders);
        users.recipient4 = createUser("Recipient4", spenders);
        users.sender = createUser("Sender", spenders);

        // Initialize the Merkle tree.
        initMerkleTree();

        // Set the variables in Modifiers contract.
        setVariables(users);

        // Set sender as the default caller for the tests.
        resetPrank({ msgSender: users.sender });

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploys the Merkle Factory contracts conditionally based on the test profile.
    function deployMerkleFactoriesConditionally() internal {
        if (!isTestOptimizedProfile()) {
            merkleFactoryInstant = new SablierMerkleFactoryInstant(users.admin, MINIMUM_FEE, address(oracle));
            merkleFactoryLL = new SablierMerkleFactoryLL(users.admin, MINIMUM_FEE, address(oracle));
            merkleFactoryLT = new SablierMerkleFactoryLT(users.admin, MINIMUM_FEE, address(oracle));
            merkleFactoryVCA = new SablierMerkleFactoryVCA(users.admin, MINIMUM_FEE, address(oracle));
        } else {
            (merkleFactoryInstant, merkleFactoryLL, merkleFactoryLT, merkleFactoryVCA) =
                deployOptimizedMerkleFactories(users.admin, MINIMUM_FEE, address(oracle));
        }
        vm.label({ account: address(merkleFactoryInstant), newLabel: "MerkleFactoryInstant" });
        vm.label({ account: address(merkleFactoryLL), newLabel: "MerkleFactoryLL" });
        vm.label({ account: address(merkleFactoryLT), newLabel: "MerkleFactoryLT" });
        vm.label({ account: address(merkleFactoryVCA), newLabel: "MerkleFactoryVCA" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-BUILDER
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Computes the Merkle proof for the given leaf data and an array of leaves.
    function computeMerkleProof(
        LeafData memory leafData,
        uint256[] storage leaves
    )
        internal
        view
        returns (bytes32[] memory merkleProof)
    {
        uint256 leaf = MerkleBuilder.computeLeaf(leafData);
        uint256 pos = Arrays.findUpperBound(leaves, leaf);

        merkleProof = leaves.length == 1 ? new bytes32[](0) : getProof(leaves.toBytes32(), pos);
    }

    function index1Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX1, users.recipient1);
    }

    function index2Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX2, users.recipient2);
    }

    function index3Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX3, users.recipient3);
    }

    function index4Proof() public view returns (bytes32[] memory) {
        return indexProof(INDEX4, users.recipient4);
    }

    function indexProof(uint256 index, address recipient) public view returns (bytes32[] memory) {
        return computeMerkleProof(LeafData({ index: index, recipient: recipient, amount: CLAIM_AMOUNT }), LEAVES);
    }

    /// @dev We need a separate function to initialize the Merkle tree because, at the construction time, the users are
    /// not yet set.
    function initMerkleTree() public {
        LeafData[] memory leafData = new LeafData[](RECIPIENT_COUNT);
        leafData[0] = LeafData({ index: INDEX1, recipient: users.recipient1, amount: CLAIM_AMOUNT });
        leafData[1] = LeafData({ index: INDEX2, recipient: users.recipient2, amount: CLAIM_AMOUNT });
        leafData[2] = LeafData({ index: INDEX3, recipient: users.recipient3, amount: CLAIM_AMOUNT });
        leafData[3] = LeafData({ index: INDEX4, recipient: users.recipient4, amount: CLAIM_AMOUNT });
        MerkleBuilder.computeLeaves(LEAVES, leafData);
        MERKLE_ROOT = getRoot(LEAVES.toBytes32());
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CALL EXPECTS - MERKLE LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {ISablierMerkleBase.claim} with data provided.
    function expectCallToClaimWithData(
        address merkleLockup,
        uint256 feeInWei,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        vm.expectCall(
            merkleLockup, feeInWei, abi.encodeCall(ISablierMerkleBase.claim, (index, recipient, amount, merkleProof))
        );
    }

    /// @dev Expects a call to {ISablierMerkleBase.claim} with msgValue as `msg.value`.
    function expectCallToClaimWithMsgValue(address merkleLockup, uint256 msgValue) internal {
        vm.expectCall(
            merkleLockup,
            msgValue,
            abi.encodeCall(ISablierMerkleBase.claim, (INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof()))
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress() internal view returns (address) {
        return computeMerkleInstantAddress(
            merkleInstantConstructorParams({
                campaignCreator: users.campaignCreator,
                expiration: EXPIRATION,
                merkleRoot: MERKLE_ROOT,
                tokenAddress: dai
            }),
            users.campaignCreator
        );
    }

    function computeMerkleInstantAddress(
        MerkleInstant.ConstructorParams memory params,
        address campaignCreator
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));
        bytes32 creationBytecodeHash;

        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleInstant).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryInstant)
        });
    }

    function merkleInstantConstructorParams() public view returns (MerkleInstant.ConstructorParams memory) {
        return merkleInstantConstructorParams(users.campaignCreator, EXPIRATION, MERKLE_ROOT, dai);
    }

    function merkleInstantConstructorParams(uint40 expiration)
        public
        view
        returns (MerkleInstant.ConstructorParams memory)
    {
        return merkleInstantConstructorParams({
            campaignCreator: users.campaignCreator,
            expiration: expiration,
            merkleRoot: MERKLE_ROOT,
            tokenAddress: dai
        });
    }

    function merkleInstantConstructorParams(
        address campaignCreator,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleInstant.ConstructorParams memory)
    {
        return MerkleInstant.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            token: tokenAddress
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLLAddress() internal view returns (address) {
        return computeMerkleLLAddress(
            merkleLLConstructorParams({
                campaignCreator: users.campaignCreator,
                expiration: EXPIRATION,
                lockupAddress: lockup,
                merkleRoot: MERKLE_ROOT,
                startTime: RANGED_STREAM_START_TIME,
                tokenAddress: dai
            }),
            users.campaignCreator
        );
    }

    function computeMerkleLLAddress(
        MerkleLL.ConstructorParams memory params,
        address campaignCreator
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLL).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryLL)
        });
    }

    function merkleLLConstructorParams() public view returns (MerkleLL.ConstructorParams memory) {
        return merkleLLConstructorParams(EXPIRATION);
    }

    function merkleLLConstructorParams(uint40 expiration) public view returns (MerkleLL.ConstructorParams memory) {
        return merkleLLConstructorParams({
            campaignCreator: users.campaignCreator,
            expiration: expiration,
            lockupAddress: lockup,
            merkleRoot: MERKLE_ROOT,
            startTime: RANGED_STREAM_START_TIME,
            tokenAddress: dai
        });
    }

    function merkleLLConstructorParams(
        address campaignCreator,
        uint40 expiration,
        ISablierLockup lockupAddress,
        bytes32 merkleRoot,
        uint40 startTime,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleLL.ConstructorParams memory)
    {
        return MerkleLL.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            lockup: lockupAddress,
            merkleRoot: merkleRoot,
            schedule: MerkleLL.Schedule({
                startTime: startTime,
                startPercentage: START_PERCENTAGE,
                cliffDuration: CLIFF_DURATION,
                cliffPercentage: CLIFF_PERCENTAGE,
                totalDuration: TOTAL_DURATION
            }),
            shape: SHAPE,
            token: tokenAddress,
            transferable: TRANSFERABLE
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleLTAddress() internal view returns (address) {
        return computeMerkleLTAddress(
            merkleLTConstructorParams({
                campaignCreator: users.campaignCreator,
                expiration: EXPIRATION,
                lockupAddress: lockup,
                merkleRoot: MERKLE_ROOT,
                startTime: RANGED_STREAM_START_TIME,
                tokenAddress: dai
            }),
            users.campaignCreator
        );
    }

    function computeMerkleLTAddress(
        MerkleLT.ConstructorParams memory params,
        address campaignCreator
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLT).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryLT)
        });
    }

    function getTotalDuration(MerkleLT.TrancheWithPercentage[] memory tranches)
        internal
        pure
        returns (uint40 totalDuration)
    {
        for (uint256 i; i < tranches.length; ++i) {
            totalDuration += tranches[i].duration;
        }
    }

    function merkleLTConstructorParams() public view returns (MerkleLT.ConstructorParams memory) {
        return merkleLTConstructorParams(EXPIRATION);
    }

    function merkleLTConstructorParams(uint40 expiration) public view returns (MerkleLT.ConstructorParams memory) {
        return merkleLTConstructorParams({
            campaignCreator: users.campaignCreator,
            expiration: expiration,
            lockupAddress: lockup,
            merkleRoot: MERKLE_ROOT,
            startTime: RANGED_STREAM_START_TIME,
            tokenAddress: dai
        });
    }

    function merkleLTConstructorParams(
        address campaignCreator,
        uint40 expiration,
        ISablierLockup lockupAddress,
        bytes32 merkleRoot,
        uint40 startTime,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleLT.ConstructorParams memory)
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages_ = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages_[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.2e18), duration: 2 days });
        tranchesWithPercentages_[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.8e18), duration: 8 days });

        return MerkleLT.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            lockup: lockupAddress,
            merkleRoot: merkleRoot,
            shape: SHAPE,
            streamStartTime: startTime,
            token: tokenAddress,
            tranchesWithPercentages: tranchesWithPercentages_,
            transferable: TRANSFERABLE
        });
    }

    /// @dev Mirrors the logic from {SablierMerkleLT._calculateStartTimeAndTranches}.
    function tranchesMerkleLT(
        uint40 streamStartTime,
        uint128 totalAmount
    )
        public
        view
        returns (LockupTranched.Tranche[] memory tranches_)
    {
        tranches_ = new LockupTranched.Tranche[](2);
        if (streamStartTime == 0) {
            tranches_[0].timestamp = uint40(block.timestamp) + CLIFF_DURATION;
            tranches_[1].timestamp = uint40(block.timestamp) + TOTAL_DURATION;
        } else {
            tranches_[0].timestamp = streamStartTime + CLIFF_DURATION;
            tranches_[1].timestamp = streamStartTime + TOTAL_DURATION;
        }

        uint128 amount0 = ud(totalAmount).mul(ud(0.2e18)).intoUint128();
        uint128 amount1 = ud(totalAmount).mul(ud(0.8e18)).intoUint128();

        tranches_[0].amount = amount0;
        tranches_[1].amount = amount1;

        uint128 amountsSum = amount0 + amount1;

        if (amountsSum != totalAmount) {
            tranches_[1].amount += totalAmount - amountsSum;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-VCA
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleVCAAddress() internal view returns (address) {
        return computeMerkleVCAAddress(
            merkleVCAConstructorParams({
                campaignCreator: users.campaignCreator,
                expiration: EXPIRATION,
                merkleRoot: MERKLE_ROOT,
                timestamps: merkleVCATimestamps(),
                tokenAddress: dai
            }),
            users.campaignCreator
        );
    }

    function computeMerkleVCAAddress(
        MerkleVCA.ConstructorParams memory params,
        address campaignCreator
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleVCA).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleVCA.sol/SablierMerkleVCA.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryVCA)
        });
    }

    function merkleVCAConstructorParams() public view returns (MerkleVCA.ConstructorParams memory) {
        return merkleVCAConstructorParams(EXPIRATION);
    }

    function merkleVCAConstructorParams(uint40 expiration) public view returns (MerkleVCA.ConstructorParams memory) {
        return merkleVCAConstructorParams({
            campaignCreator: users.campaignCreator,
            expiration: expiration,
            merkleRoot: MERKLE_ROOT,
            timestamps: merkleVCATimestamps(),
            tokenAddress: dai
        });
    }

    function merkleVCAConstructorParams(
        address campaignCreator,
        uint40 expiration,
        bytes32 merkleRoot,
        MerkleVCA.Timestamps memory timestamps,
        IERC20 tokenAddress
    )
        public
        view
        returns (MerkleVCA.ConstructorParams memory)
    {
        return MerkleVCA.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            timestamps: timestamps,
            token: tokenAddress
        });
    }

    function merkleVCATimestamps() public view returns (MerkleVCA.Timestamps memory) {
        return MerkleVCA.Timestamps({ start: RANGED_STREAM_START_TIME, end: RANGED_STREAM_END_TIME });
    }
}
