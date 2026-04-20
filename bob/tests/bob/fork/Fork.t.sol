// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Minimal interface for calling `finalize` on Lido's WithdrawalQueue in fork tests.
/// @dev The FINALIZE_ROLE is held by the stETH contract on mainnet.
interface IWithdrawalQueueFinalize {
    function finalize(uint256 _lastRequestIdToBeFinalized, uint256 _maxShareRate) external payable;
    function prefinalize(
        uint256[] calldata _batches,
        uint256 _maxShareRate
    )
        external
        view
        returns (uint256 ethToLock, uint256 sharesToBurn);
}

/// @notice Base logic needed by the Bob fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 MAINNET ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    IWETH9 internal constant FORK_WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address internal constant FORK_STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant FORK_WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant FORK_CURVE_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address internal constant FORK_LIDO_WITHDRAWAL_QUEUE = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;

    /// @dev Chainlink ETH/USD price feed on Ethereum mainnet.
    AggregatorV3Interface internal constant FORK_ETH_USD_ORACLE =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /// @dev Chainlink stETH/ETH price feed on Ethereum mainnet.
    address internal constant FORK_STETH_ETH_ORACLE = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBob internal forkBob;
    ISablierLidoAdapter internal forkAdapter;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at the latest block number.
        vm.createSelectFork({ urlOrAlias: "ethereum" });

        // Load deployed contracts from Ethereum mainnet.
        forkBob = ISablierBob(0xC8AB7E45E6DF99596b86870c26C25c721eB5C9af);
        forkAdapter = ISablierLidoAdapter(0x40c564A59bB2f1544222D6848E3eEc1Cb68837E6);
        comptroller = ISablierComptroller(0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399);

        // Create test user.
        address[] memory spenders = new address[](1);
        spenders[0] = address(forkBob);
        users.depositor = createUser("Depositor", spenders);

        // Label the mainnet addresses.
        labelForkedToken(FORK_WETH);
        vm.label(FORK_STETH, "stETH");
        vm.label(FORK_WSTETH, "wstETH");
        vm.label(FORK_CURVE_POOL, "CurvePool");
        vm.label(FORK_LIDO_WITHDRAWAL_QUEUE, "LidoWithdrawalQueue");
        vm.label(address(FORK_ETH_USD_ORACLE), "ETH/USD Oracle");
        vm.label(FORK_STETH_ETH_ORACLE, "stETH/ETH Oracle");
        vm.label(address(forkBob), "SablierBob");
        vm.label(address(forkAdapter), "SablierLidoAdapter");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Finalizes pending Lido withdrawals by impersonating the stETH contract (FINALIZE_ROLE holder).
    /// Queries the exact ETH needed via `prefinalize` to avoid TooMuchEtherToFinalize reverts.
    function _finalizeLidoWithdrawals(uint256 vaultId) internal {
        uint256[] memory requestIds = forkAdapter.getLidoWithdrawalRequestIds(vaultId);
        uint256 lastRequestId = requestIds[requestIds.length - 1];

        // Query the exact ETH needed for finalization.
        uint256[] memory batches = new uint256[](1);
        batches[0] = lastRequestId;
        (uint256 ethToLock,) =
            IWithdrawalQueueFinalize(FORK_LIDO_WITHDRAWAL_QUEUE).prefinalize(batches, type(uint256).max);

        // Stop any ongoing prank before impersonating stETH.
        vm.stopPrank();

        // Fund the stETH contract with enough ETH to cover the withdrawal and impersonate it.
        vm.deal(FORK_STETH, address(FORK_STETH).balance + ethToLock);
        vm.prank(FORK_STETH);
        IWithdrawalQueueFinalize(FORK_LIDO_WITHDRAWAL_QUEUE).finalize{ value: ethToLock }(
            lastRequestId, type(uint256).max
        );
    }
}
