// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract CreateMultiple_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();
    }

    function test_RevertWhen_RecipientsCountNotEqual() external whenNotDelegateCalled whenArrayCountsNotEqual {
        address[] memory recipients = new address[](1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_CreateMultipleArrayCountsNotEqual.selector,
                recipients.length,
                defaultSenders.length,
                defaultRatesPerSecond.length
            )
        );
        openEnded.createMultiple(recipients, defaultSenders, defaultRatesPerSecond, dai);
    }

    function test_RevertWhen_SendersCountNotEqual() external whenNotDelegateCalled whenArrayCountsNotEqual {
        address[] memory senders = new address[](1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_CreateMultipleArrayCountsNotEqual.selector,
                defaultRecipients.length,
                senders.length,
                defaultRatesPerSecond.length
            )
        );
        openEnded.createMultiple(defaultRecipients, senders, defaultRatesPerSecond, dai);
    }

    function test_RevertWhen_RatePerSecondCountNotEqual() external whenNotDelegateCalled whenArrayCountsNotEqual {
        uint128[] memory ratesPerSecond = new uint128[](1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_CreateMultipleArrayCountsNotEqual.selector,
                defaultRecipients.length,
                defaultSenders.length,
                ratesPerSecond.length
            )
        );
        openEnded.createMultiple(defaultRecipients, defaultSenders, ratesPerSecond, dai);
    }

    function test_CreateMultiple() external whenNotDelegateCalled whenArrayCountsEqual {
        uint256 beforeNextStreamId = openEnded.nextStreamId();

        vm.expectEmit({ emitter: address(openEnded) });
        emit CreateOpenEndedStream({
            streamId: beforeNextStreamId,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            lastTimeUpdate: uint40(block.timestamp)
        });
        vm.expectEmit({ emitter: address(openEnded) });
        emit CreateOpenEndedStream({
            streamId: beforeNextStreamId + 1,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            lastTimeUpdate: uint40(block.timestamp)
        });

        uint256[] memory streamIds =
            openEnded.createMultiple(defaultRecipients, defaultSenders, defaultRatesPerSecond, dai);

        uint256 afterNextStreamId = openEnded.nextStreamId();

        assertEq(streamIds[0], beforeNextStreamId, "streamIds[0] != beforeNextStreamId");
        assertEq(streamIds[1], beforeNextStreamId + 1, "streamIds[1] != beforeNextStreamId + 1");

        assertEq(streamIds.length, defaultRecipients.length, "streamIds.length != defaultRecipients.length");
        assertEq(
            beforeNextStreamId + defaultRecipients.length,
            afterNextStreamId,
            "afterNextStreamId != beforeNextStreamId + defaultRecipients.length"
        );

        OpenEnded.Stream memory expectedStream = OpenEnded.Stream({
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            assetDecimals: 18,
            balance: 0,
            lastTimeUpdate: uint40(block.timestamp),
            isCanceled: false,
            isStream: true,
            recipient: users.recipient,
            sender: users.sender
        });

        OpenEnded.Stream memory actualStream = openEnded.getStream(streamIds[0]);
        assertEq(actualStream, expectedStream);

        actualStream = openEnded.getStream(streamIds[1]);
        assertEq(actualStream, expectedStream);
    }
}
