// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2Comptroller } from "../../../../src/SablierV2Comptroller.sol";

import { Base_Test } from "../../../Base.t.sol";

contract Comptroller_Unit_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deployConditionally();
    }

    /// @dev Conditionally deploys {SablierV2Comptroller} normally or from a source precompiled with `--via-ir`.
    function deployConditionally() internal {
        if (!isTestOptimizedProfile()) {
            comptroller = new SablierV2Comptroller(users.admin);
        } else {
            comptroller = deployPrecompiledComptroller(users.admin);
        }
        vm.label({ account: address(comptroller), newLabel: "SablierV2Comptroller" });
    }
}
