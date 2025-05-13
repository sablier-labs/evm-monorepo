// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "@sablier/lockup/src/LockupNFTDescriptor.sol";
import { SablierLockup } from "@sablier/lockup/src/SablierLockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierFactoryMerkleInstant } from "src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { SablierFactoryMerkleInstant } from "src/SablierFactoryMerkleInstant.sol";
import { SablierFactoryMerkleLL } from "src/SablierFactoryMerkleLL.sol";
import { SablierFactoryMerkleLT } from "src/SablierFactoryMerkleLT.sol";
import { SablierFactoryMerkleVCA } from "src/SablierFactoryMerkleVCA.sol";
import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";
import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";
import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "src/types/DataTypes.sol";
import { Assertions } from "./utils/Assertions.sol";
import { ChainlinkOracleMock } from "./utils/ChainlinkMocks.sol";
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
    /// @dev A test contract meant to be overridden by the implementing Merkle contracts.
    ISablierMerkleBase internal merkleBase;
    /// @dev A test contract meant to be overridden by the implementing FactoryMerkle contracts.
    ISablierFactoryMerkleBase internal factoryMerkleBase;
    ISablierFactoryMerkleInstant internal factoryMerkleInstant;
    ISablierFactoryMerkleLL internal factoryMerkleLL;
    ISablierFactoryMerkleLT internal factoryMerkleLT;
    ISablierFactoryMerkleVCA internal factoryMerkleVCA;
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
        address nftDescriptor = address(new LockupNFTDescriptor());
        lockup = new SablierLockup(users.admin, nftDescriptor);

        // Deploy the mock Chainlink Oracle.
        oracle = new ChainlinkOracleMock();

        // Deploy the factories.
        deployFactoriesConditionally();

        // Create users for testing.
        createTestUsers();

        // Initialize the Merkle tree.
        initMerkleTree();

        // Set the variables in Modifiers contract.
        setVariables(users);

        // Set sender as the default caller for the tests.
        setMsgSender(users.sender);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create users for testing and assign roles if applicable.
    function createTestUsers() internal {
        address[] memory spenders = new address[](4);
        spenders[0] = address(factoryMerkleInstant);
        spenders[1] = address(factoryMerkleLL);
        spenders[2] = address(factoryMerkleLT);
        spenders[3] = address(factoryMerkleVCA);

        // Create test users.
        users.accountant = createUser("Accountant", spenders);
        users.campaignCreator = createUser("CampaignCreator", spenders);
        users.eve = createUser("Eve", spenders);
        users.recipient = createUser("Recipient", spenders);
        users.recipient1 = createUser("Recipient1", spenders);
        users.recipient2 = createUser("Recipient2", spenders);
        users.recipient3 = createUser("Recipient3", spenders);
        users.recipient4 = createUser("Recipient4", spenders);
        users.sender = createUser("Sender", spenders);

        // Assign fee collector and fee management roles to the accountant user.
        setMsgSender(users.admin);
        for (uint256 i; i < spenders.length; ++i) {
            grantAllRoles({ account: users.accountant, target: spenders[i] });
        }
    }

    /// @dev Deploys the factories conditionally based on the test profile.
    function deployFactoriesConditionally() internal {
        if (!isTestOptimizedProfile()) {
            factoryMerkleInstant = new SablierFactoryMerkleInstant(users.admin, MIN_FEE_USD, address(oracle));
            factoryMerkleLL = new SablierFactoryMerkleLL(users.admin, MIN_FEE_USD, address(oracle));
            factoryMerkleLT = new SablierFactoryMerkleLT(users.admin, MIN_FEE_USD, address(oracle));
            factoryMerkleVCA = new SablierFactoryMerkleVCA(users.admin, MIN_FEE_USD, address(oracle));
        } else {
            (factoryMerkleInstant, factoryMerkleLL, factoryMerkleLT, factoryMerkleVCA) =
                deployOptimizedFactories(users.admin, MIN_FEE_USD, address(oracle));
        }
        vm.label({ account: address(factoryMerkleInstant), newLabel: "FactoryMerkleInstant" });
        vm.label({ account: address(factoryMerkleLL), newLabel: "FactoryMerkleLL" });
        vm.label({ account: address(factoryMerkleLT), newLabel: "FactoryMerkleLT" });
        vm.label({ account: address(factoryMerkleVCA), newLabel: "FactoryMerkleVCA" });
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

    /// @dev Expects a call to {claimTo} with data provided.
    function expectCallToClaimToWithData(
        address merkleLockup,
        uint256 feeInWei,
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        vm.expectCall(
            merkleLockup, feeInWei, abi.encodeCall(ISablierMerkleInstant.claimTo, (index, to, amount, merkleProof))
        );
    }

    /// @dev Expects a call to {claimTo} with msgValue as `msg.value`.
    function expectCallToClaimToWithMsgValue(address merkleLockup, uint256 msgValue) internal {
        vm.expectCall(
            merkleLockup,
            msgValue,
            abi.encodeCall(ISablierMerkleInstant.claimTo, (INDEX1, users.eve, CLAIM_AMOUNT, index1Proof()))
        );
    }

    /// @dev Expects a call to {claim} with data provided.
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
            merkleLockup, feeInWei, abi.encodeCall(ISablierMerkleInstant.claim, (index, recipient, amount, merkleProof))
        );
    }

    /// @dev Expects a call to {claim} with msgValue as `msg.value`.
    function expectCallToClaimWithMsgValue(address merkleLockup, uint256 msgValue) internal {
        vm.expectCall(
            merkleLockup,
            msgValue,
            abi.encodeCall(ISablierMerkleInstant.claim, (INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof()))
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
            deployer: address(factoryMerkleInstant)
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
                startTime: VESTING_START_TIME,
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
            deployer: address(factoryMerkleLL)
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
            startTime: VESTING_START_TIME,
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
            cancelable: STREAM_CANCELABLE,
            cliffDuration: VESTING_CLIFF_DURATION,
            cliffUnlockPercentage: VESTING_CLIFF_UNLOCK_PERCENTAGE,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            lockup: lockupAddress,
            merkleRoot: merkleRoot,
            startUnlockPercentage: VESTING_START_UNLOCK_PERCENTAGE,
            startTime: startTime,
            shape: STREAM_SHAPE,
            token: tokenAddress,
            totalDuration: VESTING_TOTAL_DURATION,
            transferable: STREAM_TRANSFERABLE
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
                startTime: VESTING_START_TIME,
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
            deployer: address(factoryMerkleLT)
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
            startTime: VESTING_START_TIME,
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
            cancelable: STREAM_CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            lockup: lockupAddress,
            merkleRoot: merkleRoot,
            shape: STREAM_SHAPE,
            startTime: startTime,
            token: tokenAddress,
            tranchesWithPercentages: tranchesWithPercentages_,
            transferable: STREAM_TRANSFERABLE
        });
    }

    /// @dev Mirrors the logic from {SablierMerkleLT._calculateStartTimeAndTranches}.
    function tranchesMerkleLT(
        uint40 vestingStartTime,
        uint128 totalAmount
    )
        public
        view
        returns (LockupTranched.Tranche[] memory tranches_)
    {
        tranches_ = new LockupTranched.Tranche[](2);
        if (vestingStartTime == 0) {
            tranches_[0].timestamp = getBlockTimestamp() + VESTING_CLIFF_DURATION;
            tranches_[1].timestamp = getBlockTimestamp() + VESTING_TOTAL_DURATION;
        } else {
            tranches_[0].timestamp = vestingStartTime + VESTING_CLIFF_DURATION;
            tranches_[1].timestamp = vestingStartTime + VESTING_TOTAL_DURATION;
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

    /// @dev Mirrors the logic from {SablierMerkleVCA._calculateClaimAmount}.
    function calculateMerkleVCAAmounts(
        uint128 fullAmount,
        UD60x18 unlockPercentage,
        uint40 endTime,
        uint40 startTime
    )
        public
        view
        returns (uint128 claimAmount, uint128 forgoneAmount)
    {
        uint40 blockTime = getBlockTimestamp();
        if (blockTime < startTime) {
            return (0, 0);
        }

        uint128 unlockAmount = uint128(uint256(fullAmount) * unlockPercentage.unwrap() / 1e18);

        if (blockTime == startTime) {
            return (unlockAmount, fullAmount - unlockAmount);
        }

        if (blockTime < endTime) {
            uint40 elapsedTime = (blockTime - startTime);
            uint40 totalDuration = endTime - startTime;

            uint256 remainderAmount = uint256(fullAmount - unlockAmount);
            claimAmount = unlockAmount + uint128((remainderAmount * elapsedTime) / totalDuration);
            forgoneAmount = fullAmount - claimAmount;
        } else {
            claimAmount = fullAmount;
            forgoneAmount = 0;
        }
    }

    function computeMerkleVCAAddress() internal view returns (address) {
        return computeMerkleVCAAddress(
            merkleVCAConstructorParams({
                campaignCreator: users.campaignCreator,
                endTime: VESTING_END_TIME,
                expiration: EXPIRATION,
                merkleRoot: MERKLE_ROOT,
                startTime: VCA_START_TIME,
                tokenAddress: dai,
                unlockPercentage: VCA_UNLOCK_PERCENTAGE
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
            deployer: address(factoryMerkleVCA)
        });
    }

    function merkleVCAConstructorParams() public view returns (MerkleVCA.ConstructorParams memory) {
        return merkleVCAConstructorParams(EXPIRATION);
    }

    function merkleVCAConstructorParams(uint40 expiration) public view returns (MerkleVCA.ConstructorParams memory) {
        return merkleVCAConstructorParams({
            campaignCreator: users.campaignCreator,
            endTime: VESTING_END_TIME,
            expiration: expiration,
            merkleRoot: MERKLE_ROOT,
            startTime: VCA_START_TIME,
            tokenAddress: dai,
            unlockPercentage: VCA_UNLOCK_PERCENTAGE
        });
    }

    function merkleVCAConstructorParams(
        address campaignCreator,
        uint40 endTime,
        uint40 expiration,
        bytes32 merkleRoot,
        uint40 startTime,
        IERC20 tokenAddress,
        UD60x18 unlockPercentage
    )
        public
        view
        returns (MerkleVCA.ConstructorParams memory)
    {
        return MerkleVCA.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            endTime: endTime,
            expiration: expiration,
            initialAdmin: campaignCreator,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            startTime: startTime,
            token: tokenAddress,
            unlockPercentage: unlockPercentage
        });
    }
}
