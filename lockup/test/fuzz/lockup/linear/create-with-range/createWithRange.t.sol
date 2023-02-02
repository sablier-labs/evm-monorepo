// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

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
        startTime = boundUint40(startTime, defaultParams.createWithRange.range.cliff + 1, MAX_UNIX_TIMESTAMP);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_StartTimeGreaterThanCliffTime.selector,
                startTime,
                defaultParams.createWithRange.range.cliff
            )
        );
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            LockupLinear.Range({
                start: startTime,
                cliff: defaultParams.createWithRange.range.cliff,
                end: defaultParams.createWithRange.range.end
            }),
            defaultParams.createWithRange.broker
        );
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
        vm.assume(endTime > defaultParams.createWithRange.range.start);

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
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(
        UD60x18 protocolFee
    ) external recipientNonZeroAddress depositAmountNotZero startTimeNotGreaterThanCliffTime cliffTimeLessThanEndTime {
        protocolFee = bound(protocolFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);

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
    function testFuzz_RevertWhen_BrokerFeeTooHigh(
        UD60x18 brokerFee
    )
        external
        recipientNonZeroAddress
        depositAmountNotZero
        startTimeNotGreaterThanCliffTime
        cliffTimeLessThanEndTime
        protocolFeeNotTooHigh
    {
        brokerFee = bound(brokerFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
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

    modifier assetContract() {
        _;
    }

    modifier assetERC20Compliant() {
        _;
    }

    struct Params {
        Broker broker;
        bool cancelable;
        address funder;
        UD60x18 protocolFee;
        LockupLinear.Range range;
        address recipient;
        address sender;
        uint128 totalAmount;
    }

    struct Vars {
        uint256 actualNextStreamId;
        address actualNFTOwner;
        uint256 actualProtocolRevenues;
        uint128 brokerFeeAmount;
        uint128 depositAmount;
        uint256 expectedNextStreamId;
        address expectedNFTOwner;
        uint256 expectedProtocolRevenues;
        uint128 initialProtocolRevenues;
        uint128 protocolFeeAmount;
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
        Params memory params
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
        vm.assume(params.funder != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(params.totalAmount != 0);
        vm.assume(params.range.start <= params.range.cliff && params.range.cliff < params.range.end);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.protocolFee = bound(params.protocolFee, 0, DEFAULT_MAX_FEE);

        // Calculate the fee amounts and the deposit amount.
        Vars memory vars;
        vars.protocolFeeAmount = ud(params.totalAmount).mul(params.protocolFee).intoUint128();
        vars.brokerFeeAmount = ud(params.totalAmount).mul(params.broker.fee).intoUint128();
        vars.depositAmount = params.totalAmount - vars.protocolFeeAmount - vars.brokerFeeAmount;

        // Set the fuzzed protocol fee.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: params.protocolFee });

        // Make the fuzzed funder the caller in this test.
        changePrank(params.funder);

        // Mint enough ERC-20 assets to the funder.
        deal({ token: address(DEFAULT_ASSET), to: params.funder, give: params.totalAmount });

        // Approve the {SablierV2LockupLinear} contract to transfer the ERC-20 assets from the fuzzed funder.
        DEFAULT_ASSET.approve({ spender: address(linear), amount: UINT256_MAX });

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupLinear} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (params.funder, address(linear), vars.depositAmount + vars.protocolFeeAmount)
            )
        );

        // Expect the broker fee to be paid to the broker, if the fee amount is not zero.
        if (vars.brokerFeeAmount > 0) {
            vm.expectCall(
                address(DEFAULT_ASSET),
                abi.encodeCall(IERC20.transferFrom, (params.funder, params.broker.addr, vars.brokerFeeAmount))
            );
        }

        // Expect a {CreateLockupLinearStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.CreateLockupLinearStream({
            streamId: streamId,
            funder: params.funder,
            sender: params.sender,
            recipient: params.recipient,
            amounts: Lockup.CreateAmounts({
                deposit: vars.depositAmount,
                protocolFee: vars.protocolFeeAmount,
                brokerFee: vars.brokerFeeAmount
            }),
            asset: DEFAULT_ASSET,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker.addr
        });

        // Create the stream.
        linear.createWithRange(
            params.sender,
            params.recipient,
            params.totalAmount,
            DEFAULT_ASSET,
            params.cancelable,
            params.range,
            params.broker
        );

        // Assert that the stream has been created.
        LockupLinear.Stream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, Lockup.Amounts({ deposit: vars.depositAmount, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.range, params.range);
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id has been bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee has been recorded.
        vars.actualProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.protocolFeeAmount;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT has been minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
