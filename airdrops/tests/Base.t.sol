// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { LockupNFTDescriptor } from "@sablier/lockup/src/LockupNFTDescriptor.sol";
import { SablierLockup } from "@sablier/lockup/src/SablierLockup.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleFactoryLL } from "src/interfaces/ISablierMerkleFactoryLL.sol";
import { ISablierMerkleFactoryLT } from "src/interfaces/ISablierMerkleFactoryLT.sol";
import { ISablierMerkleFactoryVCA } from "src/interfaces/ISablierMerkleFactoryVCA.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";
import { SablierMerkleFactoryLL } from "src/SablierMerkleFactoryLL.sol";
import { SablierMerkleFactoryLT } from "src/SablierMerkleFactoryLT.sol";
import { SablierMerkleFactoryVCA } from "src/SablierMerkleFactoryVCA.sol";
import { SablierMerkleInstant } from "src/SablierMerkleInstant.sol";
import { SablierMerkleLL } from "src/SablierMerkleLL.sol";
import { SablierMerkleLT } from "src/SablierMerkleLT.sol";
import { SablierMerkleVCA } from "src/SablierMerkleVCA.sol";
import { MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "src/types/DataTypes.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Constants } from "./utils/Constants.sol";
import { Defaults } from "./utils/Defaults.sol";
import { DeployOptimized } from "./utils/DeployOptimized.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Constants, DeployOptimized, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20Mock internal dai;
    Defaults internal defaults;
    ISablierLockup internal lockup;
    ISablierMerkleFactoryInstant internal merkleFactoryInstant;
    ISablierMerkleFactoryLL internal merkleFactoryLL;
    ISablierMerkleFactoryLT internal merkleFactoryLT;
    ISablierMerkleFactoryVCA internal merkleFactoryVCA;
    ISablierMerkleInstant internal merkleInstant;
    ISablierMerkleLL internal merkleLL;
    ISablierMerkleLT internal merkleLT;
    ISablierMerkleVCA internal merkleVCA;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Deploy the base test contracts.
        dai = new ERC20Mock("Dai Stablecoin", "DAI");

        // Label the base test contracts.
        vm.label({ account: address(dai), newLabel: "DAI" });

        // Create the protocol admin.
        users.admin = payable(makeAddr({ name: "Admin" }));
        vm.startPrank({ msgSender: users.admin });

        // Deploy the defaults contract.
        defaults = new Defaults();

        // Deploy the Lockup contract.
        LockupNFTDescriptor nftDescriptor = new LockupNFTDescriptor();
        lockup = new SablierLockup(users.admin, nftDescriptor, 1000);

        // Deploy the Merkle Factory contracts.
        deployMerkleFactoriesConditionally();

        // Create users for testing.
        users.campaignOwner = createUser("CampaignOwner");
        users.eve = createUser("Eve");
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

        // Set sender as the default caller for the tests.
        resetPrank({ msgSender: users.sender });

        // Warp to July 1, 2024 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: JULY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all contracts to spend tokens from the address passed.
    function approveFactories(address from) internal {
        resetPrank({ msgSender: from });
        dai.approve({ spender: address(merkleFactoryInstant), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactoryLL), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactoryLT), value: MAX_UINT256 });
        dai.approve({ spender: address(merkleFactoryVCA), value: MAX_UINT256 });
    }

    /// @dev Generates a user, labels its address, funds it with test tokens, and approves the protocol contracts.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        approveFactories({ from: user });
        return user;
    }

    /// @dev Deploys the Merkle Factory contracts conditionally based on the test profile.
    function deployMerkleFactoriesConditionally() internal {
        if (!isTestOptimizedProfile()) {
            merkleFactoryInstant = new SablierMerkleFactoryInstant(users.admin, defaults.MINIMUM_FEE());
            merkleFactoryLL = new SablierMerkleFactoryLL(users.admin, defaults.MINIMUM_FEE());
            merkleFactoryLT = new SablierMerkleFactoryLT(users.admin, defaults.MINIMUM_FEE());
            merkleFactoryVCA = new SablierMerkleFactoryVCA(users.admin, defaults.MINIMUM_FEE());
        } else {
            (merkleFactoryInstant, merkleFactoryLL, merkleFactoryLT, merkleFactoryVCA) =
                deployOptimizedMerkleFactories(users.admin, defaults.MINIMUM_FEE());
        }
        vm.label({ account: address(merkleFactoryInstant), newLabel: "MerkleFactoryInstant" });
        vm.label({ account: address(merkleFactoryLL), newLabel: "MerkleFactoryLL" });
        vm.label({ account: address(merkleFactoryLT), newLabel: "MerkleFactoryLT" });
        vm.label({ account: address(merkleFactoryVCA), newLabel: "MerkleFactoryVCA" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CALL EXPECTS - IERC20
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 token, address to, uint256 value) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transfer, (to, value)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CALL EXPECTS - MERKLE LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {ISablierMerkleBase.claim} with data provided.
    function expectCallToClaimWithData(
        address merkleLockup,
        uint256 fee,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
    {
        vm.expectCall(
            merkleLockup, fee, abi.encodeCall(ISablierMerkleBase.claim, (index, recipient, amount, merkleProof))
        );
    }

    /// @dev Expects a call to {ISablierMerkleBase.claim} with msgValue as `msg.value`.
    function expectCallToClaimWithMsgValue(address merkleLockup, uint256 msgValue) internal {
        vm.expectCall(
            merkleLockup,
            msgValue,
            abi.encodeCall(
                ISablierMerkleBase.claim,
                (defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof())
            )
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPERS - MERKLE LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function computeMerkleInstantAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleInstant.ConstructorParams memory params = defaults.merkleInstantConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: merkleRoot,
            token_: token_
        });

        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));
        bytes32 creationBytecodeHash;

        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleInstant).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleInstant.sol/SablierMerkleInstant.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryInstant)
        });
    }

    function computeMerkleLLAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleLL.ConstructorParams memory params = defaults.merkleLLConstructorParams({
            campaignOwner: campaignOwner,
            lockup: lockup,
            expiration: expiration,
            merkleRoot: merkleRoot,
            token_: token_
        });
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLL).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLL.sol/SablierMerkleLL.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryLL)
        });
    }

    function computeMerkleLTAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleLT.ConstructorParams memory params = defaults.merkleLTConstructorParams({
            campaignOwner: campaignOwner,
            lockup: lockup,
            expiration: expiration,
            merkleRoot: merkleRoot,
            token_: token_
        });
        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleLT).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleLT.sol/SablierMerkleLT.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }

        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryLT)
        });
    }

    function computeMerkleVCAAddress(
        address campaignCreator,
        address campaignOwner,
        uint40 expiration,
        bytes32 merkleRoot,
        MerkleVCA.Timestamps memory timestamps,
        IERC20 token_
    )
        internal
        view
        returns (address)
    {
        MerkleVCA.ConstructorParams memory params = defaults.merkleVCAConstructorParams({
            campaignOwner: campaignOwner,
            expiration: expiration,
            merkleRoot: merkleRoot,
            timestamps: timestamps,
            token_: token_
        });

        bytes32 salt = keccak256(abi.encodePacked(campaignCreator, abi.encode(params)));

        bytes32 creationBytecodeHash;
        if (!isTestOptimizedProfile()) {
            creationBytecodeHash =
                keccak256(bytes.concat(type(SablierMerkleVCA).creationCode, abi.encode(params, campaignCreator)));
        } else {
            creationBytecodeHash = keccak256(
                bytes.concat(
                    vm.getCode("out-optimized/SablierMerkleVCA.sol/SablierMerkleVCA.json"),
                    abi.encode(params, campaignCreator)
                )
            );
        }
        return vm.computeCreate2Address({
            salt: salt,
            initCodeHash: creationBytecodeHash,
            deployer: address(merkleFactoryVCA)
        });
    }
}
