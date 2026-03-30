// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract GetCustomFeeUsers_Comptroller_Concrete_Test is Base_Test {
    function test_GivenNoCustomFeesSet(uint8 protocolIndex) external view {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should return empty arrays.
        assertEq(returnedUsers.length, 0, "users length");
        assertEq(fees.length, 0, "fees length");
    }

    modifier givenOneCustomFeeSet() {
        _;
    }

    function test_GivenOneCustomFeeSet(uint8 protocolIndex, uint128 customFeeUSD) external givenOneCustomFeeSet {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        customFeeUSD = boundUint128(customFeeUSD, 1, uint128(MAX_FEE_USD));

        comptroller.setCustomFeeUSDFor(protocol, users.alice, customFeeUSD);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should return one user.
        assertEq(returnedUsers.length, 1, "users length");
        // It should return the correct fee.
        assertEq(returnedUsers[0], users.alice, "user address");
        assertEq(fees[0], customFeeUSD, "fee amount");
    }

    function test_WhenFeeIsZero(uint8 protocolIndex) external givenOneCustomFeeSet {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Set a custom fee of 0 (enabled = true, fee = 0).
        comptroller.setCustomFeeUSDFor(protocol, users.alice, 0);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should include the zero fee user.
        assertEq(returnedUsers.length, 1, "users length");
        assertEq(returnedUsers[0], users.alice, "user address");
        assertEq(fees[0], 0, "fee amount");
    }

    function test_GivenSameUserSetTwice(uint8 protocolIndex, uint128 firstFee, uint128 secondFee) external {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        firstFee = boundUint128(firstFee, 0, uint128(MAX_FEE_USD));
        secondFee = boundUint128(secondFee, 0, uint128(MAX_FEE_USD));

        // Set the custom fee twice for the same user.
        comptroller.setCustomFeeUSDFor(protocol, users.alice, firstFee);
        comptroller.setCustomFeeUSDFor(protocol, users.alice, secondFee);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should not duplicate the user.
        assertEq(returnedUsers.length, 1, "users length");
        assertEq(returnedUsers[0], users.alice, "user address");
        assertEq(fees[0], secondFee, "fee should be updated to second value");
    }

    function test_GivenCustomFeesSetOnDifferentProtocols() external {
        uint256 feeAlice = 5e8;
        uint256 feeEve = 10e8;

        // Set custom fees on different protocols.
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.alice, feeAlice);
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Flow, users.eve, feeEve);

        // Check Airdrops: should only contain Alice.
        (address[] memory airdropUsers, uint256[] memory airdropFees) =
            comptroller.getCustomFeeUsers(ISablierComptroller.Protocol.Airdrops);
        assertEq(airdropUsers.length, 1, "airdrops users length");
        assertEq(airdropUsers[0], users.alice, "airdrops user");
        assertEq(airdropFees[0], feeAlice, "airdrops fee");

        // Check Flow: should only contain Eve.
        (address[] memory flowUsers, uint256[] memory flowFees) =
            comptroller.getCustomFeeUsers(ISablierComptroller.Protocol.Flow);
        assertEq(flowUsers.length, 1, "flow users length");
        assertEq(flowUsers[0], users.eve, "flow user");
        assertEq(flowFees[0], feeEve, "flow fee");

        // Check Lockup: should be empty.
        (address[] memory lockupUsers, uint256[] memory lockupFees) =
            comptroller.getCustomFeeUsers(ISablierComptroller.Protocol.Lockup);
        assertEq(lockupUsers.length, 0, "lockup users length");
        assertEq(lockupFees.length, 0, "lockup fees length");

        // Check Staking: should be empty.
        (address[] memory stakingUsers, uint256[] memory stakingFees) =
            comptroller.getCustomFeeUsers(ISablierComptroller.Protocol.Staking);
        assertEq(stakingUsers.length, 0, "staking users length");
        assertEq(stakingFees.length, 0, "staking fees length");

        // Check Bob: should be empty.
        (address[] memory bobUsers, uint256[] memory bobFees) =
            comptroller.getCustomFeeUsers(ISablierComptroller.Protocol.Bob);

        // It should isolate users per protocol.
        assertEq(bobUsers.length, 0, "bob users length");
        assertEq(bobFees.length, 0, "bob fees length");
    }

    modifier givenMultipleCustomFeesSet() {
        _;
    }

    function test_GivenMultipleCustomFeesSet(
        uint8 protocolIndex,
        uint128 feeAlice,
        uint128 feeEve
    )
        external
        givenMultipleCustomFeesSet
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        feeAlice = boundUint128(feeAlice, 0, uint128(MAX_FEE_USD));
        feeEve = boundUint128(feeEve, 0, uint128(MAX_FEE_USD));

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
        // It should return remaining users and fees (order-independent check).
        bool foundEve;
        for (uint256 i = 0; i < returnedUsers.length; ++i) {
            if (returnedUsers[i] == users.eve) {
                assertEq(fees[i], feeEve, "eve fee");
                foundEve = true;
            }
        }
        assertTrue(foundEve, "eve not found");
    }

    function test_WhenANon_existentUserIsDisabled(uint8 protocolIndex) external givenMultipleCustomFeesSet {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        uint256 feeAlice = 5e8;
        uint256 feeEve = 10e8;
        comptroller.setCustomFeeUSDFor(protocol, users.alice, feeAlice);
        comptroller.setCustomFeeUSDFor(protocol, users.eve, feeEve);

        // Disable a user that was never set — should be a no-op.
        comptroller.disableCustomFeeUSDFor(protocol, users.sender);

        (address[] memory returnedUsers, uint256[] memory fees) = comptroller.getCustomFeeUsers(protocol);

        // It should not affect existing users.
        assertEq(returnedUsers.length, 2, "users length unchanged");

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
}
