// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeployProtocol } from "script/DeployProtocol.s.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";

import { GoodFlashLoanReceiver } from "./shared/mockups/flash-loan/GoodFlashLoanReceiver.t.sol";
import { GoodRecipient } from "./shared/mockups/hooks/GoodRecipient.t.sol";
import { GoodSender } from "./shared/mockups/hooks/GoodSender.t.sol";
import { Assertions } from "./shared/helpers/Assertions.t.sol";
import { Calculations } from "./shared/helpers/Calculations.t.sol";

/// @title Base_Test
/// @notice Base test contract with common logic needed by all test contracts.
abstract contract Base_Test is Assertions, Calculations, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        // Default admin of all Sablier V2 contracts.
        address payable admin;
        // Neutral user.
        address payable alice;
        // Default stream broker.
        address payable broker;
        // Malicious user.
        address payable eve;
        // Default NFT operator.
        address payable operator;
        // Default stream recipient.
        address payable recipient;
        // Default stream sender.
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable DEFAULT_ASSET;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    GoodFlashLoanReceiver internal goodFlashLoanReceiver = new GoodFlashLoanReceiver();
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();
    ISablierV2Comptroller internal comptroller;
    IERC20 internal dai = new ERC20("Dai Stablecoin", "DAI");
    ISablierV2LockupLinear internal linear;
    ISablierV2LockupPro internal pro;
    NonCompliantERC20 internal nonCompliantAsset = new NonCompliantERC20("Non-Compliant ERC-20 Asset", "NCT", 18);

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_ASSET = dai;

        vm.label({ account: address(DEFAULT_ASSET), newLabel: "Dai" });
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(goodSender), newLabel: "Good Sender" });
        vm.label({ account: address(nonCompliantAsset), newLabel: "Non-Compliant ERC-20 Asset" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Modifier that runs the function only in a CI environment.
    modifier onlyInCI() {
        string memory ci = vm.envOr("CI", string(""));
        if (eqString(ci, "true")) {
            _;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            broker: createUser("Broker"),
            eve: createUser("Eve"),
            operator: createUser("Operator"),
            recipient: createUser("Recipient"),
            sender: createUser("Sender")
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all Sablier contracts to spend ERC-20 assets from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the admin.
    function approveProtocol() internal {
        changePrank({ who: users.sender });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ who: users.recipient });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ who: users.alice });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ who: users.eve });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        // Finally, change the active prank back to the admin.
        changePrank({ who: users.admin });
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    /// and 1 million non-compliant assets.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label({ account: addr, newLabel: name });
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(nonCompliantAsset), to: addr, give: 1_000_000e18 });
    }

    /// @dev Conditionally deploy contracts normally or from precompiled source.
    function deployProtocol() internal {
        // We deploy from precompiled source if the profile is "test-optimized".
        if (isTestOptimizedProfile()) {
            comptroller = ISablierV2Comptroller(
                deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json", abi.encode(users.admin))
            );
            linear = ISablierV2LockupLinear(
                deployCode(
                    "optimized-out/SablierV2LockupLinear.sol/SablierV2LockupLinear.json",
                    abi.encode(users.admin, address(comptroller), DEFAULT_MAX_FEE)
                )
            );
            pro = ISablierV2LockupPro(
                deployCode(
                    "optimized-out/SablierV2LockupPro.sol/SablierV2LockupPro.json",
                    abi.encode(users.admin, address(comptroller), DEFAULT_MAX_FEE, DEFAULT_MAX_SEGMENT_COUNT)
                )
            );
        }
        // We deploy normally in all other cases.
        else {
            (comptroller, linear, pro) = new DeployProtocol().run({
                initialAdmin: users.admin,
                maxFee: DEFAULT_MAX_FEE,
                maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(linear), newLabel: "LockupLinear" });
        vm.label({ account: address(pro), newLabel: "LockupPro" });
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool result) {
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        result = eqString(profile, "test-optimized");
    }
}
