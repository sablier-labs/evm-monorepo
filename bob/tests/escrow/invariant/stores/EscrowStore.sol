// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Storage contract that tracks escrow order state for invariant assertions.
contract EscrowStore {
    /*//////////////////////////////////////////////////////////////////////////
                                       TYPES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Data captured from each successful `fillOrder` call.
    struct FillData {
        uint128 buyAmount;
        uint128 amountToTransferToSeller;
        uint128 amountToTransferToBuyer;
        uint128 feeDeductedFromBuyerAmount;
        uint128 feeDeductedFromSellerAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Array of all created order IDs.
    uint256[] public orderIds;

    /// @dev Array of ERC-20 tokens created during the campaign.
    IERC20[] public tokens;

    /// @dev Maps order ID to its fill data.
    mapping(uint256 orderId => FillData) internal _fillData;

    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getFillData(uint256 orderId) external view returns (FillData memory) {
        return _fillData[orderId];
    }

    /// @dev Records a newly created order.
    function pushOrderId(uint256 orderId) external {
        orderIds.push(orderId);
    }

    /// @dev Adds a newly created token to the store.
    function pushToken(IERC20 token) external {
        tokens.push(token);
    }

    /// @dev Records the fill data from a successful `fillOrder` call.
    function recordFill(uint256 orderId, FillData calldata data) external {
        _fillData[orderId] = data;
    }

    function totalOrders() external view returns (uint256) {
        return orderIds.length;
    }

    function totalTokens() external view returns (uint256) {
        return tokens.length;
    }
}
