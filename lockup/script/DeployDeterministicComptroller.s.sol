// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <=0.9.0;

import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys {SablierV2Comptroller} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicComptroller is BaseScript {
    /// @dev The presence of the salt instructs Forge to deploy contracts via this deterministic CREATE2 factory:
    /// https://github.com/Arachnid/deterministic-deployment-proxy
    function run(
        string memory create2Salt,
        address initialAdmin
    )
        public
        virtual
        broadcast
        returns (SablierV2Comptroller comptroller)
    {
        comptroller = new SablierV2Comptroller{ salt: bytes32(abi.encodePacked(create2Salt)) }(initialAdmin);
    }
}
