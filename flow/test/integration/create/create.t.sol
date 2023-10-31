// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Create_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2OpenEnded.create, (users.sender, users.recipient, AMOUNT_PER_SECOND, dai));
        (bool success, bytes memory returnData) = address(openEnded).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    function test_RevertWhen_SenderZeroAddress() external whenNotDelegateCalled {
        vm.expectRevert(Errors.SablierV2OpenEnded_SenderZeroAddress.selector);
        openEnded.create({
            sender: address(0),
            recipient: users.recipient,
            amountPerSecond: AMOUNT_PER_SECOND,
            asset: dai
        });
    }

    modifier whenSenderNonZeroAddress() {
        _;
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNotDelegateCalled whenSenderNonZeroAddress {
        vm.expectRevert(Errors.SablierV2OpenEnded_RecipientZeroAddress.selector);
        openEnded.create({ sender: users.sender, recipient: address(0), amountPerSecond: AMOUNT_PER_SECOND, asset: dai });
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    function test_RevertWhen_AmountPerSecondZero()
        external
        whenNotDelegateCalled
        whenSenderNonZeroAddress
        whenRecipientNonZeroAddress
    {
        vm.expectRevert(Errors.SablierV2OpenEnded_AmountPerSecondZero.selector);
        openEnded.create({ sender: users.sender, recipient: users.recipient, amountPerSecond: 0, asset: dai });
    }

    modifier whenAmountPerSecondNonZero() {
        _;
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNotDelegateCalled
        whenSenderNonZeroAddress
        whenRecipientNonZeroAddress
        whenAmountPerSecondNonZero
    {
        address nonContract = address(8128);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_InvalidAssetDecimals.selector, IERC20(nonContract))
        );
        openEnded.create({
            sender: users.sender,
            recipient: users.recipient,
            amountPerSecond: AMOUNT_PER_SECOND,
            asset: IERC20(nonContract)
        });
    }

    modifier whenAssetContract() {
        _;
    }

    function test_Create()
        external
        whenNotDelegateCalled
        whenSenderNonZeroAddress
        whenRecipientNonZeroAddress
        whenAmountPerSecondNonZero
        whenAssetContract
    {
        uint256 expectedStreamId = openEnded.nextStreamId();

        vm.expectEmit({ emitter: address(openEnded) });
        emit CreateOpenEndedStream({
            streamId: expectedStreamId,
            sender: users.sender,
            recipient: users.recipient,
            amountPerSecond: AMOUNT_PER_SECOND,
            asset: dai,
            lastTimeUpdate: uint40(block.timestamp)
        });

        uint256 actualStreamId = openEnded.create({
            sender: users.sender,
            recipient: users.recipient,
            amountPerSecond: AMOUNT_PER_SECOND,
            asset: dai
        });

        OpenEnded.Stream memory actualStream = openEnded.getStream(actualStreamId);
        OpenEnded.Stream memory expectedStream = OpenEnded.Stream({
            amountPerSecond: AMOUNT_PER_SECOND,
            asset: dai,
            assetDecimals: 18,
            balance: 0,
            lastTimeUpdate: uint40(block.timestamp),
            isCanceled: false,
            isStream: true,
            recipient: users.recipient,
            sender: users.sender
        });

        assertEq(actualStreamId, expectedStreamId);
        assertEq(actualStream, expectedStream);
    }
}
