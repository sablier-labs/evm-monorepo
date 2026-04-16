// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import { IComptrollerable } from "src/interfaces/IComptrollerable.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

import { Base_Test } from "tests/Base.t.sol";
import { BaseScriptMock } from "tests/mocks/BaseScriptMock.sol";

contract Comptroller_Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    BaseScriptMock internal baseScript;
    address internal defaultMultisigAdmin;
    address[] internal protocolAddresses;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        // Fork Ethereum Mainnet at the latest block number.
        vm.createSelectFork({ urlOrAlias: "ethereum" });

        // Set the default multisig admin address.
        defaultMultisigAdmin = 0x58290bbdb51A4c6B022A81e9cDeD24BE19Ca57fd;

        // Deploy the `BaseScriptMock` contract.
        baseScript = new BaseScriptMock();

        // Load comptroller address from the mainnet.
        comptroller = ISablierComptroller(0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399);

        // Load Airdrops (only Merkle Instant Factory) Bob, Flow and Lockup addresses from the mainnet.
        protocolAddresses = new address[](4);
        protocolAddresses[0] = 0xb2855845067e126207DE2155Ad1c8AD5C495cb3F;
        protocolAddresses[1] = 0xC8AB7E45E6DF99596b86870c26C25c721eB5C9af;
        protocolAddresses[2] = 0x844344Cd871B28221d725ecE9630E8bDE4E3a181;
        protocolAddresses[3] = 0x93b37Bd5B6b278373217333Ac30D7E74c85fBDCB;

        // Set comptroller admin as the caller.
        setMsgSender(defaultMultisigAdmin);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev It should return the correct admin address.
    function testFork_Admin() external view {
        assertEq(comptroller.admin(), defaultMultisigAdmin, "admin");
    }

    /// @dev Checklist:
    /// - It should return zero value for Staking protocol.
    /// - It should return non-zero value for Airdrops, Bob, Flow and Lockup.
    function testForkFuzz_CalculateMinFeeWei(uint8 protocolIndex) external view {
        // Bound the protocol enum to a valid enum value.
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // It should return the min fee in wei.
        uint256 minFeeInWei = comptroller.calculateMinFeeWei(protocol);
        if (protocol == ISablierComptroller.Protocol.Staking) {
            assertEq(minFeeInWei, 0, "Staking: minFeeInWei > 0");
        } else {
            assertGt(minFeeInWei, 0, "Airdrops, Bob, Flow, Lockup: minFeeInWei == 0");
        }
    }

    /// @dev It tests the state variables that will rarely be changed.
    function testFork_Constructor() external view {
        // It should set the comptroller admin.
        assertEq(comptroller.admin(), defaultMultisigAdmin, "admin");

        // It should set the max fee in USD.
        assertEq(comptroller.MAX_FEE_USD(), MAX_FEE_USD, "max fee USD");

        // It should set the comptroller version.
        assertEq(comptroller.VERSION(), "v1.1", "version");

        // It should set the oracle address.
        assertEq(comptroller.oracle(), baseScript.getChainlinkOracle(), "oracle");
    }

    /// @dev It should use `execute` function to change the comptroller on the protocol contracts.
    function testFork_Execute() external {
        // Deploy a new comptroller.
        SablierComptroller newComptroller = new SablierComptroller(defaultMultisigAdmin);

        bytes memory payload = abi.encodeCall(IComptrollerable.setComptroller, (newComptroller));

        // Use `execute` function to change comptroller for each of the protocols.
        for (uint256 i; i < protocolAddresses.length; ++i) {
            // It should emit an {Execute} event.
            vm.expectEmit({ emitter: address(comptroller) });
            emit ISablierComptroller.Execute({
                target: protocolAddresses[i],
                targetCallData: abi.encodeCall(IComptrollerable.setComptroller, (newComptroller)),
                result: ""
            });

            comptroller.execute({ target: protocolAddresses[i], targetCallData: payload });

            // It should change the comptroller.
            assertEq(
                address(IComptrollerable(protocolAddresses[i]).comptroller()),
                address(newComptroller),
                "New comptroller"
            );
        }
    }

    /// @dev It should change the min fee in USD for a given protocol.
    function testForkFuzz_SetMinFeeUSD(uint8 protocolIndex, uint256 newMinFeeUSD) external whenNewFeeNotExceedMaxFee {
        // Bound custom fee USD to the max fee USD.
        newMinFeeUSD = bound(newMinFeeUSD, 0, MAX_FEE_USD);

        // Bound the protocol enum to a valid enum value.
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Set min fee USD.
        comptroller.setMinFeeUSD(protocol, newMinFeeUSD);

        // It should set the min fee USD.
        assertEq(comptroller.getMinFeeUSD(protocol), newMinFeeUSD, "min fee USD");
    }

    /// @dev It should transfer fees from Lockup and Flow to the provided fee recipient.
    function testForkFuzz_TransferFees(address feeRecipient) external whenFeeRecipientNotZero {
        // Skip if fee recipient is zero address, or a contract that cannot receive ETH.
        vm.assume(feeRecipient != address(0) && feeRecipient.code.length == 0);

        uint256 initialFeeRecipientBalance = feeRecipient.balance;

        // Calculate expected fee amount as the sum of balances of comptroller and protocol addresses.
        uint256 expectedFeeAmount = address(comptroller).balance;
        for (uint256 i; i < protocolAddresses.length; ++i) {
            expectedFeeAmount += protocolAddresses[i].balance;
        }

        // It should emit a {TransferFees} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.TransferFees({ feeRecipient: feeRecipient, feeAmount: expectedFeeAmount });

        // Transfer fees to the fee recipient.
        comptroller.transferFees(protocolAddresses, feeRecipient);

        // It should transfer the fee to the fee recipient.
        assertEq(feeRecipient.balance, initialFeeRecipientBalance + expectedFeeAmount, "Fee Recipient balance");
    }

    /// @dev It should change the implementation address for the Comptroller proxy.
    function testFork_UpgradeToAndCall() external {
        // Deploy a new implementation that supports {IERC1822Proxiable} interface.
        address newImplementation = address(new SablierComptroller(admin));

        // Upgrade to the new implementation.
        UUPSUpgradeable(address(comptroller)).upgradeToAndCall(newImplementation, "");

        // It should set the new implementation.
        address actualComptrollerImpl = Upgrades.getImplementationAddress(address(comptroller));
        address expectedComptrollerImpl = newImplementation;
        assertEq(actualComptrollerImpl, expectedComptrollerImpl, "implementation");
    }
}
