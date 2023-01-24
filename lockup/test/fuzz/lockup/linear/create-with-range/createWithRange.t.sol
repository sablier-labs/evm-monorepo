// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";
import { Broker, CreateLockupAmounts, LockupAmounts, LockupLinearStream, Range } from "src/types/Structs.sol";

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

    modifier netDepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_StartTimeGreaterThanCliffTime(
        uint40 startTime
    ) external recipientNonZeroAddress netDepositAmountNotZero {
        startTime = boundUint40(startTime, defaultParams.createWithRange.range.cliff + 1, UINT40_MAX);
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
            defaultParams.createWithRange.grossDepositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            Range({
                start: startTime,
                cliff: defaultParams.createWithRange.range.cliff,
                stop: defaultParams.createWithRange.range.stop
            }),
            defaultParams.createWithRange.broker
        );
    }

    modifier startTimeLessThanOrEqualToCliffTime() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CliffTimeGreaterThanStopTime(
        uint40 cliffTime,
        uint40 stopTime
    ) external recipientNonZeroAddress netDepositAmountNotZero startTimeLessThanOrEqualToCliffTime {
        vm.assume(cliffTime > stopTime);
        vm.assume(stopTime > defaultParams.createWithRange.range.start);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2LockupLinear_CliffTimeGreaterThanStopTime.selector,
                cliffTime,
                stopTime
            )
        );
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.grossDepositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            Range({ start: defaultParams.createWithRange.range.start, cliff: cliffTime, stop: stopTime }),
            defaultParams.createWithRange.broker
        );
    }

    modifier cliffLessThanOrEqualToStopTime() {
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_ProtocolFeeTooHigh(
        UD60x18 protocolFee
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
    {
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
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
    {
        brokerFee = bound(brokerFee, DEFAULT_MAX_FEE.add(ud(1)), MAX_UD60x18);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_BrokerFeeTooHigh.selector, brokerFee, DEFAULT_MAX_FEE)
        );
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.grossDepositAmount,
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
    function testFuzz_RevertWhen_AssetNotContract(
        IERC20 nonContract
    )
        external
        recipientNonZeroAddress
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
    {
        vm.assume(address(nonContract).code.length == 0);
        vm.expectRevert("Address: call to non-contract");
        linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.grossDepositAmount,
            nonContract,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    modifier assetContract() {
        _;
    }

    modifier assetERC20Compliant() {
        _;
    }

    struct Params {
        address funder;
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        bool cancelable;
        Range range;
        Broker broker;
        UD60x18 protocolFee;
    }

    struct Vars {
        uint128 initialProtocolRevenues;
        uint128 protocolFeeAmount;
        uint128 brokerFeeAmount;
        uint128 netDepositAmount;
        uint256 actualNextStreamId;
        uint256 expectedNextStreamId;
        uint256 actualProtocolRevenues;
        uint256 expectedProtocolRevenues;
        address actualNFTOwner;
        address expectedNFTOwner;
    }

    /// @dev it should perform the ERC-20 transfers, create the stream, bump the next stream id, record the protocol
    /// fee, mint the NFT, and emit a {CreateLockupLinearStream} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - All possible permutations for the funder, sender, recipient, and broker.
    /// - Multiple values for the gross deposit amount.
    /// - Cancelable and non-cancelable.
    /// - Start time in the past, present and future.
    /// - Start time lower than and equal to cliff time.
    /// - Cliff time lower than and equal to stop time.
    /// - Multiple values for the broker fee, including zero.
    /// - Multiple values for the protocol fee, including zero.
    function testFuzz_CreateWithRange(
        Params memory params
    )
        external
        netDepositAmountNotZero
        startTimeLessThanOrEqualToCliffTime
        cliffLessThanOrEqualToStopTime
        protocolFeeNotTooHigh
        brokerFeeNotTooHigh
        assetContract
        assetERC20Compliant
    {
        vm.assume(params.funder != address(0) && params.recipient != address(0) && params.broker.addr != address(0));
        vm.assume(params.grossDepositAmount != 0);
        vm.assume(params.range.start <= params.range.cliff && params.range.cliff <= params.range.stop);
        params.broker.fee = bound(params.broker.fee, 0, DEFAULT_MAX_FEE);
        params.protocolFee = bound(params.protocolFee, 0, DEFAULT_MAX_FEE);

        // Set the fuzzed protocol fee.
        changePrank({ who: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: params.protocolFee });

        // Make the fuzzed funder the caller in this test.
        changePrank(params.funder);

        // Mint enough assets to the funder.
        deal({ token: address(DEFAULT_ASSET), to: params.funder, give: params.grossDepositAmount });

        // Approve the {SablierV2LockupLinear} contract to transfer the assets from the fuzzed funder.
        DEFAULT_ASSET.approve({ spender: address(linear), amount: UINT256_MAX });

        // Load the initial protocol revenues.
        Vars memory vars;
        vars.initialProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);

        // Calculate the protocol fee amount, broker fee amount and the net deposit amount.
        vars.protocolFeeAmount = ud(params.grossDepositAmount).mul(params.protocolFee).intoUint128();
        vars.brokerFeeAmount = ud(params.grossDepositAmount).mul(params.broker.fee).intoUint128();
        vars.netDepositAmount = params.grossDepositAmount - vars.protocolFeeAmount - vars.brokerFeeAmount;

        // Expect the ERC-20 assets to be transferred from the funder to the {SablierV2LockupLinear} contract.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(
                IERC20.transferFrom,
                (params.funder, address(linear), vars.netDepositAmount + vars.protocolFeeAmount)
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
            amounts: CreateLockupAmounts({
                netDeposit: vars.netDepositAmount,
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
            params.grossDepositAmount,
            DEFAULT_ASSET,
            params.cancelable,
            params.range,
            params.broker
        );

        // Assert that the stream was created.
        LockupLinearStream memory actualStream = linear.getStream(streamId);
        assertEq(actualStream.amounts, LockupAmounts({ deposit: vars.netDepositAmount, withdrawn: 0 }));
        assertEq(actualStream.asset, defaultStream.asset, "asset");
        assertEq(actualStream.isCancelable, params.cancelable, "isCancelable");
        assertEq(actualStream.range, params.range);
        assertEq(actualStream.sender, params.sender, "sender");
        assertEq(actualStream.status, defaultStream.status);

        // Assert that the next stream id was bumped.
        vars.actualNextStreamId = linear.nextStreamId();
        vars.expectedNextStreamId = streamId + 1;
        assertEq(vars.actualNextStreamId, vars.expectedNextStreamId, "nextStreamId");

        // Assert that the protocol fee was recorded.
        vars.actualProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);
        vars.expectedProtocolRevenues = vars.initialProtocolRevenues + vars.protocolFeeAmount;
        assertEq(vars.actualProtocolRevenues, vars.expectedProtocolRevenues, "protocolRevenues");

        // Assert that the NFT was minted.
        vars.actualNFTOwner = linear.ownerOf({ tokenId: streamId });
        vars.expectedNFTOwner = params.recipient;
        assertEq(vars.actualNFTOwner, vars.expectedNFTOwner, "NFT owner");
    }
}
