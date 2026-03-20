// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierFactoryMerkleExecute } from "src/interfaces/ISablierFactoryMerkleExecute.sol";
import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { MerkleExecute } from "src/types/MerkleExecute.sol";

import { MockStaking } from "./../../mocks/MockStaking.sol";
import { Fork_Test } from "./../Fork.t.sol";
import { MerkleBase_Fork_Test } from "./MerkleBase.t.sol";

abstract contract MerkleExecute_Fork_Test is MerkleBase_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    MockStaking internal forkMockStaking;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 tokenAddress) MerkleBase_Fork_Test(tokenAddress) { }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fork_Test.setUp();

        // Deploy the mock staking contract for the forked token.
        forkMockStaking = new MockStaking(FORK_TOKEN);

        // Cast the {FactoryMerkleExecute} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleExecute;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST-FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function testForkFuzz_MerkleExecute(Params memory params) external {
        /*//////////////////////////////////////////////////////////////////////////
                                          CREATE
        //////////////////////////////////////////////////////////////////////////*/

        preCreateCampaign(params);

        MerkleExecute.ConstructorParams memory constructorParams = MerkleExecute.ConstructorParams({
            campaignName: CAMPAIGN_NAME,
            campaignStartTime: CAMPAIGN_START_TIME,
            expiration: params.expiration,
            initialAdmin: params.campaignCreator,
            ipfsCID: IPFS_CID,
            merkleRoot: vars.merkleRoot,
            selector: forkMockStaking.stake.selector,
            target: address(forkMockStaking),
            token: FORK_TOKEN
        });

        vars.expectedMerkleCampaign =
            factoryMerkleExecute.computeMerkleExecute(params.campaignCreator, constructorParams);

        vm.expectEmit({ emitter: address(factoryMerkleExecute) });
        emit ISablierFactoryMerkleExecute.CreateMerkleExecute({
            merkleExecute: ISablierMerkleExecute(vars.expectedMerkleCampaign),
            campaignParams: constructorParams,
            aggregateAmount: vars.aggregateAmount,
            recipientCount: vars.leavesData.length,
            comptroller: address(comptroller),
            minFeeUSD: vars.minFeeUSD
        });

        merkleExecute =
            factoryMerkleExecute.createMerkleExecute(constructorParams, vars.aggregateAmount, vars.leavesData.length);

        assertLt(0, address(merkleExecute).code.length, "MerkleExecute contract not created");
        assertEq(
            address(merkleExecute),
            vars.expectedMerkleCampaign,
            "MerkleExecute contract does not match computed address"
        );

        // Cast the {MerkleExecute} contract as {ISablierMerkleBase}
        merkleBase = merkleExecute;

        /*//////////////////////////////////////////////////////////////////////////
                                          CLAIM
        //////////////////////////////////////////////////////////////////////////*/

        preClaim(params);

        // Expect the {ClaimExecute} event.
        vm.expectEmit({ emitter: address(merkleExecute) });
        emit ISablierMerkleExecute.ClaimExecute({
            index: vars.leafToClaim.index,
            recipient: vars.leafToClaim.recipient,
            amount: vars.leafToClaim.amount,
            target: address(forkMockStaking)
        });

        // Expect the token transfer from to the target (forkMockStaking).
        expectCallToTransferFrom({
            token: FORK_TOKEN,
            from: address(merkleExecute),
            to: address(forkMockStaking),
            value: vars.leafToClaim.amount
        });

        // Claim and execute with the amount as arguments.
        merkleExecute.claimAndExecute{ value: vars.minFeeWei }({
            index: vars.leafToClaim.index,
            amount: vars.leafToClaim.amount,
            merkleProof: vars.merkleProof,
            selectorArguments: abi.encode(vars.leafToClaim.amount)
        });

        assertTrue(merkleExecute.hasClaimed(vars.leafToClaim.index));

        /*//////////////////////////////////////////////////////////////////////////
                                        CLAWBACK
        //////////////////////////////////////////////////////////////////////////*/

        testClawback(params);
    }
}
