// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract GetCustomFeeUsers_Comptroller_Concrete_Test is Base_Test {
    function test_GivenNoCustomFeesSet(uint8 protocolIndex) external view {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        (address[] memory users, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should return empty arrays.
        assertEq(users.length, 0, "users length");
        assertEq(fees.length, 0, "fees length");
    }

    function test_GivenOneCustomFeeSet(uint8 protocolIndex) external {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        uint256 customFee = 5e8; // $5
        comptroller.setCustomFeeUSDFor(protocol, users.alice, customFee);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should return one user.
        assertEq(returnedUsers.length, 1, "users length");
        // It should return the correct fee.
        assertEq(returnedUsers[0], users.alice, "user address");
        assertEq(fees[0], customFee, "fee amount");
    }

    modifier givenMultipleCustomFeesSet() {
        _;
    }

    function test_GivenMultipleCustomFeesSet(uint8 protocolIndex) external givenMultipleCustomFeesSet {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        uint256 feeAlice = 5e8; // $5
        uint256 feeEve = 10e8; // $10
        comptroller.setCustomFeeUSDFor(protocol, users.alice, feeAlice);
        comptroller.setCustomFeeUSDFor(protocol, users.eve, feeEve);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should return all users.
        assertEq(returnedUsers.length, 2, "users length");
        // It should return the correct fees.
        assertEq(fees.length, 2, "fees length");

        // Verify both users and fees are present (order depends on EnumerableSet).
        bool foundAlice;
        bool foundEve;
        for (uint256 i = 0; i < returnedUsers.length; ++i) {
            if (returnedUsers[i] == users.alice) {
                assertEq(fees[i], feeAlice, "alice fee");
                foundAlice = true;
            } else if (returnedUsers[i] == users.eve) {
                assertEq(fees[i], feeEve, "eve fee");
                foundEve = true;
            }
        }
        assertTrue(foundAlice, "alice not found");
        assertTrue(foundEve, "eve not found");
    }

    function test_WhenACustomFeeIsDisabled(uint8 protocolIndex) external givenMultipleCustomFeesSet {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        uint256 feeAlice = 5e8;
        uint256 feeEve = 10e8;
        comptroller.setCustomFeeUSDFor(protocol, users.alice, feeAlice);
        comptroller.setCustomFeeUSDFor(protocol, users.eve, feeEve);

        // Disable the custom fee for Alice.
        comptroller.disableCustomFeeUSDFor(protocol, users.alice);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should not include the disabled user.
        assertEq(returnedUsers.length, 1, "users length after disable");
        // It should return remaining users and fees.
        assertEq(returnedUsers[0], users.eve, "remaining user");
        assertEq(fees[0], feeEve, "remaining fee");
    }
}
