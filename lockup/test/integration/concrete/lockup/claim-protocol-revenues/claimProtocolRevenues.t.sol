// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract ClaimProtocolRevenues_Integration_Concrete_Test is
    Integration_Test,
    Lockup_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        base.claimProtocolRevenues(dai);
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
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

        // Expect the relevant event to be emitted.
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
