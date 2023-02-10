// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

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
    function test_RevertWhen_RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
        createDefaultStreamWithRecipient({ recipient: address(0) });
    }

    modifier recipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    ///
    /// It is not possible to obtain a zero deposit amount from a non-zero total amount, because the
    /// `MAX_FEE` is hard coded to 10%.
    function test_RevertWhen_DepositAmountZero() external recipientNonZeroAddress {
        vm.expectRevert(Errors.SablierV2Lockup_DepositAmountZero.selector);
        createDefaultStreamWithTotalAmount(0);
    }

    modifier depositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StartTimeGreaterThanCliffTime() external recipientNonZeroAddress depositAmountNotZero {
        uint40 startTime = defaultParams.createWithRange.range.cliff;
        uint40 cliffTime = defaultParams.createWithRange.range.start;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector,
                startTime,
                cliffTime
            )
        );
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            LockupLinear.Range({ start: startTime, cliff: cliffTime, end: defaultParams.createWithRange.range.end }),
            defaultParams.createWithRange.broker
        );
    }

    modifier startTimeNotGreaterThanCliffTime() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CliffTimeNotLessThanEndTime()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
    {
        uint40 cliffTime = defaultParams.createWithRange.range.end;
        uint40 endTime = defaultParams.createWithRange.range.cliff;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector,
                cliffTime,
                endTime
            )
        );
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            LockupLinear.Range({ start: defaultParams.createWithRange.range.start, cliff: cliffTime, end: endTime }),
            defaultParams.createWithRange.broker
        );
    }

    modifier cliffTimeLessThanEndTime() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolFeeTooHigh()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
    {
        UD60x18 protocolFee = DEFAULT_MAX_FEE.add(ud(1));

        // Set the protocol fee.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: protocolFee });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_ProtocolFeeTooHigh.selector, protocolFee, DEFAULT_MAX_FEE)
        );
        createDefaultStream();
    }

    modifier protocolFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_BrokerFeeTooHigh()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
    {
        UD60x18 brokerFee = DEFAULT_MAX_FEE.add(ud(1));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            Broker({ addr: users.broker, fee: brokerFee })
        );
    }

    modifier brokerFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotContract()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
    {
        address nonContract = address(8128);
        vm.expectRevert("Address: call to non-contract");
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            IERC20(nonContract),
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    modifier assetContract() {
        _;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, and mint the NFT.
    function test_CreateWithRange_AssetMissingReturnValue()
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
    {
        test_createWithRange(address(nonCompliantAsset));
    }

    modifier assetERC20Compliant() {
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
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
        assetERC20Compliant
    {
        test_createWithRange(address(DEFAULT_ASSET));
    }

    /// @dev Shared test logic for `test_CreateWithRange_AssetMissingReturnValue` and `test_CreateWithRange`.
    function test_createWithRange(address asset) internal {
        // Make the sender the funder of the stream.
        address funder = users.sender;

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupLinear} contract.
        vm.expectCall(
            asset,
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, address(linear), DEFAULT_DEPOSIT_AMOUNT + DEFAULT_PROTOCOL_FEE_AMOUNT)
            )
        );

        // Expect the broker fee to be paid to the broker.
        vm.expectCall(
            asset,
            abi.encodeCall(
                IERC20.transferFrom,
                (funder, defaultParams.createWithRange.broker.addr, DEFAULT_BROKER_FEE_AMOUNT)
            )
        );

        // Create the stream.
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            IERC20(asset),
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, defaultStream.amounts);
        assertEq(address(actualStream.asset), asset, "asset");
        assertEq(actualStream.isCancelable, defaultStream.isCancelable, "isCancelable");
        assertEq(actualStream.sender, defaultStream.sender, "sender");
        assertEq(actualStream.range, defaultStream.range);
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
