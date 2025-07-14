// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { AdminableMock } from "src/mocks/AdminableMock.sol";
import { BatchMock } from "src/mocks/BatchMock.sol";
import { ComptrollerableMock } from "src/mocks/ComptrollerableMock.sol";
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

    AdminableMock internal adminableMock;
    BatchMock internal batchMock;
    ComptrollerableMock internal comptrollerableMock;
    NoDelegateCallMock internal noDelegateCallMock;
    RoleAdminableMock internal roleAdminableMock;

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
        noDelegateCallMock = new NoDelegateCallMock();
        roleAdminableMock = new RoleAdminableMock(admin);

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

    /// @dev Bound the protocol to a valid enum value.
    function boundProtocolEnum(uint8 protocolIndex) internal pure returns (ISablierComptroller.Protocol) {
        return ISablierComptroller.Protocol(boundUint8(protocolIndex, 0, 3));
    }

    /// @dev Convert value from USD to ETH wei.
    function convertUSDToWei(uint128 amountUSD) internal pure returns (uint256 amountWei) {
        amountWei = (1e18 * uint256(amountUSD)) / ETH_PRICE_USD;
    }

    /// @dev Returns the fee in USD for the given protocol.
    function getFeeInUSD(ISablierComptroller.Protocol protocol) internal pure returns (uint256 feeInUSD) {
        if (protocol == ISablierComptroller.Protocol.Airdrops) {
            feeInUSD = AIRDROP_MIN_FEE_USD;
        } else if (protocol == ISablierComptroller.Protocol.Flow) {
            feeInUSD = FLOW_MIN_FEE_USD;
        } else if (protocol == ISablierComptroller.Protocol.Lockup) {
            feeInUSD = LOCKUP_MIN_FEE_USD;
        } else if (protocol == ISablierComptroller.Protocol.Staking) {
            feeInUSD = STAKING_MIN_FEE_USD;
        }
    }

    /// @dev Returns the fee in wei for the given protocol.
    function getFeeInWei(ISablierComptroller.Protocol protocol) internal pure returns (uint256 feeInWei) {
        if (protocol == ISablierComptroller.Protocol.Airdrops) {
            feeInWei = AIRDROP_MIN_FEE_WEI;
        } else if (protocol == ISablierComptroller.Protocol.Flow) {
            feeInWei = FLOW_MIN_FEE_WEI;
        } else if (protocol == ISablierComptroller.Protocol.Lockup) {
            feeInWei = LOCKUP_MIN_FEE_WEI;
        } else if (protocol == ISablierComptroller.Protocol.Staking) {
            feeInWei = STAKING_MIN_FEE_WEI;
        }
    }
}
