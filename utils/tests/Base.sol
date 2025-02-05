// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { CommonConstants } from "./utils/Constants.sol";
import { CommonUtils } from "./utils/Utils.sol";

import { ERC20MissingReturn } from "./mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "./mocks/erc20/ERC20Mock.sol";
import { ContractWithoutReceive, ContractWithReceive } from "./mocks/Receive.sol";

contract CommonBase is CommonConstants, CommonUtils, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ContractWithoutReceive internal contractWithoutReceive;
    ContractWithReceive internal contractWithReceive;
    ERC20Mock internal dai;
    address[] internal tokens;
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
        tokens.push(address(dai));
        tokens.push(address(usdc));
        tokens.push(address(usdt));

        // Label the tokens.
        vm.label({ account: address(contractWithoutReceive), newLabel: "Contract without Receive" });
        vm.label({ account: address(contractWithReceive), newLabel: "Contract with Receive" });
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

    /// @dev Generates a user, labels its address and funds it with test tokens.
    function createUser(string memory name, address[] memory spenders) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1e28 });
        deal({ token: address(usdt), to: user, give: 1e28 });
        deal({ token: address(usdc), to: user, give: 1e16 });

        for (uint256 i = 0; i < spenders.length; ++i) {
            for (uint256 j = 0; j < tokens.length; ++j) {
                approveContract(tokens[j], user, spenders[i]);
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
}
