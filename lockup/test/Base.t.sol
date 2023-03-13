// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeployProtocol } from "script/deploy/DeployProtocol.s.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { SablierV2NftDescriptor } from "src/SablierV2NftDescriptor.sol";

import { Assertions } from "./shared/Assertions.t.sol";
import { Calculations } from "./shared/Calculations.t.sol";
import { Events } from "./shared/Events.t.sol";
import { Fuzzers } from "./shared/Fuzzers.t.sol";
import { GoodFlashLoanReceiver } from "./shared/mockups/flash-loan/GoodFlashLoanReceiver.t.sol";
import { GoodRecipient } from "./shared/mockups/hooks/GoodRecipient.t.sol";
import { GoodSender } from "./shared/mockups/hooks/GoodSender.t.sol";

/// @title Base_Test
/// @notice Base test contract with common logic needed by all test contracts.
abstract contract Base_Test is Assertions, Calculations, Events, Fuzzers, StdCheats {
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
                                     VARIABLES
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
    SablierV2NftDescriptor internal nftDescriptor = new SablierV2NftDescriptor();
    NonCompliantERC20 internal nonCompliantAsset = new NonCompliantERC20("Non-Compliant ERC-20 Asset", "NCT", 18);
    ISablierV2LockupPro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_ASSET = dai;

        vm.label({ account: address(DEFAULT_ASSET), newLabel: "Dai" });
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(goodSender), newLabel: "Good Sender" });
        vm.label({ account: address(nftDescriptor), newLabel: "Sablier V2 NFT Descriptor" });
        vm.label({ account: address(nonCompliantAsset), newLabel: "Non-Compliant ERC-20 Asset" });
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
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all Sablier contracts to spend ERC-20 assets from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the admin.
    function approveProtocol() internal {
        changePrank({ msgSender: users.sender });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ msgSender: users.recipient });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ msgSender: users.alice });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ msgSender: users.eve });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(pro), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        // Finally, change the active prank back to the admin.
        changePrank({ msgSender: users.admin });
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    /// and 1 million non-compliant assets.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(makeAddr(name));
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
                    abi.encode(users.admin, address(comptroller), address(nftDescriptor), DEFAULT_MAX_FEE)
                )
            );
            pro = ISablierV2LockupPro(
                deployCode(
                    "optimized-out/SablierV2LockupPro.sol/SablierV2LockupPro.json",
                    abi.encode(
                        users.admin,
                        address(comptroller),
                        address(nftDescriptor),
                        DEFAULT_MAX_FEE,
                        DEFAULT_MAX_SEGMENT_COUNT
                    )
                )
            );
        }
        // We deploy normally in all other cases.
        else {
            (comptroller, linear, pro) = new DeployProtocol().run({
                initialAdmin: users.admin,
                nftDescriptor: nftDescriptor,
                maxFee: DEFAULT_MAX_FEE,
                maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(linear), newLabel: "LockupLinear" });
        vm.label({ account: address(pro), newLabel: "LockupPro" });
    }

    /// @dev Expects a call to the `transfer` function of the default ERC-20 asset.
    function expectTransferCall(address to, uint256 amount) internal {
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, amount)));
    }

    /// @dev Expects a call to the `transfer` function of the provided ERC-20 asset.
    function expectTransferCall(IERC20 asset, address to, uint256 amount) internal {
        vm.expectCall(address(asset), abi.encodeCall(IERC20.transfer, (to, amount)));
    }

    /// @dev Expects a call to the `transfer` function of the default ERC-20 asset.
    function expectTransferFromCall(address from, address to, uint256 amount) internal {
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
    }

    /// @dev Expects a call to the `transfer` function of the provided ERC-20 asset.
    function expectTransferFromCall(IERC20 asset, address from, address to, uint256 amount) internal {
        vm.expectCall(address(asset), abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool result) {
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        result = eqString(profile, "test-optimized");
    }
}
