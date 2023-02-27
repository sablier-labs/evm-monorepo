// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract ClaimProtocolRevenues_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Adminable_CallerNotAdmin.selector, users.admin, users.eve)
        );
        config.claimProtocolRevenues(DEFAULT_ASSET);
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.admin });
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolRevenuesZero() external callerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_NoProtocolRevenues.selector, DEFAULT_ASSET));
        config.claimProtocolRevenues(DEFAULT_ASSET);
    }

    modifier protocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank({ msgSender: users.sender });
        createDefaultStream();
        changePrank({ msgSender: users.admin });
        _;
    }

    /// @dev it should claim the protocol revenues, update the protocol revenues, and emit a {ClaimProtocolRevenues}
    /// event.
    function test_ClaimProtocolRevenues() external callerAdmin protocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        expectTransferCall({ to: users.admin, amount: protocolRevenues });

        // Expect a {ClaimProtocolRevenues} event to be emitted.
        expectEmit();
        emit Events.ClaimProtocolRevenues(users.admin, DEFAULT_ASSET, protocolRevenues);

        // Claim the protocol revenues.
        config.claimProtocolRevenues(DEFAULT_ASSET);

        // Assert that the protocol revenues have been set to zero.
        uint128 actualProtocolRevenues = config.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
