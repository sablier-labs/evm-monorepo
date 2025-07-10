// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

abstract contract BaseConstants {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant ETH_PRICE_USD = 3000e8; // $3000 per ETH
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant FEE_MANAGEMENT_ROLE = keccak256("FEE_MANAGEMENT_ROLE");
    uint256 public constant MAX_FEE_USD = 100e8; // equivalent to $100
    uint128 public constant MAX_UINT128 = type(uint128).max;
    uint256 public constant MAX_UINT256 = type(uint256).max;
    uint40 public constant MAX_UINT40 = type(uint40).max;
    uint64 public constant MAX_UINT64 = type(uint64).max;
    uint40 public constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1

    /*//////////////////////////////////////////////////////////////////////////
                                      AIRDROPS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant AIRDROP_MIN_FEE_USD = 3e8; // equivalent to $3
    uint256 public constant AIRDROP_MIN_FEE_WEI = (1e18 * AIRDROP_MIN_FEE_USD) / ETH_PRICE_USD;

    /*//////////////////////////////////////////////////////////////////////////
                                        FLOW
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant FLOW_MIN_FEE_USD = 1e8; // equivalent to $1
    uint256 public constant FLOW_MIN_FEE_WEI = (1e18 * FLOW_MIN_FEE_USD) / ETH_PRICE_USD;

    /*//////////////////////////////////////////////////////////////////////////
                                       LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant LOCKUP_MIN_FEE_USD = 1e8; // equivalent to $1
    uint256 public constant LOCKUP_MIN_FEE_WEI = (1e18 * LOCKUP_MIN_FEE_USD) / ETH_PRICE_USD;

    /*//////////////////////////////////////////////////////////////////////////
                                      STAKING
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant STAKING_MIN_FEE_USD = 10e8; // equivalent to $10
    uint256 public constant STAKING_MIN_FEE_WEI = (1e18 * STAKING_MIN_FEE_USD) / ETH_PRICE_USD;
}
