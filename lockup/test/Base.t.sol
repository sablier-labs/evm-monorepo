// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeployProtocol } from "../script/deploy/DeployProtocol.s.sol";
import { ISablierV2Comptroller } from "../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "../src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "../src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { GoodFlashLoanReceiver } from "./mocks/flash-loan/GoodFlashLoanReceiver.sol";
import { GoodRecipient } from "./mocks/hooks/GoodRecipient.sol";
import { GoodSender } from "./mocks/hooks/GoodSender.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Events } from "./utils/Events.sol";
import { Fuzzers } from "./utils/Fuzzers.sol";
import { Users } from "./utils/Types.sol";

/// @title Base_Test
/// @notice Base test contract with common logic needed by all test contracts.
abstract contract Base_Test is Assertions, Calculations, Constants, Events, Fuzzers, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller internal comptroller;
    IERC20 internal dai;
    Defaults internal defaults;
    ISablierV2LockupDynamic internal dynamic;
    GoodFlashLoanReceiver internal goodFlashLoanReceiver;
    GoodRecipient internal goodRecipient;
    GoodSender internal goodSender;
    ISablierV2LockupLinear internal linear;
    SablierV2NFTDescriptor internal nftDescriptor;
    ERC20MissingReturn internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new ERC20("Dai Stablecoin", "DAI");
        goodFlashLoanReceiver = new GoodFlashLoanReceiver();
        goodRecipient = new GoodRecipient();
        goodSender = new GoodSender();
        nftDescriptor = new SablierV2NFTDescriptor();
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(goodSender), newLabel: "Good Sender" });
        vm.label({ account: address(nftDescriptor), newLabel: "NFT Descriptor" });
        vm.label({ account: address(usdt), newLabel: "USDT" });

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

        // Deploy the defaults contract.
        defaults = new Defaults();
        defaults.setAsset(dai);
        defaults.setUsers(users);

        // Warp to March 1, 2023 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp({ timestamp: MARCH_1_2023 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all V2 Core contracts to spend assets from the sender, recipient, Alice and Eve.
    function approveProtocol() internal {
        changePrank({ msgSender: users.sender });
        dai.approve({ spender: address(linear), amount: MAX_UINT256 });
        dai.approve({ spender: address(dynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(linear), value: MAX_UINT256 });
        usdt.approve({ spender: address(dynamic), value: MAX_UINT256 });

        changePrank({ msgSender: users.recipient });
        dai.approve({ spender: address(linear), amount: MAX_UINT256 });
        dai.approve({ spender: address(dynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(linear), value: MAX_UINT256 });
        usdt.approve({ spender: address(dynamic), value: MAX_UINT256 });

        changePrank({ msgSender: users.alice });
        dai.approve({ spender: address(linear), amount: MAX_UINT256 });
        dai.approve({ spender: address(dynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(linear), value: MAX_UINT256 });
        usdt.approve({ spender: address(dynamic), value: MAX_UINT256 });

        changePrank({ msgSender: users.eve });
        dai.approve({ spender: address(linear), amount: MAX_UINT256 });
        dai.approve({ spender: address(dynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(linear), value: MAX_UINT256 });
        usdt.approve({ spender: address(dynamic), value: MAX_UINT256 });

        // Finally, change the active prank back to the admin.
        changePrank({ msgSender: users.admin });
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(makeAddr(name));
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(usdt), to: addr, give: 1_000_000e18 });
    }

    /// @dev Deploys {SablierV2Comptroller} from a source precompiled with `--via-ir`.
    function deployPrecompiledComptroller(address initialAdmin) internal returns (ISablierV2Comptroller comptroller_) {
        comptroller_ = ISablierV2Comptroller(
            deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json", abi.encode(initialAdmin))
        );
    }

    /// @dev Deploys {SablierV2LockupDynamic} from a source precompiled with `--via-ir`.
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
                abi.encode(initialAdmin, address(comptroller_), address(nftDescriptor_), defaults.MAX_SEGMENT_COUNT())
            )
        );
    }

    /// @dev Deploys {SablierV2LockupLinear} from a source precompiled with via IR.
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
        // We deploy normally for all other profiles.
        else {
            (comptroller, dynamic, linear) = new DeployProtocol().run({
                initialAdmin: users.admin,
                initialNFTDescriptor: nftDescriptor,
                maxSegmentCount: defaults.MAX_SEGMENT_COUNT()
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(dynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(linear), newLabel: "LockupLinear" });
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool result) {
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        result = eqString(profile, "test-optimized");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CALL EXPECTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 asset, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 asset, address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }
}
