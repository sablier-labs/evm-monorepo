// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommonBase as StdBase } from "forge-std/src/Base.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { ERC20MissingReturn } from "../mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "../mocks/erc20/ERC20Mock.sol";
import { ContractWithoutReceive, ContractWithReceive } from "../mocks/Receive.sol";

contract BaseTest is StdBase, StdCheats, StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant FEE = 0.001e18;
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint64 internal constant MAX_UINT64 = type(uint64).max;
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ContractWithoutReceive internal contractWithoutReceive;
    ContractWithReceive internal contractWithReceive;
    ERC20Mock internal dai;
    IERC20[] internal tokens;
    ERC20Mock internal usdc;
    ERC20MissingReturn internal usdt;

    function setUp() public virtual {
        contractWithoutReceive = new ContractWithoutReceive();
        contractWithReceive = new ContractWithReceive();

        // Deploy the tokens.
        dai = new ERC20Mock("Dai stablecoin", "DAI", 18);
        usdc = new ERC20Mock("USD Coin", "USDC", 6);
        usdt = new ERC20MissingReturn("Tether", "USDT", 6);

        // Push in the tokens array.
        tokens.push(dai);
        tokens.push(usdc);
        tokens.push(IERC20(address(usdt)));

        // Label the tokens.
        vm.label(address(contractWithoutReceive), "Contract without Receive");
        vm.label(address(contractWithoutReceive), "Contract with Receive");
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

    /// @dev Generates a user, label its address, funds it with test tokens and approve `spenders` contracts.
    function createUser(string memory name, address[] memory spenders) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.label(user, "name");
        vm.deal({ account: user, newBalance: 100 ether });

        for (uint256 i = 0; i < spenders.length; ++i) {
            for (uint256 j = 0; j < tokens.length; ++j) {
                deal({ token: address(tokens[j]), to: user, give: 1e10 * ERC20Mock(address(tokens[j])).decimals() });
                approveContract(address(tokens[j]), user, spenders[i]);
            }
        }

        return user;
    }

    /// @dev Approve `spender` to spend tokens from `from`.
    function approveContract(address token_, address from, address spender) internal {
        vm.stopPrank();
        vm.startPrank(from);
        (bool success,) = token_.call(abi.encodeCall(IERC20.approve, (spender, UINT256_MAX)));
        success;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CALL EXPECTS
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

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        vm.expectCall({ callee: address(token), data: abi.encodeCall(IERC20.transferFrom, (from, to, value)) });
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
        IERC20 token,
        uint64 count,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        vm.expectCall({
            callee: address(token),
            count: count,
            data: abi.encodeCall(IERC20.transferFrom, (from, to, value))
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds a `uint128` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal pure returns (uint128) {
        return uint128(_bound(x, min, max));
    }

    /// @dev Bounds a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal pure returns (uint40) {
        return uint40(_bound(x, min, max));
    }

    /// @dev Bounds a `uint64` number.
    function boundUint64(uint64 x, uint64 min, uint64 max) internal pure returns (uint64) {
        return uint64(_bound(x, min, max));
    }

    /// @dev Bounds a `uint8` number.
    function boundUint8(uint8 x, uint8 min, uint8 max) internal pure returns (uint8) {
        return uint8(_bound(x, min, max));
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal view returns (bool) {
        string memory profile = vm.envOr({ name: "FOUNDRY_PROFILE", defaultValue: string("default") });
        return Strings.equal(profile, "test-optimized");
    }

    /// @dev Stops the active prank and sets a new one.
    function resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }
}
