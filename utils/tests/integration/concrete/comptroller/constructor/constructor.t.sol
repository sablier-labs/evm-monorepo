// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

import { Base_Test } from "tests/Base.t.sol";

contract Constructor_Comptroller_Concrete_Test is Base_Test {
    function test_RevertWhen_InitialAirdropFeeExceedsMaxFee() external {
        uint256 initialAirdropMinFeeUSD = MAX_FEE_USD + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MaxFeeUSDExceeded.selector, initialAirdropMinFeeUSD, MAX_FEE_USD
            )
        );
        new SablierComptroller(admin, initialAirdropMinFeeUSD, FLOW_MIN_FEE_USD, LOCKUP_MIN_FEE_USD, address(oracle));
    }

    function test_RevertWhen_InitialFlowFeeExceedsMaxFee() external whenInitialAirdropFeeNotExceedMaxFee {
        uint256 initialFlowMinFeeUSD = MAX_FEE_USD + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MaxFeeUSDExceeded.selector, initialFlowMinFeeUSD, MAX_FEE_USD
            )
        );
        new SablierComptroller(admin, AIRDROP_MIN_FEE_USD, initialFlowMinFeeUSD, LOCKUP_MIN_FEE_USD, address(oracle));
    }

    function test_RevertWhen_InitialLockupFeeExceedsMaxFee()
        external
        whenInitialAirdropFeeNotExceedMaxFee
        whenInitialFlowFeeNotExceedMaxFee
    {
        uint256 initialLockupMinFeeUSD = MAX_FEE_USD + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MaxFeeUSDExceeded.selector, initialLockupMinFeeUSD, MAX_FEE_USD
            )
        );
        new SablierComptroller(admin, AIRDROP_MIN_FEE_USD, FLOW_MIN_FEE_USD, initialLockupMinFeeUSD, address(oracle));
    }

    function test_WhenInitialLockupFeeNotExceedMaxFee()
        public
        view
        whenInitialAirdropFeeNotExceedMaxFee
        whenInitialFlowFeeNotExceedMaxFee
    {
        // Constants and variables.
        assertEq(comptroller.admin(), admin, "admin");
        assertEq(comptroller.MAX_FEE_USD(), MAX_FEE_USD, "max fee USD");
        bytes4 expectedMinimalInterfaceId = ISablierComptroller.calculateMinFeeWeiFor.selector
            ^ ISablierComptroller.convertUSDFeeToWei.selector ^ ISablierComptroller.execute.selector
            ^ ISablierComptroller.getMinFeeUSDFor.selector;
        assertEq(comptroller.MINIMAL_INTERFACE_ID(), expectedMinimalInterfaceId, "minimal interface ID");
        assertEq(comptroller.oracle(), address(oracle), "oracle");

        // GetMinFeeUSD
        assertEq(
            comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Airdrops),
            AIRDROP_MIN_FEE_USD,
            "get min fee USD Airdrops"
        );
        assertEq(comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Flow), FLOW_MIN_FEE_USD, "get min fee USD Flow");
        assertEq(
            comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Lockup), LOCKUP_MIN_FEE_USD, "get min fee USD Lockup"
        );

        // GetMinFeeUSDFor
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.campaignCreator),
            AIRDROP_MIN_FEE_USD,
            "get min fee USD Airdrops for user"
        );
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Flow, users.campaignCreator),
            FLOW_MIN_FEE_USD,
            "get min fee USD Flow for user"
        );
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Lockup, users.campaignCreator),
            LOCKUP_MIN_FEE_USD,
            "get min fee USD Lockup for user"
        );
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Staking, users.campaignCreator),
            STAKING_MIN_FEE_USD,
            "get min fee USD Staking for user"
        );
    }
}
