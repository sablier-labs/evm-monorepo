// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILockupNFTDescriptor } from "src/core/interfaces/ILockupNFTDescriptor.sol";
import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "src/core/LockupNFTDescriptor.sol";
import { SablierLockup } from "src/core/SablierLockup.sol";
import { ISablierBatchLockup } from "src/periphery/interfaces/ISablierBatchLockup.sol";
import { ISablierMerkleFactory } from "src/periphery/interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "src/periphery/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/periphery/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/periphery/interfaces/ISablierMerkleLT.sol";
import { SablierBatchLockup } from "src/periphery/SablierBatchLockup.sol";
import { SablierMerkleFactory } from "src/periphery/SablierMerkleFactory.sol";

import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { RecipientGood } from "./mocks/Hooks.sol";
import { Noop } from "./mocks/Noop.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Calculations } from "./utils/Calculations.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Calculations, DeployOptimized, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBatchLockup internal batchLockup;
    ERC20Mock internal dai;
    Defaults internal defaults;
    ISablierLockup internal lockup;
    ISablierMerkleFactory internal merkleFactory;
    ISablierMerkleInstant internal merkleInstant;
    ISablierMerkleLL internal merkleLL;
    ISablierMerkleLT internal merkleLT;
    ILockupNFTDescriptor internal nftDescriptor;
    Noop internal noop;
    RecipientGood internal recipientGood;
    ERC20MissingReturn internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new ERC20Mock("Dai Stablecoin", "DAI");
        recipientGood = new RecipientGood();
        noop = new Noop();
        usdt = new ERC20MissingReturn("Tether USD", "USDT", 6);

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });
        vm.label({ account: address(recipientGood), newLabel: "Good Recipient" });
        vm.label({ account: address(noop), newLabel: "Noop" });
        vm.label({ account: address(usdt), newLabel: "USDT" });

        // Create the protocol admin.
        users.admin = payable(makeAddr({ name: "Admin" }));
        vm.startPrank({ msgSender: users.admin });

        // Deploy the defaults contract.
        defaults = new Defaults();
        defaults.setAsset(dai);

        // Deploy the protocol.
        deployProtocolConditionally();

        // Set the Sablier fee on the Merkle factory.
        merkleFactory.setDefaultSablierFee(defaults.DEFAULT_SABLIER_FEE());

        // Create users for testing.
        users.alice = createUser("Alice");
        users.broker = createUser("Broker");
        users.campaignOwner = createUser("CampaignOwner");
        users.eve = createUser("Eve");
        users.operator = createUser("Operator");
        users.recipient = createUser("Recipient");
        users.recipient1 = createUser("Recipient1");
        users.recipient2 = createUser("Recipient2");
        users.recipient3 = createUser("Recipient3");
        users.recipient4 = createUser("Recipient4");
        users.sender = createUser("Sender");

        defaults.setUsers(users);
        defaults.initMerkleTree();

        // Set the variables in Modifiers contract.
        setVariables(defaults, users);

        // Approve `users.operator` to operate over lockup on behalf of the `users.recipient`.
        resetPrank({ msgSender: users.recipient });
        lockup.setApprovalForAll(users.operator, true);

        // Set sender as the default caller for the tests.
        resetPrank({ msgSender: users.sender });

        // Warp to July 1, 2024 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: JULY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve `spender` to spend assets from `from`.
    function approveContract(IERC20 asset_, address from, address spender) internal {
        resetPrank({ msgSender: from });
        (bool success,) = address(asset_).call(abi.encodeCall(IERC20.approve, (spender, MAX_UINT256)));
        success;
    }

    /// @dev Approves all contracts to spend assets from the address passed.
    function approveProtocol(address from) internal {
        resetPrank({ msgSender: from });
        dai.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        dai.approve({ spender: address(lockup), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactory), value: MAX_UINT256 });
        usdt.approve({ spender: address(batchLockup), value: MAX_UINT256 });
        usdt.approve({ spender: address(lockup), value: MAX_UINT256 });
        usdt.approve({ spender: address(merkleFactory), value: MAX_UINT256 });
    }

    /// @dev Generates a user, labels its address, funds it with test assets, and approves the protocol contracts.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        approveProtocol({ from: user });
        return user;
    }

    /// @dev Conditionally deploys the protocol normally or from an optimized source compiled with `--via-ir`.
    /// We cannot use the {DeployProtocol} script because some tests rely on hard coded addresses for the
    /// deployed contracts. Since the script itself would have to be deployed, using it would bump the
    /// deployer's nonce, which would in turn lead to different addresses (recall that the addresses
    /// for contracts deployed via `CREATE` are based on the caller-and-nonce-hash).
    function deployProtocolConditionally() internal {
        if (!isBenchmarkProfile() && !isTestOptimizedProfile()) {
            batchLockup = new SablierBatchLockup();
            nftDescriptor = new LockupNFTDescriptor();
            lockup = new SablierLockup(users.admin, nftDescriptor, defaults.MAX_COUNT());
            merkleFactory = new SablierMerkleFactory(users.admin);
        } else {
            (nftDescriptor, lockup, batchLockup, merkleFactory) =
                deployOptimizedProtocol(users.admin, defaults.MAX_COUNT());
        }
        vm.label({ account: address(batchLockup), newLabel: "BatchLockup" });
        vm.label({ account: address(lockup), newLabel: "Lockup" });
        vm.label({ account: address(merkleFactory), newLabel: "MerkleFactory" });
        vm.label({ account: address(nftDescriptor), newLabel: "NFTDescriptor" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - IERC20
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 asset, address to, uint256 value) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 asset, address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /// @dev Expects multiple calls to {IERC20.transfer}.
    function expectMultipleCallsToTransfer(uint64 count, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), count: count, data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects multiple calls to {IERC20.transferFrom}.
    function expectMultipleCallsToTransferFrom(uint64 count, address from, address to, uint256 value) internal {
        expectMultipleCallsToTransferFrom(dai, count, from, to, value);
    }

    /// @dev Expects multiple calls to {IERC20.transferFrom}.
    function expectMultipleCallsToTransferFrom(
        IERC20 asset,
        uint64 count,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        vm.expectCall({
            callee: address(asset),
            count: count,
            data: abi.encodeCall(IERC20.transferFrom, (from, to, value))
        });
    }
}
