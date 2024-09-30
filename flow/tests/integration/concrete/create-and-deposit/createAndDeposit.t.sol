// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CreateAndDeposit_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(
            flow.createAndDeposit,
            (users.sender, users.recipient, RATE_PER_SECOND, usdc, TRANSFERABLE, DEPOSIT_AMOUNT_6D)
        );
        expectRevert_DelegateCall(callData);
    }

    function test_WhenNoDelegateCall() external {
        uint256 expectedStreamId = flow.nextStreamId();

        // It should emit events: 1 {MetadataUpdate}, 1 {CreateFlowStream}, 1 {Transfer}, 1
        // {DepositFlowStream}
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.CreateFlowStream({
            streamId: expectedStreamId,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE
        });

        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: expectedStreamId,
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });

        // It should perform the ERC-20 transfers
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), amount: DEPOSIT_AMOUNT_6D });

        uint256 actualStreamId = flow.createAndDeposit({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE,
            amount: DEPOSIT_AMOUNT_6D
        });

        Flow.Stream memory actualStream = flow.getStream(actualStreamId);
        Flow.Stream memory expectedStream = defaultStreamWithDeposit();

        // It should create the stream
        assertEq(actualStream, expectedStream);

        // It should bump the next stream id
        assertEq(flow.nextStreamId(), expectedStreamId + 1, "next stream id");

        // It should mint the NFT
        address actualNFTOwner = flow.ownerOf({ tokenId: actualStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");

        // It should update the stream balance
        uint128 actualStreamBalance = flow.getBalance(expectedStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT_6D;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
