// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Noop } from "src/mocks/Noop.sol";
import { ChainlinkOracleMock } from "src/mocks/ChainlinkMocks.sol";

import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract Setters_Concrete_Test is SablierComptroller_Concrete_Test {
    /*//////////////////////////////////////////////////////////////////////////
                          DISABLE-AIRDROPS-CUSTOM-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_DisableAirdropsCustomFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Enable the custom fee.
        comptroller.setAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            comptroller.getAirdropsMinFeeUSD(),
            "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableAirdropsCustomFeeUSD();
    }

    function test_DisableAirdropsCustomFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.disableAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator });
    }

    function test_DisableAirdropsCustomFeeUSDWhenNotEnabled() external whenCallerAdmin {
        // Disable the custom fee.
        comptroller.disableAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // Check that custom fee is not enabled.
        assertEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            comptroller.getAirdropsMinFeeUSD(),
            "custom fee USD enabled"
        );

        // Disable the custom fee.
        _disableAirdropsCustomFeeUSD();
    }

    function test_DisableAirdropsCustomFeeUSDWhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        comptroller.setAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            comptroller.getAirdropsMinFeeUSD(),
            "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableAirdropsCustomFeeUSD();
    }

    function _disableAirdropsCustomFeeUSD() private {
        // It should emit a {DisableAirdropsCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.DisableAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // Disable the custom fee.
        comptroller.disableAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // It should return the min USD fee.
        assertEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            comptroller.getAirdropsMinFeeUSD(),
            "custom fee USD"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            DISABLE-FLOW-CUSTOM-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_DisableFlowCustomFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Enable the custom fee.
        comptroller.setFlowCustomFeeUSD({ sender: users.sender, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getFlowMinFeeUSDFor(users.sender), comptroller.getFlowMinFeeUSD(), "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableFlowCustomFeeUSD();
    }

    function test_DisableFlowCustomFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.disableFlowCustomFeeUSD({ sender: users.sender });
    }

    function test_DisableFlowCustomFeeUSDWhenNotEnabled() external whenCallerAdmin {
        // Disable the custom fee.
        comptroller.disableFlowCustomFeeUSD({ sender: users.sender });

        // Check that custom fee is not enabled.
        assertEq(
            comptroller.getFlowMinFeeUSDFor(users.sender), comptroller.getFlowMinFeeUSD(), "custom fee USD enabled"
        );

        // Disable the custom fee.
        _disableFlowCustomFeeUSD();
    }

    function test_DisableFlowCustomFeeUSDWhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        comptroller.setFlowCustomFeeUSD({ sender: users.sender, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getFlowMinFeeUSDFor(users.sender), comptroller.getFlowMinFeeUSD(), "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableFlowCustomFeeUSD();
    }

    function _disableFlowCustomFeeUSD() private {
        // It should emit a {DisableFlowCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.DisableFlowCustomFeeUSD({ sender: users.sender });

        // Disable the custom fee.
        comptroller.disableFlowCustomFeeUSD({ sender: users.sender });

        // It should return the min USD fee.
        assertEq(comptroller.getFlowMinFeeUSDFor(users.sender), comptroller.getFlowMinFeeUSD(), "custom fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                           DISABLE-LOCKUP-CUSTOM-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_DisableLockupCustomFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Enable the custom fee.
        comptroller.setLockupCustomFeeUSD({ sender: users.sender, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getLockupMinFeeUSDFor(users.sender),
            comptroller.getLockupMinFeeUSD(),
            "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableLockupCustomFeeUSD();
    }

    function test_DisableLockupCustomFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.disableLockupCustomFeeUSD({ sender: users.sender });
    }

    function test_DisableLockupCustomFeeUSDWhenNotEnabled() external whenCallerAdmin {
        // Disable the custom fee.
        comptroller.disableLockupCustomFeeUSD({ sender: users.sender });

        // Check that custom fee is not enabled.
        assertEq(
            comptroller.getLockupMinFeeUSDFor(users.sender), comptroller.getLockupMinFeeUSD(), "custom fee USD enabled"
        );

        // Disable the custom fee.
        _disableLockupCustomFeeUSD();
    }

    function test_DisableLockupCustomFeeUSDWhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        comptroller.setLockupCustomFeeUSD({ sender: users.sender, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getLockupMinFeeUSDFor(users.sender),
            comptroller.getLockupMinFeeUSD(),
            "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableLockupCustomFeeUSD();
    }

    function _disableLockupCustomFeeUSD() private {
        // It should emit a {DisableLockupCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.DisableLockupCustomFeeUSD({ sender: users.sender });

        // Disable the custom fee.
        comptroller.disableLockupCustomFeeUSD({ sender: users.sender });

        // It should return the min USD fee.
        assertEq(comptroller.getLockupMinFeeUSDFor(users.sender), comptroller.getLockupMinFeeUSD(), "custom fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SET-AIRDROPS-CUSTOM-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetAirdropsCustomFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the custom fee.
        _setAirdropsCustomFeeUSD();
    }

    function test_SetAirdropsCustomFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0 });
    }

    function test_SetAirdropsCustomFeeUSDRevertWhen_NewFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 customFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, customFeeUSD, MAX_FEE_USD)
        );
        comptroller.setAirdropsCustomFeeUSD(users.campaignCreator, customFeeUSD);
    }

    function test_SetAirdropsCustomFeeUSDWhenNotEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        comptroller.disableAirdropsCustomFeeUSD(users.campaignCreator);

        // Check that custom fee is not enabled for user.
        assertEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            comptroller.getAirdropsMinFeeUSD(),
            "custom fee USD enabled"
        );

        // Set the custom fee.
        _setAirdropsCustomFeeUSD();
    }

    function test_SetAirdropsCustomFeeUSDWhenEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        // Enable the custom fee.
        comptroller.setAirdropsCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            comptroller.getAirdropsMinFeeUSD(),
            "custom fee USD not enabled"
        );

        // Set the custom fee.
        _setAirdropsCustomFeeUSD();
    }

    function _setAirdropsCustomFeeUSD() private {
        // Set the custom fee to a different value.
        uint256 customFeeUSD = 0;

        // It should emit a {SetAirdropsCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetAirdropsCustomFeeUSD(users.campaignCreator, customFeeUSD);

        // Set the custom fee.
        comptroller.setAirdropsCustomFeeUSD(users.campaignCreator, customFeeUSD);

        // It should set the custom fee.
        assertEq(comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator), customFeeUSD, "custom fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SET-AIRDROPS-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetAirdropsMinFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the min fee USD.
        _setAirdropsMinFeeUSD();
    }

    function test_SetAirdropsMinFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setAirdropsMinFeeUSD(0.001e18);
    }

    function test_SetAirdropsMinFeeUSDRevertWhen_NewMinFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, newMinFeeUSD, MAX_FEE_USD)
        );
        comptroller.setAirdropsMinFeeUSD(newMinFeeUSD);
    }

    function test_SetAirdropsMinFeeUSDWhenNewMinFeeNotExceedMaxFee() external whenCallerAdmin {
        // Set the min fee USD.
        _setAirdropsMinFeeUSD();
    }

    function _setAirdropsMinFeeUSD() private {
        uint256 newMinFeeUSD = MAX_FEE_USD;

        // It should emit a {SetMinFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetAirdropsMinFeeUSD({
            newMinFeeUSD: newMinFeeUSD,
            previousMinFeeUSD: AIRDROP_MIN_FEE_USD
        });

        comptroller.setAirdropsMinFeeUSD(newMinFeeUSD);

        // It should set the min USD fee.
        assertEq(comptroller.getAirdropsMinFeeUSD(), newMinFeeUSD, "min fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SET-FLOW-CUSTOM-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetFlowCustomFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the custom fee.
        _setFlowCustomFeeUSD();
    }

    function test_SetFlowCustomFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setFlowCustomFeeUSD(users.sender, 0);
    }

    function test_SetFlowCustomFeeUSDRevertWhen_NewFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 customFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, customFeeUSD, MAX_FEE_USD)
        );
        comptroller.setFlowCustomFeeUSD(users.sender, customFeeUSD);
    }

    function test_SetFlowCustomFeeUSDWhenNotEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        comptroller.disableFlowCustomFeeUSD(users.sender);

        // Check that custom fee is not enabled for user.
        assertEq(
            comptroller.getFlowMinFeeUSDFor(users.sender), comptroller.getFlowMinFeeUSD(), "custom fee USD enabled"
        );

        // Set the custom fee.
        _setFlowCustomFeeUSD();
    }

    function test_SetFlowCustomFeeUSDWhenEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        // Enable the custom fee.
        comptroller.setFlowCustomFeeUSD(users.sender, 0.5e8);

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getFlowMinFeeUSDFor(users.sender), comptroller.getFlowMinFeeUSD(), "custom fee USD not enabled"
        );

        // Set the custom fee.
        _setFlowCustomFeeUSD();
    }

    function _setFlowCustomFeeUSD() private {
        // Set the custom fee to a different value.
        uint256 customFeeUSD = 0;

        // It should emit a {SetFlowCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetFlowCustomFeeUSD(users.sender, customFeeUSD);

        // Set the custom fee.
        comptroller.setFlowCustomFeeUSD(users.sender, customFeeUSD);

        // It should set the custom fee.
        assertEq(comptroller.getFlowMinFeeUSDFor(users.sender), customFeeUSD, "custom fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET-FLOW-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetFlowMinFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the min fee USD.
        _setFlowMinFeeUSD();
    }

    function test_SetFlowMinFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setFlowMinFeeUSD(0.001e18);
    }

    function test_SetFlowMinFeeUSDRevertWhen_NewMinFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, newMinFeeUSD, MAX_FEE_USD)
        );
        comptroller.setFlowMinFeeUSD(newMinFeeUSD);
    }

    function test_SetFlowMinFeeUSDWhenNewMinFeeNotExceedMaxFee() external whenCallerAdmin {
        // Set the min fee USD.
        _setFlowMinFeeUSD();
    }

    function _setFlowMinFeeUSD() private {
        uint256 newMinFeeUSD = MAX_FEE_USD;

        // It should emit a {SetMinFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetFlowMinFeeUSD({ newMinFeeUSD: newMinFeeUSD, previousMinFeeUSD: FLOW_MIN_FEE_USD });

        comptroller.setFlowMinFeeUSD(newMinFeeUSD);

        // It should set the min USD fee.
        assertEq(comptroller.getFlowMinFeeUSD(), newMinFeeUSD, "min fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                             SET-LOCKUP-CUSTOM-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetLockupCustomFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the custom fee.
        _setLockupCustomFeeUSD();
    }

    function test_SetLockupCustomFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setLockupCustomFeeUSD(users.sender, 0);
    }

    function test_SetLockupCustomFeeUSDRevertWhen_NewFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 customFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, customFeeUSD, MAX_FEE_USD)
        );
        comptroller.setLockupCustomFeeUSD(users.sender, customFeeUSD);
    }

    function test_SetLockupCustomFeeUSDWhenNotEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        comptroller.disableLockupCustomFeeUSD(users.sender);

        // Check that custom fee is not enabled for user.
        assertEq(
            comptroller.getLockupMinFeeUSDFor(users.sender), comptroller.getLockupMinFeeUSD(), "custom fee USD enabled"
        );

        // Set the custom fee.
        _setLockupCustomFeeUSD();
    }

    function test_SetLockupCustomFeeUSDWhenEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        // Enable the custom fee.
        comptroller.setLockupCustomFeeUSD(users.sender, 0.5e8);

        // Check that custom fee is enabled.
        assertNotEq(
            comptroller.getLockupMinFeeUSDFor(users.sender),
            comptroller.getLockupMinFeeUSD(),
            "custom fee USD not enabled"
        );

        // Set the custom fee.
        _setLockupCustomFeeUSD();
    }

    function _setLockupCustomFeeUSD() private {
        // Set the custom fee to a different value.
        uint256 customFeeUSD = 0;

        // It should emit a {SetLockupCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetLockupCustomFeeUSD(users.sender, customFeeUSD);

        // Set the custom fee.
        comptroller.setLockupCustomFeeUSD(users.sender, customFeeUSD);

        // It should set the custom fee.
        assertEq(comptroller.getLockupMinFeeUSDFor(users.sender), customFeeUSD, "custom fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SET-LOCKUP-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetLockupMinFeeUSDWhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the min fee USD.
        _setLockupMinFeeUSD();
    }

    function test_SetLockupMinFeeUSDRevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setLockupMinFeeUSD(0.001e18);
    }

    function test_SetLockupMinFeeUSDRevertWhen_NewMinFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, newMinFeeUSD, MAX_FEE_USD)
        );
        comptroller.setLockupMinFeeUSD(newMinFeeUSD);
    }

    function test_SetLockupMinFeeUSDWhenNewMinFeeNotExceedMaxFee() external whenCallerAdmin {
        // Set the min fee USD.
        _setLockupMinFeeUSD();
    }

    function _setLockupMinFeeUSD() private {
        uint256 newMinFeeUSD = MAX_FEE_USD;

        // It should emit a {SetMinFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetLockupMinFeeUSD({ newMinFeeUSD: newMinFeeUSD, previousMinFeeUSD: LOCKUP_MIN_FEE_USD });

        comptroller.setLockupMinFeeUSD(newMinFeeUSD);

        // It should set the min USD fee.
        assertEq(comptroller.getLockupMinFeeUSD(), newMinFeeUSD, "min fee USD");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     SET-ORACLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_SetOracleRevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        comptroller.setOracle(address(0));
    }

    function test_SetOracleWhenNewOracleZero() external whenCallerAdmin {
        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetOracle(admin, address(0), address(oracle));
        comptroller.setOracle(address(0));

        // It should set the oracle to zero.
        assertEq(comptroller.oracle(), address(0), "oracle after");
    }

    function test_SetOracleRevertWhen_NewOracleWithoutImplementation() external whenCallerAdmin whenNewOracleNotZero {
        Noop noop = new Noop();

        // It should revert.
        vm.expectRevert();
        comptroller.setOracle(address(noop));
    }

    function test_SetOracleWhenNewOracleWithImplementation() external whenCallerAdmin whenNewOracleNotZero {
        ChainlinkOracleMock newOracleWithImpl = new ChainlinkOracleMock();

        // It should emit a {SetOracle} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetOracle(admin, address(newOracleWithImpl), address(oracle));
        comptroller.setOracle(address(newOracleWithImpl));

        // It should set the oracle.
        assertEq(comptroller.oracle(), address(newOracleWithImpl), "oracle after");
    }
}
