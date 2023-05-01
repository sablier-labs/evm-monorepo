// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeployProtocol } from "script/deploy/DeployProtocol.s.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2NFTDescriptor } from "src/SablierV2NFTDescriptor.sol";

import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Events } from "./utils/Events.sol";
import { Fuzzers } from "./utils/Fuzzers.sol";
import { GoodFlashLoanReceiver } from "./mocks/flash-loan/GoodFlashLoanReceiver.sol";
import { GoodRecipient } from "./mocks/hooks/GoodRecipient.sol";
import { GoodSender } from "./mocks/hooks/GoodSender.sol";

/// @title Base_Test
/// @notice Base test contract with common logic needed by all test contracts.
abstract contract Base_Test is Assertions, Calculations, Events, Fuzzers, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        // Default admin for all Sablier V2 contracts.
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

    ISablierV2LockupDynamic internal dynamic;
    GoodFlashLoanReceiver internal goodFlashLoanReceiver = new GoodFlashLoanReceiver();
    GoodRecipient internal goodRecipient = new GoodRecipient();
    GoodSender internal goodSender = new GoodSender();
    ISablierV2Comptroller internal comptroller;
    IERC20 internal dai = new ERC20("Dai Stablecoin", "DAI");
    ISablierV2LockupLinear internal linear;
    SablierV2NFTDescriptor internal nftDescriptor = new SablierV2NFTDescriptor();
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

        // Warp to March 1, 2023 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp({ timestamp: DEFAULT_START_TIME });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all Sablier contracts to spend assets from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the admin.
    function approveProtocol() internal {
        changePrank({ msgSender: users.sender });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(dynamic), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(dynamic), value: UINT256_MAX });

        changePrank({ msgSender: users.recipient });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(dynamic), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(dynamic), value: UINT256_MAX });

        changePrank({ msgSender: users.alice });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(dynamic), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(dynamic), value: UINT256_MAX });

        changePrank({ msgSender: users.eve });
        dai.approve({ spender: address(linear), amount: UINT256_MAX });
        dai.approve({ spender: address(dynamic), amount: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(dynamic), value: UINT256_MAX });

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

    /// @dev Deploys {SablierV2Comptroller} from precompiled source.
    function deployPrecompiledComptroller(address initialAdmin) internal returns (ISablierV2Comptroller comptroller_) {
        comptroller_ = ISablierV2Comptroller(
            deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json", abi.encode(initialAdmin))
        );
    }

    /// @dev Deploys {SablierV2LockupDynamic} from precompiled source.
    function deployPrecompiledDynamic(
        address initialAdmin,
        ISablierV2Comptroller comptroller_,
        ISablierV2NFTDescriptor nftDescriptor_
    )
        internal
        returns (ISablierV2LockupDynamic dynamic_)
    {
        dynamic_ = ISablierV2LockupDynamic(
            deployCode(
                "optimized-out/SablierV2LockupDynamic.sol/SablierV2LockupDynamic.json",
                abi.encode(initialAdmin, address(comptroller_), address(nftDescriptor_), DEFAULT_MAX_SEGMENT_COUNT)
            )
        );
    }

    /// @dev Deploys {SablierV2LockupLinear} from precompiled source.
    function deployPrecompiledLinear(
        address initialAdmin,
        ISablierV2Comptroller comptroller_,
        ISablierV2NFTDescriptor nftDescriptor_
    )
        internal
        returns (ISablierV2LockupLinear linear_)
    {
        linear_ = ISablierV2LockupLinear(
            deployCode(
                "optimized-out/SablierV2LockupLinear.sol/SablierV2LockupLinear.json",
                abi.encode(initialAdmin, address(comptroller_), address(nftDescriptor_))
            )
        );
    }

    /// @dev Conditionally deploy V2 Core normally or from a source precompiled with via IR.
    function deployProtocolConditionally() internal {
        // We deploy from precompiled source if the profile is "test-optimized".
        if (isTestOptimizedProfile()) {
            comptroller = deployPrecompiledComptroller(users.admin);
            dynamic = deployPrecompiledDynamic(users.admin, comptroller, nftDescriptor);
            linear = deployPrecompiledLinear(users.admin, comptroller, nftDescriptor);
        }
        // We deploy normally in all other cases.
        else {
            (comptroller, dynamic, linear) = new DeployProtocol().run({
                initialAdmin: users.admin,
                initialNFTDescriptor: nftDescriptor,
                maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(dynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(linear), newLabel: "LockupLinear" });
    }

    /// @dev Expects a call to the `transfer` function of the default ERC-20 contract.
    function expectTransferCall(address to, uint256 amount) internal {
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (to, amount)));
    }

    /// @dev Expects a call to the `transfer` function of the provided ERC-20 contract.
    function expectTransferCall(IERC20 asset, address to, uint256 amount) internal {
        vm.expectCall(address(asset), abi.encodeCall(IERC20.transfer, (to, amount)));
    }

    /// @dev Expects a call to the `transferFrom` function of the default ERC-20 contract.
    function expectTransferFromCall(address from, address to, uint256 amount) internal {
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
    }

    /// @dev Expects a call to the `transferFrom` function of the provided ERC-20 contract.
    function expectTransferFromCall(IERC20 asset, address from, address to, uint256 amount) internal {
        vm.expectCall(address(asset), abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool result) {
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        result = eqString(profile, "test-optimized");
    }
}
