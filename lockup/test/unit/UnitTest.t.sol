// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Linear } from "src/interfaces/ISablierV2Linear.sol";
import { ISablierV2Pro } from "src/interfaces/ISablierV2Pro.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "test/BaseTest.t.sol";
import { Empty } from "test/helpers/hooks/Empty.t.sol";
import { GoodRecipient } from "test/helpers/hooks/GoodRecipient.t.sol";
import { GoodSender } from "test/helpers/hooks/GoodSender.t.sol";
import { ReentrantRecipient } from "test/helpers/hooks/ReentrantRecipient.t.sol";
import { ReentrantSender } from "test/helpers/hooks/ReentrantSender.t.sol";
import { RevertingRecipient } from "test/helpers/hooks/RevertingRecipient.t.sol";
import { RevertingSender } from "test/helpers/hooks/RevertingSender.t.sol";
import { SablierV2Mock } from "test/helpers/mocks/SablierV2Mock.t.sol";

abstract contract UnitTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        // Neutral user.
        address payable alice;
        // Malicious user.
        address payable eve;
        // Default NFT operator.
        address payable operator;
        // Default owner of all Sablier V2 contracts.
        address payable owner;
        // Recipient of the default stream.
        address payable recipient;
        // Sender of the default stream.
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller internal comptroller;
    ISablierV2Linear internal linear;
    ISablierV2Pro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    Empty internal empty = new Empty();
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();
    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Non-Compliant Token", "NCT", 18);
    ReentrantRecipient internal reentrantRecipient = new ReentrantRecipient();
    ReentrantSender internal reentrantSender = new ReentrantSender();
    RevertingRecipient internal revertingRecipient = new RevertingRecipient();
    RevertingSender internal revertingSender = new RevertingSender();

    /*//////////////////////////////////////////////////////////////////////////
                                      STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create users for testing.
        users = Users({
            alice: createUser("Alice"),
            eve: createUser("Eve"),
            operator: createUser("Operator"),
            owner: createUser("Owner"),
            recipient: createUser("Recipient"),
            sender: createUser("Sender")
        });

        // Deploy all contracts.
        deployContracts();

        // Label all contracts.
        labelContracts();

        // Approve all contracts.
        approveContracts();
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve all Sablier contracts to spend tokens from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the owner.
    function approveContracts() internal {
        changePrank(users.sender);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.recipient);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.alice);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.eve);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.owner);
    }

    /// @dev Helper function to create the default stream, meant to be overridden by the child test contracts.
    function createDefaultStream() internal virtual returns (uint256 streamId);

    /// @dev Helper function to create the default stream, meant to be overridden by the child test contracts.
    function createDefaultStreamNonCancelable() internal virtual returns (uint256 streamId);

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    ///  and 1 million non-compliant tokens.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label({ account: addr, newLabel: name });
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(nonCompliantToken), to: addr, give: 1_000_000e18 });
    }

    /// @dev Deploy all contracts with the owner as the caller.
    function deployContracts() internal {
        vm.startPrank({ msgSender: users.owner });
        comptroller = new SablierV2Comptroller();
        linear = new SablierV2Linear({ initialComptroller: comptroller, maxFee: MAX_FEE });
        pro = new SablierV2Pro({
            initialComptroller: comptroller,
            maxFee: MAX_FEE,
            maxSegmentCount: MAX_SEGMENT_COUNT
        });
    }

    /// @dev Label all contracts, which helps during debugging.
    function labelContracts() internal {
        // Label the Sablier contracts.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(linear), newLabel: "SablierV2Linear" });
        vm.label({ account: address(pro), newLabel: "SablierV2Pro" });

        // Label the test contracts.
        vm.label({ account: address(empty), newLabel: "Empty" });
        vm.label({ account: address(dai), newLabel: "Dai" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(goodSender), newLabel: "Good Sender" });
        vm.label({ account: address(nonCompliantToken), newLabel: "Non-Compliant Token" });
        vm.label({ account: address(reentrantRecipient), newLabel: "Reentrant Recipient" });
        vm.label({ account: address(reentrantSender), newLabel: "Reentrant Sender" });
        vm.label({ account: address(revertingRecipient), newLabel: "Reverting Recipient" });
        vm.label({ account: address(revertingSender), newLabel: "Reverting Sender" });
    }
}
