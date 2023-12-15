// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2Comptroller } from "../src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupDynamic } from "../src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "../src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "../src/interfaces/ISablierV2NFTDescriptor.sol";
import { SablierV2Comptroller } from "../src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "../src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "../src/SablierV2LockupLinear.sol";
import { SablierV2NFTDescriptor } from "../src/SablierV2NFTDescriptor.sol";

import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { GoodFlashLoanReceiver } from "./mocks/flash-loan/GoodFlashLoanReceiver.sol";
import { Noop } from "./mocks/Noop.sol";
import { GoodRecipient } from "./mocks/hooks/GoodRecipient.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { Events } from "./utils/Events.sol";
import { Fuzzers } from "./utils/Fuzzers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Calculations, Constants, DeployOptimized, Events, Fuzzers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller internal comptroller;
    ERC20 internal dai;
    Defaults internal defaults;
    GoodFlashLoanReceiver internal goodFlashLoanReceiver;
    GoodRecipient internal goodRecipient;
    ISablierV2LockupDynamic internal lockupDynamic;
    ISablierV2LockupLinear internal lockupLinear;
    ISablierV2NFTDescriptor internal nftDescriptor;
    Noop internal noop;
    ERC20MissingReturn internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new ERC20("Dai Stablecoin", "DAI");
        goodFlashLoanReceiver = new GoodFlashLoanReceiver();
        goodRecipient = new GoodRecipient();
        noop = new Noop();
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });
        vm.label({ account: address(goodFlashLoanReceiver), newLabel: "Good Flash Loan Receiver" });
        vm.label({ account: address(goodRecipient), newLabel: "Good Recipient" });
        vm.label({ account: address(nftDescriptor), newLabel: "NFT Descriptor" });
        vm.label({ account: address(noop), newLabel: "Noop" });
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

        // Warp to May 1, 2023 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp({ timestamp: MAY_1_2023 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all V2 Core contracts to spend assets from the Sender, Recipient, Alice and Eve.
    function approveProtocol() internal {
        changePrank({ msgSender: users.sender });
        dai.approve({ spender: address(lockupLinear), amount: MAX_UINT256 });
        dai.approve({ spender: address(lockupDynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });

        changePrank({ msgSender: users.recipient });
        dai.approve({ spender: address(lockupLinear), amount: MAX_UINT256 });
        dai.approve({ spender: address(lockupDynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });

        changePrank({ msgSender: users.alice });
        dai.approve({ spender: address(lockupLinear), amount: MAX_UINT256 });
        dai.approve({ spender: address(lockupDynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });

        changePrank({ msgSender: users.eve });
        dai.approve({ spender: address(lockupLinear), amount: MAX_UINT256 });
        dai.approve({ spender: address(lockupDynamic), amount: MAX_UINT256 });
        usdt.approve({ spender: address(lockupLinear), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockupDynamic), value: MAX_UINT256 });

        // Finally, change the active prank back to the Admin.
        changePrank({ msgSender: users.admin });
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        return user;
    }

    /// @dev Conditionally deploys V2 Core normally or from an optimized source compiled with `--via-ir`.
    /// We cannot use the {DeployCore} script because some tests rely on hard coded addresses for the
    /// deployed contracts. Since the script itself would have to be deployed, using it would bump the
    /// deployer's nonce, which would in turn lead to different addresses (recall that the addresses
    /// for contracts deployed via `CREATE` are based on the caller-and-nonce-hash).
    function deployCoreConditionally() internal {
        if (!isTestOptimizedProfile()) {
            comptroller = new SablierV2Comptroller(users.admin);
            nftDescriptor = new SablierV2NFTDescriptor();
            lockupDynamic =
                new SablierV2LockupDynamic(users.admin, comptroller, nftDescriptor, defaults.MAX_SEGMENT_COUNT());
            lockupLinear = new SablierV2LockupLinear(users.admin, comptroller, nftDescriptor);
        } else {
            (comptroller, lockupDynamic, lockupLinear, nftDescriptor) =
                deployOptimizedCore(users.admin, defaults.MAX_SEGMENT_COUNT());
        }

        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(lockupDynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(lockupLinear), newLabel: "LockupLinear" });
        vm.label({ account: address(nftDescriptor), newLabel: "NFTDescriptor" });
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
