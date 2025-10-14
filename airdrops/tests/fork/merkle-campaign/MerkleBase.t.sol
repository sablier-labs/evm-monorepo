// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { LeafData, MerkleBuilder } from "./../../utils/MerkleBuilder.sol";
import { Fork_Test } from "./../Fork.t.sol";

abstract contract MerkleBase_Fork_Test is Fork_Test {
    using MerkleBuilder for uint256[];

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        address campaignCreator;
        uint40 expiration;
        LeafData[] leavesData;
        uint256 leafIndex;
    }

    struct Vars {
        uint256[] leaves;
        LeafData[] leavesData;
        LeafData leafToClaim;
        uint256 initialAdminBalance;
        uint256 aggregateAmount;
        uint128 clawbackAmount;
        address expectedMerkleCampaign;
        bytes32[] merkleProof;
        bytes32 merkleRoot;
        uint256 minFeeUSD;
        uint256 minFeeWei;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Vars internal vars;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE-CAMPAIGN
    //////////////////////////////////////////////////////////////////////////*/

    function preCreateCampaign(Params memory params) internal {
        vm.assume(params.campaignCreator != address(0) && params.campaignCreator != address(factoryMerkleBase));
        vm.assume(params.leavesData.length > 0);
        assumeNoBlacklisted({ token: address(FORK_TOKEN), addr: params.campaignCreator });
        params.leafIndex = _bound(params.leafIndex, 0, params.leavesData.length - 1);

        // The expiration must be either zero or greater than the block timestamp.
        if (params.expiration != 0) {
            params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 1 seconds, MAX_UNIX_TIMESTAMP);
        }

        // Exclude the factory contract from being the recipient. Otherwise, the fee accrued may not be equal to the sum
        // of all `msg.value`.
        address[] memory excludedAddresses = new address[](1);
        excludedAddresses[0] = address(factoryMerkleBase);

        // Fuzz the leaves data.
        vars.aggregateAmount = fuzzMerkleData({ leavesData: params.leavesData, excludedAddresses: excludedAddresses });

        // Store the merkle tree leaves in storage.
        for (uint256 i = 0; i < params.leavesData.length; ++i) {
            vars.leavesData.push(params.leavesData[i]);
        }

        MerkleBuilder.computeLeaves(vars.leaves, params.leavesData);

        // If there is only one leaf, the Merkle root is the hash of the leaf itself.
        vars.merkleRoot = vars.leaves.length == 1 ? bytes32(vars.leaves[0]) : getRoot(vars.leaves.toBytes32());

        // Make the campaign creator as the caller.
        setMsgSender(params.campaignCreator);

        // Load the min fee in USD.
        vars.minFeeUSD = comptroller.getMinFeeUSD({ protocol: ISablierComptroller.Protocol.Airdrops });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CLAIM
    //////////////////////////////////////////////////////////////////////////*/

    function preClaim(Params memory params) internal {
        // Fund the Merkle contract.
        deal({ token: address(FORK_TOKEN), to: address(merkleBase), give: vars.aggregateAmount });

        vars.leafToClaim = params.leavesData[params.leafIndex];

        // Make the recipient as the caller.
        setMsgSender(vars.leafToClaim.recipient);

        assertFalse(merkleBase.hasClaimed(vars.leafToClaim.index));

        vars.merkleProof = computeMerkleProof(vars.leafToClaim, vars.leaves);
        vars.minFeeWei = comptroller.calculateMinFeeWei({ protocol: ISablierComptroller.Protocol.Airdrops });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      CLAWBACK
    //////////////////////////////////////////////////////////////////////////*/

    function testClawback(Params memory params) internal {
        // Make the campaign creator as the caller.
        setMsgSender(params.campaignCreator);

        if (params.expiration > 0) {
            vars.clawbackAmount = uint128(FORK_TOKEN.balanceOf(address(merkleBase)));
            vm.warp({ newTimestamp: params.expiration + 1 seconds });

            expectCallToTransfer({ token: FORK_TOKEN, to: params.campaignCreator, value: vars.clawbackAmount });
            vm.expectEmit({ emitter: address(merkleBase) });
            emit ISablierMerkleBase.Clawback({
                to: params.campaignCreator,
                admin: params.campaignCreator,
                amount: vars.clawbackAmount
            });
            merkleBase.clawback({ to: params.campaignCreator, amount: vars.clawbackAmount });
        }
    }
}
