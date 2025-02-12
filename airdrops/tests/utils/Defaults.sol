// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";
import { ud2x18, UD2x18, uUNIT } from "@prb/math/src/UD2x18.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";
import { Merkle } from "murky/src/Merkle.sol";

import { MerkleInstant, MerkleLL, MerkleLT } from "../../src/types/DataTypes.sol";

import { Constants } from "./Constants.sol";
import { MerkleBuilder } from "./MerkleBuilder.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants, Merkle {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    uint128 public constant CLIFF_AMOUNT = 2500e18;
    uint40 public constant CLIFF_DURATION = 2500 seconds;
    uint40 public immutable START_TIME;
    uint128 public constant START_AMOUNT = 100e18;
    uint40 public constant TOTAL_DURATION = 10_000 seconds;

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant AGGREGATE_AMOUNT = CLAIM_AMOUNT * RECIPIENT_COUNT;
    string public CAMPAIGN_NAME = "Airdrop Campaign";
    bool public constant CANCELABLE = false;
    uint128 public constant CLAIM_AMOUNT = 10_000e18;
    UD2x18 public constant CLIFF_PERCENTAGE = UD2x18.wrap(0.25e18); // 25% of the claim amount
    uint40 public immutable EXPIRATION;
    uint256 public constant FEE = 0.005e18;
    uint40 public constant FIRST_CLAIM_TIME = JULY_1_2024;
    uint256 public constant INDEX1 = 1;
    uint256 public constant INDEX2 = 2;
    uint256 public constant INDEX3 = 3;
    uint256 public constant INDEX4 = 4;
    string public constant IPFS_CID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    uint256[] public LEAVES = new uint256[](RECIPIENT_COUNT);
    uint256 public constant RECIPIENT_COUNT = 4;
    bytes32 public MERKLE_ROOT;
    string public SHAPE = "A custom stream shape";
    UD2x18 public constant START_PERCENTAGE = UD2x18.wrap(0.01e18); // 1% of the claim amount
    uint40 public immutable STREAM_START_TIME_NON_ZERO = JULY_1_2024 - 2 days;
    uint40 public immutable STREAM_START_TIME_ZERO = 0;
    uint64 public constant TOTAL_PERCENTAGE = uUNIT;
    bool public constant TRANSFERABLE = false;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 private token;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        START_TIME = JULY_1_2024 + 2 days;
        EXPIRATION = JULY_1_2024 + 12 weeks;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

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
        uint256 leaf = MerkleBuilder.computeLeaf(index, recipient, CLAIM_AMOUNT);
        uint256 pos = Arrays.findUpperBound(LEAVES, leaf);
        return getProof(LEAVES.toBytes32(), pos);
    }

    /// @dev We need a separate function to initialize the Merkle tree because, at the construction time, the users are
    /// not yet set.
    function initMerkleTree() public {
        LEAVES[0] = MerkleBuilder.computeLeaf(INDEX1, users.recipient1, CLAIM_AMOUNT);
        LEAVES[1] = MerkleBuilder.computeLeaf(INDEX2, users.recipient2, CLAIM_AMOUNT);
        LEAVES[2] = MerkleBuilder.computeLeaf(INDEX3, users.recipient3, CLAIM_AMOUNT);
        LEAVES[3] = MerkleBuilder.computeLeaf(INDEX4, users.recipient4, CLAIM_AMOUNT);
        MerkleBuilder.sortLeaves(LEAVES);
        MERKLE_ROOT = getRoot(LEAVES.toBytes32());
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MERKLE-INSTANT
    //////////////////////////////////////////////////////////////////////////*/

    function merkleInstantConstructorParams(
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 token_
    )
        public
        view
        returns (MerkleInstant.ConstructorParams memory)
    {
        return MerkleInstant.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            merkleRoot: merkleRoot,
            token: token_
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LL
    //////////////////////////////////////////////////////////////////////////*/

    function merkleLLConstructorParams(
        address campaignOwner,
        uint40 expiration,
        ISablierLockup lockup,
        bytes32 merkleRoot,
        IERC20 token_
    )
        public
        view
        returns (MerkleLL.ConstructorParams memory)
    {
        return MerkleLL.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            lockup: lockup,
            merkleRoot: merkleRoot,
            schedule: MerkleLL.Schedule({
                startTime: STREAM_START_TIME_ZERO,
                startPercentage: START_PERCENTAGE,
                cliffDuration: CLIFF_DURATION,
                cliffPercentage: CLIFF_PERCENTAGE,
                totalDuration: TOTAL_DURATION
            }),
            shape: SHAPE,
            token: token_,
            transferable: TRANSFERABLE
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MERKLE-LT
    //////////////////////////////////////////////////////////////////////////*/

    function merkleLTConstructorParams(
        address campaignOwner,
        uint40 expiration,
        ISablierLockup lockup,
        bytes32 merkleRoot,
        IERC20 token_
    )
        public
        view
        returns (MerkleLT.ConstructorParams memory)
    {
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages_ = new MerkleLT.TrancheWithPercentage[](2);
        tranchesWithPercentages_[0] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.25e18), duration: 2500 seconds });
        tranchesWithPercentages_[1] =
            MerkleLT.TrancheWithPercentage({ unlockPercentage: ud2x18(0.75e18), duration: 7500 seconds });

        return MerkleLT.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            cancelable: CANCELABLE,
            expiration: expiration,
            initialAdmin: campaignOwner,
            ipfsCID: IPFS_CID,
            lockup: lockup,
            merkleRoot: merkleRoot,
            shape: SHAPE,
            streamStartTime: STREAM_START_TIME_ZERO,
            token: token_,
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

        uint128 amount0 = ud(totalAmount).mul(ud(0.25e18)).intoUint128();
        uint128 amount1 = ud(totalAmount).mul(ud(0.75e18)).intoUint128();

        tranches_[0].amount = amount0;
        tranches_[1].amount = amount1;

        uint128 amountsSum = amount0 + amount1;

        if (amountsSum != totalAmount) {
            tranches_[1].amount += totalAmount - amountsSum;
        }
    }
}
