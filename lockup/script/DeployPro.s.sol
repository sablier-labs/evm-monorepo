// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { Common } from "./helpers/Common.s.sol";

/// @notice Deploys the SablierV2Pro contract.
contract DeployPro is Script, Common {
    function run(
        address admin,
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public broadcaster returns (SablierV2Pro pro) {
        pro = new SablierV2Pro({
            initialAdmin: admin,
            initialComptroller: comptroller,
            maxFee: maxFee,
            maxSegmentCount: maxSegmentCount
        });
    }

    /// @dev Deploys the contract at a deterministic address across all chains. Reverts if the contract has already
    /// been deployed via the deterministic CREATE2 factory.
    function runDeterministic(
        address admin,
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public broadcaster returns (bool success, SablierV2Pro pro) {
        bytes memory creationBytecode = type(SablierV2Pro).creationCode;
        bytes memory callData = abi.encodePacked(
            creationBytecode,
            abi.encode(admin, comptroller, maxFee, maxSegmentCount)
        );
        bytes memory returnData;
        (success, returnData) = DETERMINISTIC_CREATE2_FACTORY.call(callData);
        pro = SablierV2Pro(address(uint160(bytes20(returnData))));
    }
}
