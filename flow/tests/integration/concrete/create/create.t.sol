// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { ERC20Mock } from "@sablier/evm-utils/src/mocks/erc20/ERC20Mock.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Flow } from "src/types/DataTypes.sol";
import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract Create_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    uint40 internal startTime;

    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();
        startTime = getBlockTimestamp() - 100 seconds;
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, ZERO, dai, TRANSFERABLE));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertWhen_SenderAddressZero() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierFlow_SenderZeroAddress.selector);
        flow.create({
            sender: address(0),
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            startTime: ZERO,
            token: dai,
            transferable: TRANSFERABLE
        });
    }

    function test_RevertWhen_StartTimeInTheFuture()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondZero
    {
        vm.expectRevert(Errors.SablierFlow_CreateRatePerSecondZero.selector);
        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: ud21x18(0),
            startTime: getBlockTimestamp() + 1 days,
            token: dai,
            transferable: TRANSFERABLE
        });
    }

    function test_WhenStartTimeNotInTheFuture()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondZero
    {
        uint256 streamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: ud21x18(0),
            startTime: ZERO,
            token: dai,
            transferable: TRANSFERABLE
        });

        assertTrue(flow.isStream(streamId));
        assertEq(uint8(flow.statusOf(streamId)), uint8(Flow.Status.PAUSED_SOLVENT));
    }

    function test_RevertWhen_TokenNativeToken()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
    {
        setMsgSender(address(comptroller));
        flow.setNativeToken(address(usdc));
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_CreateNativeToken.selector, address(usdc)));
        createDefaultStream();
    }

    function test_RevertWhen_TokenNotImplementDecimals()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
        whenTokenNotNativeToken
    {
        address invalidToken = address(8128);
        vm.expectRevert(bytes(""));
        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            startTime: startTime,
            token: IERC20(invalidToken),
            transferable: TRANSFERABLE
        });
    }

    function test_RevertWhen_TokenDecimalsExceeds18()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
        whenTokenNotNativeToken
        whenTokenImplementsDecimals
    {
        IERC20 tokenWith24Decimals = new ERC20Mock("Token With More Decimals", "TWMD", 24);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_InvalidTokenDecimals.selector, address(tokenWith24Decimals))
        );

        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            startTime: startTime,
            token: tokenWith24Decimals,
            transferable: TRANSFERABLE
        });
    }

    function test_RevertWhen_RecipientAddressZero()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
        whenTokenNotNativeToken
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
    {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        flow.create({
            sender: users.sender,
            recipient: address(0),
            ratePerSecond: RATE_PER_SECOND,
            startTime: startTime,
            token: dai,
            transferable: TRANSFERABLE
        });
    }

    function test_WhenStartTimeZero()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
        whenTokenNotNativeToken
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
        whenRecipientNotAddressZero
    {
        startTime = 0;
        _test_Create();
    }

    function test_WhenStartTimeNotInThePast()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
        whenTokenNotNativeToken
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
        whenRecipientNotAddressZero
        whenStartTimeNotZero
    {
        startTime = getBlockTimestamp();
        _test_Create();
    }

    function test_WhenStartTimeInThePast()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenRatePerSecondNotZero
        whenTokenNotNativeToken
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
        whenRecipientNotAddressZero
        whenStartTimeNotZero
    {
        _test_Create();
    }

    function _test_Create() private {
        uint256 expectedStreamId = flow.nextStreamId();
        uint40 expectedSnapshotTime = startTime == 0 ? getBlockTimestamp() : startTime;

        // It should emit 1 {MetadataUpdate}, 1 {CreateFlowStream} and 1 {Transfer} events.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC721.Transfer({ from: address(0), to: users.recipient, tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });

        // vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.CreateFlowStream({
            streamId: expectedStreamId,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE,
            snapshotTime: expectedSnapshotTime
        });

        // Create the stream.
        uint256 actualStreamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            startTime: startTime,
            token: usdc,
            transferable: TRANSFERABLE
        });

        Flow.Stream memory actualStream = flow.getStream(actualStreamId);
        Flow.Stream memory expectedStream = defaultStream();
        expectedStream.snapshotTime = expectedSnapshotTime;

        // It should bump the next stream id.
        assertEq(actualStream, expectedStream);
        assertEq(actualStreamId, expectedStreamId, "stream id");
        assertEq(flow.nextStreamId(), expectedStreamId + 1, "next stream id");

        // It should mint the NFT.
        address actualNFTOwner = flow.ownerOf({ tokenId: actualStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");

        uint8 actualStatus = uint8(flow.statusOf(actualStreamId));
        uint256 actualTotalDebt = flow.totalDebtOf(actualStreamId);
        uint8 expectedStatus;
        uint256 expectedTotalDebt;

        // It should create the `STREAMING` stream.
        if (startTime > 0 && startTime < getBlockTimestamp()) {
            expectedTotalDebt = getDescaledAmount(RATE_PER_SECOND_U128 * 100 seconds, DECIMALS);
            expectedStatus = uint8(Flow.Status.STREAMING_INSOLVENT);
        } else {
            expectedTotalDebt = 0;
            expectedStatus = uint8(Flow.Status.STREAMING_SOLVENT);
        }

        assertEq(actualStatus, expectedStatus, "status");
        assertEq(actualTotalDebt, expectedTotalDebt, "total debt");
    }
}
