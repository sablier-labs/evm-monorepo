// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Test } from "forge-std/src/Test.sol";
import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { SablierFlow } from "src/SablierFlow.sol";
import { ERC20MissingReturn } from "./mocks/ERC20MissingReturn.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";
import { Vars } from "./utils/Vars.sol";

abstract contract Base_Test is Assertions, Modifiers, Test, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;
    Vars internal vars;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20Mock internal tokenWithoutDecimals;
    ERC20Mock internal tokenWithProtocolFee;
    ERC20Mock internal dai;
    ERC20Mock internal usdc;
    ERC20MissingReturn internal usdt;

    SablierFlow internal flow;
    FlowNFTDescriptor internal nftDescriptor;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        users.admin = payable(makeAddr("admin"));

        if (!isBenchmarkProfile() && !isTestOptimizedProfile()) {
            nftDescriptor = new FlowNFTDescriptor();
            flow = new SablierFlow(users.admin, nftDescriptor);
        } else {
            flow = deployOptimizedSablierFlow();
        }

        // Label the flow contract.
        vm.label(address(flow), "Flow");

        // Create new tokens and label them.
        createAndLabelTokens();

        // Turn on the protocol fee for tokenWithProtocolFee.
        resetPrank(users.admin);
        flow.setProtocolFee(tokenWithProtocolFee, PROTOCOL_FEE);

        // Create the users.
        users.broker = createUser("broker");
        users.eve = createUser("eve");
        users.operator = createUser("operator");
        users.recipient = createUser("recipient");
        users.sender = createUser("sender");

        resetPrank(users.sender);

        // Warp to May 1, 2024 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp({ newTimestamp: OCT_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create new tokens and label them.
    function createAndLabelTokens() internal {
        // Deploy the tokens.
        tokenWithoutDecimals = createToken("Token without Decimals", "TWD", 0);
        tokenWithProtocolFee = createToken("Token with Protocol Fee", "TPF", 6);
        dai = createToken("Dai stablecoin", "DAI", 18);
        usdc = createToken("USD Coin", "USDC", 6);
        usdt = new ERC20MissingReturn("Tether", "USDT", 6);

        // Label the tokens.
        vm.label(address(tokenWithoutDecimals), "TWD");
        vm.label(address(tokenWithProtocolFee), "TPF");
        vm.label(address(dai), "DAI");
        vm.label(address(usdc), "USDC");
        vm.label(address(usdt), "USDT");
    }

    /// @dev Creates a new ERC-20 token with `decimals`.
    function createToken(uint8 decimals) internal returns (ERC20Mock) {
        return createToken("", "", decimals);
    }

    /// @dev Creates a new ERC-20 token with `name`, `symbol` and `decimals`.
    function createToken(string memory name, string memory symbol, uint8 decimals) internal returns (ERC20Mock) {
        return new ERC20Mock(name, symbol, decimals);
    }

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(tokenWithoutDecimals), to: user, give: 1_000_000 });
        deal({ token: address(tokenWithProtocolFee), to: user, give: 1_000_000e6 });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdc), to: user, give: 1_000_000e6 });
        deal({ token: address(usdt), to: user, give: 1_000_000e6 });
        resetPrank(user);
        dai.approve({ spender: address(flow), value: UINT256_MAX });
        usdc.approve({ spender: address(flow), value: UINT256_MAX });
        usdt.approve({ spender: address(flow), value: UINT256_MAX });
        return user;
    }

    /// @dev Deploys {SablierFlow} from an optimized source compiled with `--via-ir`.
    function deployOptimizedSablierFlow() internal returns (SablierFlow) {
        nftDescriptor = FlowNFTDescriptor(deployCode("out-optimized/FlowNFTDescriptor.sol/FlowNFTDescriptor.json"));

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
    function expectCallToTransfer(IERC20 token, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(dai), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }
}
