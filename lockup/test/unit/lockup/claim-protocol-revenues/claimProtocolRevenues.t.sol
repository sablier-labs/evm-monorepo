// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract ClaimProtocolRevenues_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        base.claimProtocolRevenues(dai);
    }

    modifier whenCallerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_RevertWhen_ProtocolRevenuesZero() external whenCallerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Base_NoProtocolRevenues.selector, dai));
        base.claimProtocolRevenues(dai);
    }

    modifier whenProtocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank({ msgSender: users.sender });
        createDefaultStream();
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_ClaimProtocolRevenues() external whenCallerAdmin whenProtocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = defaults.PROTOCOL_FEE_AMOUNT();
        expectCallToTransfer({ to: users.admin, amount: protocolRevenues });

        // Expect a {ClaimProtocolRevenues} event to be emitted.
        vm.expectEmit({ emitter: address(base) });
        emit ClaimProtocolRevenues(users.admin, dai, protocolRevenues);

        // Claim the protocol revenues.
        base.claimProtocolRevenues(dai);

        // Assert that the protocol revenues have been set to zero.
        uint128 actualProtocolRevenues = base.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
