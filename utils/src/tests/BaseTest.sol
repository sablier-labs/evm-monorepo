// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommonBase as StdBase } from "forge-std/src/Base.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdStyle } from "forge-std/src/StdStyle.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";
import { IRoleAdminable } from "src/interfaces/IRoleAdminable.sol";

import { ERC20MissingReturn } from "../mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "../mocks/erc20/ERC20Mock.sol";
import { ContractWithoutReceive, ContractWithReceive } from "../mocks/Receive.sol";

contract BaseTest is StdBase, StdCheats, StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    uint256 internal constant FEE = 0.001e18;
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant FEE_MANAGEMENT_ROLE = keccak256("FEE_MANAGEMENT_ROLE");
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

    /*//////////////////////////////////////////////////////////////////////////
                                        SETUP
    //////////////////////////////////////////////////////////////////////////*/

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
        vm.label(address(contractWithReceive), "Contract with Receive");
        vm.label(address(dai), "DAI");
        vm.label(address(usdc), "USDC");
        vm.label(address(usdt), "USDT");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approve `spender` to spend tokens from `from`.
    function approveContract(address token_, address from, address spender) internal {
        vm.stopPrank();
        vm.startPrank(from);
        (bool success,) = token_.call(abi.encodeCall(IERC20.approve, (spender, UINT256_MAX)));
        success;
    }

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
        vm.label(user, name);
        vm.deal({ account: user, newBalance: 100 ether });

        for (uint256 i = 0; i < spenders.length; ++i) {
            for (uint256 j = 0; j < tokens.length; ++j) {
                deal({
                    token: address(tokens[j]),
                    to: user,
                    give: 1e10 * (10 ** ERC20Mock(address(tokens[j])).decimals())
                });
                approveContract(address(tokens[j]), user, spenders[i]);
            }
        }

        return user;
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }

    /// @dev Authorize `account` to take admin actions on `target` contract.
    function grantAllRoles(address account, address target) internal {
        IRoleAdminable(target).grantRole(FEE_COLLECTOR_ROLE, account);
        IRoleAdminable(target).grantRole(FEE_MANAGEMENT_ROLE, account);
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal view returns (bool) {
        string memory profile = vm.envOr({ name: "FOUNDRY_PROFILE", defaultValue: string("default") });
        return Strings.equal(profile, "test-optimized");
    }

    /// @notice Logs a message in blue color.
    /// @param message The message to log.
    function logBlue(string memory message) internal pure {
        console2.log(StdStyle.blue(message));
    }

    /// @notice Logs a message in green color with a ✓ checkmark.
    /// @param message The message to log.
    function logGreen(string memory message) internal pure {
        console2.log(StdStyle.green(string.concat(unicode"✓ ", message)));
    }

    /// @dev Stops the active prank and sets a new one.
    function setMsgSender(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }

    /// @dev Forks the Ethereum Mainnet at the latest block and reverts if the environment variable is not set or the
    /// rpc endpoint is not valid.
    function setUpForkMainnet() internal {
        setUpFork("mainnet", 1);
    }

    /// @dev Forks the `chainName` at the latest block and reverts if the environment variable is not set or the
    /// rpc endpoint is not valid.
    function setUpFork(string memory chainName, uint256 chainId) internal {
        vm.createSelectFork({ urlOrAlias: chainName });
        require(
            block.chainid == chainId,
            string.concat(
                "Provided chain ID does not match the forked chain ",
                chainName,
                " Update your RPC URL in .env or pass the correct chainId."
            )
        );
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
