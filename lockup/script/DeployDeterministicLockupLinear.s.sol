// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13 <0.9.0;

import { Script } from "forge-std/Script.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";

import { Common } from "./helpers/Common.s.sol";

/// @dev Deploys the {SablierV2LockupLinear} contract at a deterministic address across all chains. Reverts if
/// the contract has already been deployed via the deterministic CREATE2 factory.
contract DeployDeterministicLinear is Script, Common {
    function run(
        address admin,
        ISablierV2Comptroller comptroller,
        UD60x18 maxFee
    ) public broadcaster returns (bool success, SablierV2LockupLinear linear) {
        bytes memory creationBytecode = type(SablierV2LockupLinear).creationCode;
        bytes memory callData = abi.encodePacked(creationBytecode, abi.encode(admin, comptroller, maxFee));
        bytes memory returnData;
        (success, returnData) = DETERMINISTIC_CREATE2_FACTORY.call(callData);
        linear = SablierV2LockupLinear(address(uint160(bytes20(returnData))));
    }
}
