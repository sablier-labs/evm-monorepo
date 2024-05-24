// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Test } from "forge-std/src/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { SablierFlow } from "src/SablierFlow.sol";

import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { ERC20MissingReturn } from "./mocks/ERC20MissingReturn.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Constants } from "./utils/Constants.sol";
import { Events } from "./utils/Events.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";

abstract contract Base_Test is Assertions, Constants, Events, Modifiers, Test, Utils {
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20Mock internal assetWithoutDecimals = new ERC20Mock("Asset without decimals", "AWD", 0);
    ERC20Mock internal dai = new ERC20Mock("Dai stablecoin", "DAI", 18);
    SablierFlow internal flow;
    ERC20Mock internal usdc = new ERC20Mock("USD Coin", "USDC", 6);
    ERC20MissingReturn internal usdt = new ERC20MissingReturn("USDT stablecoin", "USDT", 6);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        if (!isTestOptimizedProfile()) {
            flow = new SablierFlow();
        } else {
            flow = deployOptimizedSablierFlow();
        }

        users.broker = createUser("broker");
        users.eve = createUser("eve");
        users.recipient = createUser("recipient");
        users.sender = createUser("sender");

        labelContracts();

        resetPrank(users.sender);

        // Warp to May 1, 2024 at 00:00 GMT to provide a more realistic testing environment.
        vm.warp({ newTimestamp: MAY_1_2024 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdc), to: user, give: 1_000_000e6 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        resetPrank(user);
        dai.approve({ spender: address(flow), value: type(uint256).max });
        usdc.approve({ spender: address(flow), value: type(uint256).max });
        usdt.approve({ spender: address(flow), value: type(uint256).max });
        return user;
    }

    /// @dev Deploys {SablierFlow} from an optimized source compiled with `--via-ir`.
    function deployOptimizedSablierFlow() internal returns (SablierFlow) {
        return SablierFlow(deployCode("out-optimized/SablierFlow.sol/SablierFlow.json"));
    }

    function labelContracts() internal {
        vm.label(address(dai), "DAI");
        vm.label(address(flow), "Flow");
        vm.label(address(usdt), "USDT");
    }

    /// @dev Normalizes `amount` to `decimals`.
    function normalizeAmountToDecimal(
        uint128 amount,
        uint8 decimals
    )
        internal
        pure
        returns (uint128 normalizedAmount)
    {
        // Return the original amount if it's already in the standard 18-decimal format.
        if (decimals == 18) {
            return amount;
        }

        bool isGreaterThan18 = decimals > 18;

        uint8 normalizationFactor = isGreaterThan18 ? decimals - 18 : 18 - decimals;

        normalizedAmount = isGreaterThan18
            ? (amount * (10 ** normalizationFactor)).toUint128()
            : (amount / (10 ** normalizationFactor)).toUint128();
    }

    /// @dev Normalizes `amount` to the decimal of `streamId` asset.
    function normalizeAmountWithStreamId(uint256 streamId, uint128 amount) internal view returns (uint256) {
        return normalizeAmountToDecimal(amount, flow.getAssetDecimals(streamId));
    }

    /// @dev Normalizes stream balance to the decimal of `streamId` asset.
    function normalizeStreamBalance(uint256 streamId) internal view returns (uint256) {
        return normalizeAmountToDecimal(flow.getBalance(streamId), flow.getAssetDecimals(streamId));
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
