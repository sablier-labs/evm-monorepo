// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Broker } from "src/types/DataTypes.sol";

import { Integration_Test } from "../Integration.t.sol";

contract DepositViaBroker_Integration_Test is Integration_Test {
    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(
            ISablierV2OpenEnded.depositViaBroker, (defaultStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker)
        );
        // it should revert
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        // it should revert
        expectRevertNull();
        openEnded.depositViaBroker(nullStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker);
    }

    function test_RevertWhen_BrokerFeeGreaterThanMaxFee() external whenNotDelegateCalled givenNotNull {
        defaultBroker.fee = MAX_BROKER_FEE.add(ud(1));
        // it should revert
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_BrokerFeeTooHigh.selector, defaultStreamId, defaultBroker.fee, MAX_BROKER_FEE
            )
        );
        openEnded.depositViaBroker(defaultStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker);
    }

    function test_RevertWhen_BrokeAddressIsZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
    {
        defaultBroker.account = address(0);
        // it should revert
        vm.expectRevert(Errors.SablierV2OpenEnded_BrokerAddressZero.selector);
        openEnded.depositViaBroker(defaultStreamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, defaultBroker);
    }

    function test_RevertWhen_TotalAmountIsZero()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
        whenBrokerAddressIsNotZero
    {
        // it should revert
        vm.expectRevert(Errors.SablierV2OpenEnded_DepositAmountZero.selector);
        openEnded.depositViaBroker(defaultStreamId, 0, defaultBroker);
    }

    function test_WhenAssetMissesERC20Return()
        external
        whenNotDelegateCalled
        givenNotNull
        whenBrokerFeeNotGreaterThanMaxFee
        whenBrokerAddressIsNotZero
        whenTotalAmountIsNotZero
    {
        // it should make the deposit
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
        // it should update the stream balance
        // it should perform the ERC20 transfer
        // it should emit 2 {Transfer}, 1 {DepositOpenEndedStream}, 1 {MetadataUpdate} events
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
        // it should update the stream balance
        // it should perform the ERC20 transfer
        // it should emit 2 {Transfer}, 1 {DepositOpenEndedStream}, 1 {MetadataUpdate} events
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(dai)));
        _test_DepositViaBroker(streamId, IERC20(address(dai)), defaultBroker);
    }

    function _test_DepositViaBroker(uint256 streamId, IERC20 asset, Broker memory broker) private {
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: users.sender,
            to: address(openEnded),
            value: normalizeAmountWithStreamId(streamId, DEPOSIT_AMOUNT)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit DepositOpenEndedStream({
            streamId: streamId,
            funder: users.sender,
            asset: asset,
            depositAmount: DEPOSIT_AMOUNT
        });

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: users.sender,
            to: users.broker,
            value: normalizeAmountWithStreamId(streamId, BROKER_FEE_AMOUNT)
        });

        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: streamId });

        expectCallToTransferFrom({
            asset: asset,
            from: users.sender,
            to: address(openEnded),
            amount: normalizeAmountWithStreamId(streamId, DEPOSIT_AMOUNT)
        });

        expectCallToTransferFrom({
            asset: asset,
            from: users.sender,
            to: users.broker,
            amount: normalizeAmountWithStreamId(streamId, BROKER_FEE_AMOUNT)
        });

        openEnded.depositViaBroker(streamId, DEPOSIT_AMOUNT_WITH_BROKER_FEE, broker);

        uint128 actualStreamBalance = openEnded.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
