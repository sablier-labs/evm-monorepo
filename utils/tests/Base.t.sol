// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import { StdAssertions } from "forge-std/src/StdAssertions.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { SafeOracleMock } from "src/mocks/ChainlinkMocks.sol";
import { BaseTest } from "src/tests/BaseTest.sol";

import { AdminableMock } from "./mocks/AdminableMock.sol";
import { BatchMock } from "./mocks/BatchMock.sol";
import { ComptrollerableMock } from "./mocks/ComptrollerableMock.sol";
import { MerkleMock } from "./mocks/MerkleMock.sol";
import { NoDelegateCallMock } from "./mocks/NoDelegateCallMock.sol";
import { RoleAdminableMock } from "./mocks/RoleAdminableMock.sol";
import { SafeTokenSymbolMock } from "./mocks/SafeTokenSymbolMock.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is BaseTest, Modifiers, StdAssertions, Utils {
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

    AdminableMock internal adminableMock;
    BatchMock internal batchMock;
    ComptrollerableMock internal comptrollerableMock;
    MerkleMock internal merkleMock;
    NoDelegateCallMock internal noDelegateCallMock;
    RoleAdminableMock internal roleAdminableMock;
    SafeOracleMock internal safeOracleMock;
    SafeTokenSymbolMock internal safeTokenSymbolMock;

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
        adminableMock = new AdminableMock(admin);
        batchMock = new BatchMock();
        comptrollerableMock = new ComptrollerableMock(address(comptroller));
        merkleMock = new MerkleMock();
        noDelegateCallMock = new NoDelegateCallMock();
        roleAdminableMock = new RoleAdminableMock(admin);
        safeOracleMock = new SafeOracleMock();
        safeTokenSymbolMock = new SafeTokenSymbolMock();

        // Set the admin as the msg.sender.
        setMsgSender(admin);

        // Grant all the roles to the accountant.
        grantAllRoles({ account: users.accountant, target: address(comptroller) });
        grantAllRoles({ account: users.accountant, target: address(roleAdminableMock) });

        // Set the min fee USD for the staking protocol.
        comptroller.setMinFeeUSD(ISablierComptroller.Protocol.Staking, STAKING_MIN_FEE_USD);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Get the implementation address of the comptroller.
    function getComptrollerImplAddress() internal view returns (address payable) {
        return payable(Upgrades.getImplementationAddress(address(comptroller)));
    }
}
