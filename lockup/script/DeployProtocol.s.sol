// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { Common } from "./helpers/Common.s.sol";
import { DeployComptroller } from "./DeployComptroller.s.sol";

/// @notice Deploys the entire Sablier V2 protocol. The contracts are deployed in the following order:
///
/// 1. SablierV2Comptroller
/// 2. SablierV2Linear
/// 3. SablierV2Pro
contract DeployProtocol is Script, Common {
    function run(
        UD60x18 maxFee,
        uint256 maxSegmentCount
    ) public broadcaster returns (SablierV2Comptroller comptroller, SablierV2Linear linear, SablierV2Pro pro) {
        comptroller = new SablierV2Comptroller();
        linear = new SablierV2Linear(comptroller, maxFee);
        pro = new SablierV2Pro(comptroller, maxFee, maxSegmentCount);
    }

    /// @dev Deploys the contracts at deterministic addresses across all chains. Reverts if any contract has already
    /// been deployed via the deterministic CREATE2 factory.
    function runDeterministic(
        UD60x18 maxFee,
        uint256 maxSegmentCount
    )
        public
        broadcaster
        returns (bool success, SablierV2Comptroller comptroller, SablierV2Linear linear, SablierV2Pro pro)
    {
        // Deploy the SablierV2Comptroller contract.
        bytes memory comptrollerCreationBytecode = type(SablierV2Comptroller).creationCode;
        bytes memory comptrollerReturnData;
        (success, comptrollerReturnData) = DETERMINISTIC_CREATE2_FACTORY.call(comptrollerCreationBytecode);
        comptroller = SablierV2Comptroller(address(uint160(bytes20(comptrollerReturnData))));

        // Deploy the SablierV2Linear contract.
        bytes memory linearCreationBytecode = type(SablierV2Comptroller).creationCode;
        bytes memory linearCallData = abi.encodePacked(linearCreationBytecode, abi.encode(comptroller, maxFee));
        bytes memory linearReturnData;
        (success, linearReturnData) = DETERMINISTIC_CREATE2_FACTORY.call(linearCallData);
        linear = SablierV2Linear(address(uint160(bytes20(linearReturnData))));

        // Deploy the SablierV2Pro contract.
        bytes memory proCreationBytecode = type(SablierV2Comptroller).creationCode;
        bytes memory proCallData = abi.encodePacked(
            proCreationBytecode,
            abi.encode(comptroller, maxFee, maxSegmentCount)
        );
        bytes memory proReturnData;
        (success, proReturnData) = DETERMINISTIC_CREATE2_FACTORY.call(proCallData);
        pro = SablierV2Pro(address(uint160(bytes20(proReturnData))));
    }
}
