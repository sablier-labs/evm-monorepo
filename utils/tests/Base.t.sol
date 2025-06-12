// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { AdminableMock } from "src/mocks/AdminableMock.sol";
import { BatchMock } from "src/mocks/BatchMock.sol";
import { ComptrollerManagerMock } from "src/mocks/ComptrollerManagerMock.sol";
import { NoDelegateCallMock } from "src/mocks/NoDelegateCallMock.sol";
import { RoleAdminableMock } from "src/mocks/RoleAdminableMock.sol";
import { BaseTest } from "src/tests/BaseTest.sol";

import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is BaseTest, Modifiers, StdAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint40 public constant FEB_1_2025 = 1_738_368_000;

    /*//////////////////////////////////////////////////////////////////////////
                                     TEST-USERS
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   MOCK-CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    AdminableMock internal adminable;
    BatchMock internal batch;
    ComptrollerManagerMock internal comptrollerManager;
    NoDelegateCallMock internal noDelegateCall;
    RoleAdminableMock internal roleAdminable;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        BaseTest.setUp();

        // Create the test users.
        address[] memory noSpenders;
        users.accountant = createUser("accountant", noSpenders);
        users.alice = createUser("alice", noSpenders);
        users.campaignCreator = createUser("campaignCreator", noSpenders);
        users.eve = createUser("eve", noSpenders);
        users.sender = createUser("sender", noSpenders);

        // Deploy mock contracts.
        adminable = new AdminableMock(admin);
        batch = new BatchMock();
        comptrollerManager = new ComptrollerManagerMock(address(comptroller));
        noDelegateCall = new NoDelegateCallMock();
        roleAdminable = new RoleAdminableMock(admin);

        // Set the admin as the msg.sender.
        setMsgSender(admin);

        // Grant all the roles to the accountant.
        grantAllRoles({ account: users.accountant, target: address(comptroller) });
        grantAllRoles({ account: users.accountant, target: address(roleAdminable) });

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }
}
