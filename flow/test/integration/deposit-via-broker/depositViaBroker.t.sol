// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract DepositViaBroker_Integration_Test is Integration_Test {
    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(
            ISablierFlow.depositViaBroker, (defaultStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker)
        );
        // It should revert
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        // It should revert
        expectRevertNull();
        flow.depositViaBroker(nullStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker);
    }

    function test_RevertWhen_BrokerFeeGreaterThanMaxFee() external whenNotDelegateCalled givenNotNull {
        defaultBroker.fee = MAX_BROKER_FEE.add(ud(1));
        // It should revert
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_BrokerFeeTooHigh.selector, defaultStreamId, defaultBroker.fee, MAX_BROKER_FEE
            )
        );
        flow.depositViaBroker(defaultStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker);
    }

    function test_RevertWhen_BrokeAddressIsZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
    {
        defaultBroker.account = address(0);
        // It should revert
        vm.expectRevert(Errors.SablierFlow_BrokerAddressZero.selector);
        flow.depositViaBroker(defaultStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker);
    }

    function test_RevertWhen_TotalAmountIsZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
        whenBrokerAddressIsNotZero
    {
        // It should revert
        vm.expectRevert(Errors.SablierFlow_DepositAmountZero.selector);
        flow.depositViaBroker(defaultStreamId, 0, defaultBroker);
    }

    function test_WhenAssetMissesERC20Return()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
        whenBrokerAddressIsNotZero
        whenTotalAmountIsNotZero
    {
        // It should make the deposit
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        _test_DepositViaBroker(streamId, IERC20(address(usdt)), defaultBroker);
    }

    function test_GivenAssetDoesNotHave18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
        whenBrokerAddressIsNotZero
        whenTotalAmountIsNotZero
        whenAssetDoesNotMissERC20Return
    {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdc)));
        _test_DepositViaBroker(streamId, IERC20(address(usdc)), defaultBroker);
    }

    function test_GivenAssetHas18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
        whenBrokerAddressIsNotZero
        whenTotalAmountIsNotZero
        whenAssetDoesNotMissERC20Return
    {
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(dai)));
        _test_DepositViaBroker(streamId, IERC20(address(dai)), defaultBroker);
    }

    function _test_DepositViaBroker(uint256 streamId, IERC20 asset, Broker memory broker) private {
        // It should emit 2 {Transfer}, 1 {DepositFlowStream}, 1 {MetadataUpdate} events
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: users.sender,
            to: address(flow),
            value: normalizeAmountWithStreamId(streamId, DEPOSIT_AMOUNT)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: users.sender, asset: asset, depositAmount: DEPOSIT_AMOUNT });

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: users.sender,
            to: users.broker,
            value: normalizeAmountWithStreamId(streamId, BROKER_FEE_AMOUNT)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC20 transfers
        expectCallToTransferFrom({
            asset: asset,
            from: users.sender,
            to: address(flow),
            amount: normalizeAmountWithStreamId(streamId, DEPOSIT_AMOUNT)
        });

        expectCallToTransferFrom({
            asset: asset,
            from: users.sender,
            to: users.broker,
            amount: normalizeAmountWithStreamId(streamId, BROKER_FEE_AMOUNT)
        });

        flow.depositViaBroker(streamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, broker);

        // It should update the stream balance
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
