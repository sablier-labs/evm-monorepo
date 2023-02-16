// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Linear_Fuzz_Test } from "../Linear.t.sol";

contract CreateWithRange_Linear_Fuzz_Test is Linear_Fuzz_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Linear_Fuzz_Test.setUp();

        // Load the stream id.
        streamId = linear.nextStreamId();
    }

    modifier recipientNonZeroAddress() {
        _;
    }

    modifier depositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_StartTimeGreaterThanCliffTime(
        uint40 startTime
    ) external recipientNonZeroAddress depositAmountNotZero {
        startTime = boundUint40(startTime, DEFAULT_CLIFF_TIME + 1, MAX_UNIX_TIMESTAMP);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector,
                startTime,
                DEFAULT_CLIFF_TIME
            )
        );
        createDefaultStreamWithStartTime(startTime);
    }

    modifier startTimeNotGreaterThanCliffTime() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CliffTimeNotLessThanEndTime(
        uint40 cliffTime,
        uint40 endTime
    ) external recipientNonZeroAddress depositAmountNotZero startTimeNotGreaterThanCliffTime {
        vm.assume(cliffTime >= endTime);
        vm.assume(endTime > DEFAULT_START_TIME);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeNotLessThanEndTime.selector,
                cliffTime,
                endTime
            )
        );
        createDefaultStreamWithRange(LockupLinear.Range({ start: DEFAULT_START_TIME, cliff: cliffTime, end: endTime }));
    }

    modifier cliffTimeLessThanEndTime() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(
        UD60x18 protocolFee
    ) external recipientNonZeroAddress depositAmountNotZero startTimeNotGreaterThanCliffTime cliffTimeLessThanEndTime {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

        // Set the protocol fee.
        changePrank({ msgSender: users.admin });
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
    function testFuzz_RevertWhen_BrokerFeeTooHigh(
        Broker memory broker
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
    {
        vm.assume(broker.account != address(0));
        broker.fee = bound(broker.fee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, broker.fee, DEFAULT_MAX_FEE)
        );
        createDefaultStreamWithBroker(broker);
    }

    modifier brokerFeeNotTooHigh() {
        _;
    }

    modifier assetContract() {
        _;
    }

    modifier assetERC20Compliant() {
        _;
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        Lockup.CreateAmounts createAmounts;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        uint128 initialProtocolRevenues;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the protocol
    /// fee, mint the NFT, and emit a {CreateLockupLinearStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker.
    /// - Multiple values for the total amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Multiple values for the cliff time and the stop time.
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    function testFuzz_CreateWithRange(
        address funder,
        LockupLinear.CreateWithRange memory params,
        UD60x18 protocolFee
    )
        external
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
        assetERC20Compliant
    {
        vm.assume(funder != address(0) && params.recipient != address(0) && params.broker.account != address(0));
        vm.assume(params.totalAmount != 0);
        vm.assume(params.range.start <= params.range.cliff && params.range.cliff < params.range.end);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        protocolFee = bound(protocolFee, 0, DEFAULT_MAX_FEE);

        // Calculate the fee amounts and the deposit amount.
        Vars memory vars;
        vars.createAmounts.protocolFee = ud(params.totalAmount).mul(protocolFee).intoUint128();
        vars.createAmounts.brokerFee = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.createAmounts.deposit = params.totalAmount - vars.createAmounts.protocolFee - vars.createAmounts.brokerFee;

        // Set the fuzzed protocol fee.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: protocolFee });

        // Make the fuzzed funder the caller in this test.
        changePrank(funder);

        // Mint enough ERC-20 assets to the funder.
        deal({ token: address(DEFAULT_ASSET), to: funder, give: params.totalAmount });

        // Approve the {SablierV2LockupLinear} contract to transfer the ERC-20 assets from the fuzzed funder.
        DEFAULT_ASSET.approve({ spender: address(linear), amount: UINT256_MAX });

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupLinear} contract.
        expectTransferFromCall({
            from: funder,
            to: address(linear),
            amount: vars.createAmounts.deposit + vars.createAmounts.protocolFee
        });

        // Expect the broker fee to be paid to the broker, if not zero.
        if (vars.createAmounts.brokerFee > 0) {
            expectTransferFromCall({ from: funder, to: params.broker.account, amount: vars.createAmounts.brokerFee });
        }

        // Expect a {CreateLockupLinearStream} event to be emitted.
        expectEmit();
        emit Events.CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: vars.createAmounts,
            asset: DEFAULT_ASSET,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker.account
        });

        // Create the stream.
        linear.createWithRange(
            LockupLinear.CreateWithRange({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                asset: DEFAULT_ASSET,
                cancelable: params.cancelable,
                range: params.range,
                broker: params.broker
            })
        );

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.createAmounts.deposit, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.cliffTime, params.range.cliff);
        assertEq(actualStream.endTime, params.range.end);
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.startTime, params.range.start);
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.createAmounts.protocolFee;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
