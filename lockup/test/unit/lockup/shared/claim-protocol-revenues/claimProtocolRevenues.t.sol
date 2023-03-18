// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract ClaimProtocolRevenues_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        base.claimProtocolRevenues(DEFAULT_ASSET);
    }

    modifier whenCallerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.admin });
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolRevenuesZero() external whenCallerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Base_NoProtocolRevenues.selector, DEFAULT_ASSET));
        base.claimProtocolRevenues(DEFAULT_ASSET);
    }

    modifier whenProtocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank({ msgSender: users.sender });
        createDefaultStream();
        changePrank({ msgSender: users.admin });
        _;
    }

    /// @dev it should claim the protocol revenues, update the protocol revenues, and emit a {ClaimProtocolRevenues}
    /// event.
    function test_ClaimProtocolRevenues() external whenCallerAdmin whenProtocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        expectTransferCall({ to: users.admin, amount: protocolRevenues });

        // Expect a {ClaimProtocolRevenues} event to be emitted.
        vm.expectEmit({ emitter: address(base) });
        emit ClaimProtocolRevenues(users.admin, DEFAULT_ASSET, protocolRevenues);

        // Claim the protocol revenues.
        base.claimProtocolRevenues(DEFAULT_ASSET);

        // Assert that the protocol revenues have been set to zero.
        uint128 actualProtocolRevenues = base.protocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
