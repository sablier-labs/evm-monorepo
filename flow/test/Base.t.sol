// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Test } from "forge-std/src/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SablierFlow } from "src/SablierFlow.sol";
import { SablierFlowNFTDescriptor } from "src/SablierFlowNFTDescriptor.sol";

import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { ERC20MissingReturn } from "./mocks/ERC20MissingReturn.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Events } from "./utils/Events.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";

abstract contract Base_Test is Assertions, Events, Modifiers, Test, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20Mock internal assetWithoutDecimals = createAsset("Asset without decimals", "AWD", 0);
    ERC20Mock internal dai = createAsset("Dai stablecoin", "DAI", 18);
    ERC20Mock internal usdc = createAsset("USD Coin", "USDC", 6);
    ERC20MissingReturn internal usdt = new ERC20MissingReturn("USDT stablecoin", "USDT", 6);

    SablierFlow internal flow;
    SablierFlowNFTDescriptor internal nftDescriptor;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        users.admin = payable(makeAddr("admin"));

        if (!isTestOptimizedProfile()) {
            nftDescriptor = new SablierFlowNFTDescriptor();
            flow = new SablierFlow(users.admin, nftDescriptor);
        } else {
            flow = deployOptimizedSablierFlow();
        }

        // Label the flow contract.
        vm.label(address(flow), "Flow");

        // Create new assets and label them.
        createAndLabelAssets();

        // Create the users.
        users.broker = createUser("broker");
        users.eve = createUser("eve");
        users.operator = createUser("operator");
        users.recipient = createUser("recipient");
        users.sender = createUser("sender");

        resetPrank(users.sender);

        // Warp to May 1, 2024 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp({ newTimestamp: MAY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create new assets and label them.
    function createAndLabelAssets() internal {
        // Deploy the assets.
        assetWithoutDecimals = createAsset("Asset without decimals", "AWD", 0);
        dai = createAsset("Dai stablecoin", "DAI", 18);
        usdc = createAsset("USD Coin", "USDC", 6);
        usdt = new ERC20MissingReturn("USDT stablecoin", "USDT", 6);

        // Label the assets.
        vm.label(address(assetWithoutDecimals), "AWD");
        vm.label(address(dai), "DAI");
        vm.label(address(usdc), "USDC");
        vm.label(address(usdt), "USDT");
    }

    /// @dev Creates a new ERC20 asset with `decimals`.
    function createAsset(uint8 decimals) internal returns (ERC20Mock) {
        return createAsset("", "", decimals);
    }

    /// @dev Creates a new ERC20 asset with `name`, `symbol` and `decimals`.
    function createAsset(string memory name, string memory symbol, uint8 decimals) internal returns (ERC20Mock) {
        return new ERC20Mock(name, symbol, decimals);
    }

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(assetWithoutDecimals), to: user, give: 1_000_000 });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdc), to: user, give: 1_000_000e6 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        resetPrank(user);
        dai.approve({ spender: address(flow), value: UINT256_MAX });
        usdc.approve({ spender: address(flow), value: UINT256_MAX });
        usdt.approve({ spender: address(flow), value: UINT256_MAX });
        return user;
    }

    /// @dev Deploys {SablierFlow} from an optimized source compiled with `--via-ir`.
    function deployOptimizedSablierFlow() internal returns (SablierFlow) {
        nftDescriptor = SablierFlowNFTDescriptor(
            deployCode("out-optimized/SablierFlowNFTDescriptor.sol/SablierFlowNFTDescriptor.json")
        );

        return SablierFlow(
            deployCode(
                "out-optimized/SablierFlow.sol/SablierFlow.json", abi.encode(users.admin, address(nftDescriptor))
            )
        );
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
