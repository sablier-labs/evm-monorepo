// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract CreateAndDepositViaBroker_Integration_Test is Integration_Test {
    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(
            ISablierV2OpenEnded.createAndDepositViaBroker,
            (
                users.sender,
                users.recipient,
                RATE_PER_SECOND,
                dai,
                IS_TRANFERABLE,
                DEPOSIT_AMOUNT_WITH_BROKER_FEE,
                defaultBroker
            )
        );
        // it should revert
        expectRevertDueToDelegateCall(callData);
    }

    function test_WhenNotDelegateCalled() external {
        uint256 expectedStreamId = openEnded.nextStreamId();

        // it should create the stream
        // it should bump the next stream id
        // it should mint the NFT
        // it should update the stream balance
        // it should perform the ERC20 transfers
        // it should emit events: 1 {MetadataUpdate}, 1 {CreateOpenEndedStream}, 2 {Transfer}, 1
        // {DepositOpenEndedStream}

        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(openEnded) });
        emit CreateOpenEndedStream({
            streamId: expectedStreamId,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            lastTimeUpdate: uint40(block.timestamp)
        });

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: users.sender,
            to: address(openEnded),
            value: normalizeAmountToDecimal(DEPOSIT_AMOUNT, 18)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit DepositOpenEndedStream({
            streamId: expectedStreamId,
            funder: users.sender,
            asset: dai,
            depositAmount: DEPOSIT_AMOUNT
        });

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: users.sender,
            to: users.broker,
            value: normalizeAmountToDecimal(BROKER_FEE_AMOUNT, 18)
        });

        expectCallToTransferFrom({
            asset: dai,
            from: users.sender,
            to: address(openEnded),
            amount: normalizeAmountToDecimal(DEPOSIT_AMOUNT, 18)
        });

        expectCallToTransferFrom({
            asset: dai,
            from: users.sender,
            to: users.broker,
            amount: normalizeAmountToDecimal(BROKER_FEE_AMOUNT, 18)
        });

        uint256 actualStreamId = openEnded.createAndDepositViaBroker({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            isTransferable: IS_TRANFERABLE,
            totalAmount: DEPOSIT_AMOUNT_WITH_BROKER_FEE,
            broker: defaultBroker
        });

        OpenEnded.Stream memory actualStream = openEnded.getStream(actualStreamId);
        OpenEnded.Stream memory expectedStream = OpenEnded.Stream({
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            assetDecimals: 18,
            balance: DEPOSIT_AMOUNT,
            lastTimeUpdate: uint40(block.timestamp),
            isPaused: false,
            isStream: true,
            isTransferable: IS_TRANFERABLE,
            remainingAmount: 0,
            sender: users.sender
        });

        assertEq(actualStreamId, expectedStreamId, "stream id");
        assertEq(actualStream, expectedStream);

        address actualNFTOwner = openEnded.ownerOf({ tokenId: actualStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");

        uint128 actualStreamBalance = openEnded.getBalance(expectedStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
