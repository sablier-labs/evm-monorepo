// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";

import { ISablierFlowBase } from "src/interfaces/ISablierFlowBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "./../../Integration.t.sol";

contract SetProtocolFee_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        flow.setProtocolFee(tokenWithProtocolFee, PROTOCOL_FEE);
    }

    function test_RevertWhen_NewProtocolFeeExceedsMaxFee() external whenCallerAdmin {
        UD60x18 newProtocolFee = MAX_FEE + UNIT;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlowBase_ProtocolFeeTooHigh.selector, newProtocolFee, MAX_FEE)
        );
        flow.setProtocolFee(tokenWithProtocolFee, newProtocolFee);
    }

    modifier whenNewProtocolFeeNotExceedMaxFee() {
        _;
    }

    function test_WhenNewAndOldProtocolFeeAreSame() external whenCallerAdmin whenNewProtocolFeeNotExceedMaxFee {
        // It should emit {SetProtocolFee} and {BatchMetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.SetProtocolFee(users.admin, tokenWithProtocolFee, PROTOCOL_FEE, PROTOCOL_FEE);
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        flow.setProtocolFee(tokenWithProtocolFee, PROTOCOL_FEE);

        // It should re-set the protocol fee.
        assertEq(flow.protocolFee(tokenWithProtocolFee), PROTOCOL_FEE);
    }

    function test_WhenNewAndOldProtocolFeeAreNotSame() external whenCallerAdmin whenNewProtocolFeeNotExceedMaxFee {
        UD60x18 newProtocolFee = PROTOCOL_FEE + UD60x18.wrap(0.01e18);

        // It should emit {SetProtocolFee} and {BatchMetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlowBase.SetProtocolFee(users.admin, tokenWithProtocolFee, PROTOCOL_FEE, newProtocolFee);
        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.BatchMetadataUpdate({ _fromTokenId: 1, _toTokenId: flow.nextStreamId() - 1 });

        flow.setProtocolFee(tokenWithProtocolFee, newProtocolFee);

        // It should set the protocol fee.
        assertEq(flow.protocolFee(tokenWithProtocolFee), newProtocolFee);
    }
}
