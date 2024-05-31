// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Flow } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Create_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, dai, IS_TRANFERABLE));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertWhen_SenderZeroAddress() external whenNotDelegateCalled {
        vm.expectRevert(Errors.SablierFlow_SenderZeroAddress.selector);
        flow.create({
            sender: address(0),
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            isTransferable: IS_TRANFERABLE
        });
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNotDelegateCalled whenSenderIsNotZeroAddress {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        flow.create({
            sender: users.sender,
            recipient: address(0),
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            isTransferable: IS_TRANFERABLE
        });
    }

    function test_RevertWhen_RatePerSecondZero()
        external
        whenNotDelegateCalled
        whenSenderIsNotZeroAddress
        whenRecipientIsNotZeroAddress
    {
        vm.expectRevert(Errors.SablierFlow_RatePerSecondZero.selector);
        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: 0,
            asset: dai,
            isTransferable: IS_TRANFERABLE
        });
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNotDelegateCalled
        whenSenderIsNotZeroAddress
        whenRecipientIsNotZeroAddress
        whenRatePerSecondIsNotZero
    {
        address nonContract = address(8128);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_InvalidAssetDecimals.selector, IERC20(nonContract)));
        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: IERC20(nonContract),
            isTransferable: IS_TRANFERABLE
        });
    }

    function test_Create()
        external
        whenNotDelegateCalled
        whenSenderIsNotZeroAddress
        whenRecipientIsNotZeroAddress
        whenRatePerSecondIsNotZero
        whenAssetContract
    {
        uint256 expectedStreamId = flow.nextStreamId();

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(flow) });
        emit CreateFlowStream({
            streamId: expectedStreamId,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            lastTimeUpdate: uint40(block.timestamp)
        });

        uint256 actualStreamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            isTransferable: IS_TRANFERABLE
        });

        Flow.Stream memory actualStream = flow.getStream(actualStreamId);
        Flow.Stream memory expectedStream = Flow.Stream({
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            assetDecimals: 18,
            balance: 0,
            lastTimeUpdate: uint40(block.timestamp),
            isPaused: false,
            isStream: true,
            isTransferable: IS_TRANFERABLE,
            remainingAmount: 0,
            sender: users.sender
        });

        assertEq(actualStreamId, expectedStreamId, "stream id");
        assertEq(actualStream, expectedStream);

        address actualNFTOwner = flow.ownerOf({ tokenId: actualStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
