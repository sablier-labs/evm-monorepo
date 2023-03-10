// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract SetProtocolFee_Unit_Test is Comptroller_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Adminable_CallerNotAdmin.selector, users.admin, users.eve)
        );
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: DEFAULT_MAX_FEE });
    }

    /// @dev The admin is the default caller in the comptroller tests.
    modifier callerAdmin() {
        _;
    }

    /// @dev it should re-set the protocol fee.
    function test_SetProtocolFee_SameFee() external callerAdmin {
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = ZERO;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }

    modifier newFee() {
        _;
    }

    /// @dev it should set the new protocol fee and emit a {SetProtocolFee} event.
    function test_SetProtocolFee() external callerAdmin newFee {
        UD60x18 newProtocolFee = DEFAULT_FLASH_FEE;

        // Expect a {SetProtocolFee} event to be emitted.
        vm.expectEmit();
        emit SetProtocolFee({
            admin: users.admin,
            asset: DEFAULT_ASSET,
            oldProtocolFee: ZERO,
            newProtocolFee: newProtocolFee
        });

        // Set the new protocol fee.
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: newProtocolFee });

        // Assert that the protocol fee has been updated.
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }
}
