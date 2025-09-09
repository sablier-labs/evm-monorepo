// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UnsafeUpgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";

import { Errors } from "src/libraries/Errors.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

import { Base_Test } from "tests/Base.t.sol";

contract Initialize_Comptroller_Concrete_Test is Base_Test {
    SablierComptroller internal uninitializedProxy;

    function setUp() public override {
        Base_Test.setUp();

        // Deploy the comptroller proxy without initializing it.
        uninitializedProxy =
            SablierComptroller(payable(UnsafeUpgrades.deployUUPSProxy(getComptrollerImplAddress(), "")));
    }

    function test_RevertWhen_CalledOnImplementation() external {
        SablierComptroller implementation = SablierComptroller(getComptrollerImplAddress());

        // It should revert.
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(admin, AIRDROP_MIN_FEE_USD, FLOW_MIN_FEE_USD, LOCKUP_MIN_FEE_USD, address(oracle));
    }

    function test_RevertGiven_Initialized() external whenCalledOnProxy {
        SablierComptroller initializedProxy = SablierComptroller(payable(address(comptroller)));

        // It should revert.
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        initializedProxy.initialize(admin, AIRDROP_MIN_FEE_USD, FLOW_MIN_FEE_USD, LOCKUP_MIN_FEE_USD, address(oracle));
    }

    function test_RevertWhen_InitialAirdropFeeExceedsMaxFee() external whenCalledOnProxy givenNotInitialized {
        uint256 initialAirdropMinFeeUSD = MAX_FEE_USD + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MaxFeeUSDExceeded.selector, initialAirdropMinFeeUSD, MAX_FEE_USD
            )
        );
        uninitializedProxy.initialize(
            admin, initialAirdropMinFeeUSD, FLOW_MIN_FEE_USD, LOCKUP_MIN_FEE_USD, address(oracle)
        );
    }

    function test_RevertWhen_InitialFlowFeeExceedsMaxFee()
        external
        whenCalledOnProxy
        givenNotInitialized
        whenInitialAirdropFeeNotExceedMaxFee
    {
        uint256 initialFlowMinFeeUSD = MAX_FEE_USD + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MaxFeeUSDExceeded.selector, initialFlowMinFeeUSD, MAX_FEE_USD
            )
        );
        uninitializedProxy.initialize(
            admin, AIRDROP_MIN_FEE_USD, initialFlowMinFeeUSD, LOCKUP_MIN_FEE_USD, address(oracle)
        );
    }

    function test_RevertWhen_InitialLockupFeeExceedsMaxFee()
        external
        whenCalledOnProxy
        givenNotInitialized
        whenInitialAirdropFeeNotExceedMaxFee
        whenInitialFlowFeeNotExceedMaxFee
    {
        uint256 initialLockupMinFeeUSD = MAX_FEE_USD + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierComptroller_MaxFeeUSDExceeded.selector, initialLockupMinFeeUSD, MAX_FEE_USD
            )
        );
        uninitializedProxy.initialize(
            admin, AIRDROP_MIN_FEE_USD, FLOW_MIN_FEE_USD, initialLockupMinFeeUSD, address(oracle)
        );
    }

    function test_WhenInitialLockupFeeNotExceedMaxFee()
        external
        whenCalledOnProxy
        givenNotInitialized
        whenInitialAirdropFeeNotExceedMaxFee
        whenInitialFlowFeeNotExceedMaxFee
    {
        uninitializedProxy.initialize(admin, AIRDROP_MIN_FEE_USD, FLOW_MIN_FEE_USD, LOCKUP_MIN_FEE_USD, address(oracle));

        // It should initialize the proxy states.
        assertEq(uninitializedProxy.admin(), admin, "admin");
        assertEq(uninitializedProxy.MAX_FEE_USD(), MAX_FEE_USD, "max fee USD");
        assertEq(uninitializedProxy.oracle(), address(oracle), "oracle");
        assertEq(
            uninitializedProxy.getMinFeeUSD(ISablierComptroller.Protocol.Airdrops),
            AIRDROP_MIN_FEE_USD,
            "get min fee USD Airdrops"
        );
        assertEq(
            uninitializedProxy.getMinFeeUSD(ISablierComptroller.Protocol.Flow), FLOW_MIN_FEE_USD, "get min fee USD Flow"
        );
        assertEq(
            uninitializedProxy.getMinFeeUSD(ISablierComptroller.Protocol.Lockup),
            LOCKUP_MIN_FEE_USD,
            "get min fee USD Lockup"
        );
    }
}
