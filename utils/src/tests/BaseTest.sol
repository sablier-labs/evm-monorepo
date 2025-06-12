// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommonBase as StdBase } from "forge-std/src/Base.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { StdStyle } from "forge-std/src/StdStyle.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { IRoleAdminable } from "../interfaces/IRoleAdminable.sol";
import { ISablierComptroller } from "../interfaces/ISablierComptroller.sol";
import { ChainlinkOracleMock } from "../mocks/ChainlinkMocks.sol";
import { ERC20MissingReturn } from "../mocks/erc20/ERC20MissingReturn.sol";
import { ERC20Mock } from "../mocks/erc20/ERC20Mock.sol";
import { ContractWithoutReceive, ContractWithReceive } from "../mocks/Receive.sol";
import { SablierComptroller } from "../SablierComptroller.sol";

abstract contract BaseTest is StdBase, StdCheats, StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    uint256 internal constant AIRDROP_MIN_FEE_USD = 3e8; // equivalent to $3
    uint256 public constant AIRDROP_MIN_FEE_WEI = (1e18 * AIRDROP_MIN_FEE_USD) / 3000e8; // at $3000 per ETH
    uint256 internal constant AIRDROPS_CUSTOM_FEE_USD = 0.5e8; // equivalent to $0.5
    uint256 internal constant AIRDROPS_CUSTOM_FEE_WEI = (1e18 * AIRDROPS_CUSTOM_FEE_USD) / 3000e8; // at $3000 per ETH
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant FEE_MANAGEMENT_ROLE = keccak256("FEE_MANAGEMENT_ROLE");
    uint256 internal constant FLOW_MIN_FEE_USD = 1e8; // equivalent to $1
    uint256 internal constant FLOW_MIN_FEE_WEI = (1e18 * FLOW_MIN_FEE_USD) / 3000e8; // at $3000 per ETH
    uint256 internal constant FLOW_CUSTOM_FEE_USD = 0.1e8; // equivalent to $0.1
    uint256 internal constant FLOW_CUSTOM_FEE_WEI = (1e18 * FLOW_CUSTOM_FEE_USD) / 3000e8; // at $3000 per ETH
    uint256 internal constant LOCKUP_MIN_FEE_USD = 1e8; // equivalent to $1
    uint256 internal constant LOCKUP_MIN_FEE_WEI = (1e18 * LOCKUP_MIN_FEE_USD) / 3000e8; // at $3000 per ETH
    uint256 internal constant LOCKUP_CUSTOM_FEE_USD = 0.1e8; // equivalent to $0.1
    uint256 internal constant LOCKUP_CUSTOM_FEE_WEI = (1e18 * LOCKUP_CUSTOM_FEE_USD) / 3000e8; // at $3000 per ETH
    uint256 internal constant MAX_FEE_USD = 100e8; // equivalent to $100
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint64 internal constant MAX_UINT64 = type(uint64).max;
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    address internal admin;
    ISablierComptroller internal comptroller;
    ContractWithoutReceive internal contractWithoutReceive;
    ContractWithReceive internal contractWithReceive;
    ERC20Mock internal dai;
    ChainlinkOracleMock internal oracle;
    IERC20[] internal tokens;
    ERC20Mock internal usdc;
    ERC20MissingReturn internal usdt;

    /*//////////////////////////////////////////////////////////////////////////
                                        SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        contractWithoutReceive = new ContractWithoutReceive();
        contractWithReceive = new ContractWithReceive();

        // Create the admin user.
        admin = payable(makeAddr({ name: "Admin" }));
        vm.label(admin, "Admin");

        // Deploy the Sablier Comptroller.
        oracle = new ChainlinkOracleMock();
        comptroller =
            new SablierComptroller(admin, AIRDROP_MIN_FEE_USD, FLOW_MIN_FEE_USD, LOCKUP_MIN_FEE_USD, address(oracle));

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

    /// @dev Generates a user, labels its address, funds it with test tokens, approves `spenders` contracts and returns
    /// the user's address.
    function createUser(string memory name, address[] memory spenders) internal returns (address payable user) {
        user = payable(makeAddr(name));
        vm.label(user, name);
        vm.deal({ account: user, newBalance: 100 ether });

        dealAndApproveSpenders(user, spenders);
    }

    /// @dev Generates a user, labels its address, funds it with test tokens, approves `spenders` contracts and returns
    /// the user's address and the private key.
    function createUserAndKey(
        string memory name,
        address[] memory spenders
    )
        internal
        returns (address payable user, uint256 privateKey)
    {
        address addr;
        (addr, privateKey) = makeAddrAndKey(name);

        user = payable(addr);
        vm.label(user, name);
        vm.deal({ account: user, newBalance: 100 ether });

        dealAndApproveSpenders(user, spenders);
    }

    /// @dev Deals tokens to user and approve contracts from spenders list.
    function dealAndApproveSpenders(address user, address[] memory spenders) internal {
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
    }

    /// @dev Function to deploy the Sablier Comptroller with the given parameters.
    function deployComptroller(
        address admin_,
        uint256 airdropMinFeeUSD,
        uint256 flowMinFeeUSD,
        uint256 lockupMinFeeUSD,
        address oracle_
    )
        internal
        returns (address)
    {
        return address(new SablierComptroller(admin_, airdropMinFeeUSD, flowMinFeeUSD, lockupMinFeeUSD, oracle_));
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
        // solhint-disable-next-line no-console
        console2.log(StdStyle.blue(message));
    }

    /// @notice Logs a message in green color with a ✓ checkmark.
    /// @param message The message to log.
    function logGreen(string memory message) internal pure {
        // solhint-disable-next-line no-console
        console2.log(StdStyle.green(string.concat(unicode"✓ ", message)));
    }

    /// @dev Stops the active prank and sets a new one.
    function setMsgSender(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);

        // Deal some ETH to the new caller.
        vm.deal(msgSender, 1 ether);
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
