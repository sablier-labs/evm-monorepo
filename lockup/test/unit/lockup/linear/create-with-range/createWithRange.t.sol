// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract CreateWithRange_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Load the stream id.
        streamId = linear.nextStreamId();
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2LockupLinear.createWithRange, defaultParams.createWithRange);
        (bool success, bytes memory returnData) = address(linear).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_RecipientZeroAddress() external whenNoDelegateCall {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    ///
    /// It is not possible to obtain a zero deposit amount from a non-zero total amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function test_RevertWhen_DepositAmountZero() external whenNoDelegateCall whenRecipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        createDefaultStreamWithTotalAmount(0);
    }

    modifier whenDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StartTimeGreaterThanCliffTime()
        external
        whenNoDelegateCall
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
    {
        uint40 startTime = DEFAULT_CLIFF_TIME;
        uint40 cliffTime = DEFAULT_START_TIME;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        createDefaultStreamWithRange(LockupLinear.Range({ start: startTime, cliff: cliffTime, end: DEFAULT_END_TIME }));
    }

    modifier whenStartTimeNotGreaterThanCliffTime() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CliffTimeNotLessThanEndTime()
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
    {
        uint40 cliffTime = DEFAULT_END_TIME;
        uint40 endTime = DEFAULT_CLIFF_TIME;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector,
                cliffTime,
                endTime
            )
        );
        createDefaultStreamWithRange(LockupLinear.Range({ start: DEFAULT_START_TIME, cliff: cliffTime, end: endTime }));
    }

    modifier whenCliffTimeLessThanEndTime() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
    {
        UD60x18 protocolFee = DEFAULT_MAX_FEE.add(ud(1));

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: protocolFee });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, DEFAULT_MAX_FEE)
        );
        createDefaultStream();
    }

    modifier whenProtocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_BrokerFeeTooHigh()
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenProtocolFeeNotTooHigh
    {
        UD60x18 brokerFee = DEFAULT_MAX_FEE.add(ud(1));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        createDefaultStreamWithBroker(Broker({ account: users.broker, fee: brokerFee }));
    }

    modifier whenBrokerFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotContract()
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
    {
        address nonContract = address(8128);
        vm.expectRevert("Address: call to non-contract");
        createDefaultStreamWithAsset(IERC20(nonContract));
    }

    modifier whenAssetContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function test_CreateWithRange_AssetMissingReturnValue()
        external
        whenRecipientNonZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
    {
        test_createWithRange(address(nonCompliantAsset));
    }

    modifier whenAssetERC20Compliant() {
        _;
    }

    /// @dev it should:
    ///
    /// - Perform the ERC-20 transfers.
    /// - Create the stream.
    /// - Bump the next stream id.
    /// - Record the protocol fee.
    /// - Mint the NFT.
    /// - Emit a {CreateLockupLinearStream} event.
    function test_CreateWithRange()
        external
        whenDepositAmountNotZero
        whenStartTimeNotGreaterThanCliffTime
        whenCliffTimeLessThanEndTime
        whenProtocolFeeNotTooHigh
        whenBrokerFeeNotTooHigh
        whenAssetContract
        whenAssetERC20Compliant
    {
        test_createWithRange(address(DEFAULT_ASSET));
    }

    /// @dev Shared test logic for `test_CreateWithRange_AssetMissingReturnValue` and `test_CreateWithRange`.
    function test_createWithRange(address asset) internal {
        // Make the sender the funder of the stream.
        address funder = users.sender;

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupLinear} contract.
        expectTransferFromCall({
            asset: IERC20(asset),
            from: funder,
            to: address(linear),
            amount: DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT
        });

        // Expect the broker fee to be paid to the broker.
        expectTransferFromCall({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            amount: DEFAULT_BROKER_FEE_AMOUNT
        });

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vm.expectEmit();
        emit CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: DEFAULT_LOCKUP_CREATE_AMOUNTS,
            asset: IERC20(asset),
            cancelable: true,
            range: DEFAULT_LINEAR_RANGE,
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithAsset(IERC20(asset));

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(address(actualStream.asset), asset, "asset");
        assertEq(actualStream.cliffTime, defaultStream.cliffTime, "cliffTime");
        assertEq(actualStream.endTime, defaultStream.endTime, "endTime");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.startTime, defaultStream.startTime, "startTime");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        uint256 actualNextStreamId = linear.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = defaultParams.createWithRange.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
