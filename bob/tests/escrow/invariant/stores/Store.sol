// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Storage contract that tracks escrow order state for invariant assertions.
contract Store {
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

    /// @dev Data captured from each successful `cancelOrder` call.
    struct CancelData {
        uint256 orderId;
        uint128 sellAmount;
        uint256 sellerBalanceBefore;
        uint256 sellerBalanceAfter;
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

    /// @dev Records from each cancel call.
    CancelData[] internal _cancelRecords;

    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getFillData(uint256 orderId) external view returns (FillData memory) {
        return _fillData[orderId];
    }

    function orderCount() external view returns (uint256) {
        return orderIds.length;
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

    function tokensCount() external view returns (uint256) {
        return tokens.length;
    }

    function cancelRecordCount() external view returns (uint256) {
        return _cancelRecords.length;
    }

    function getCancelRecord(uint256 index) external view returns (CancelData memory) {
        return _cancelRecords[index];
    }

    /// @dev Records the cancel data from a successful `cancelOrder` call.
    function recordCancel(CancelData calldata data) external {
        _cancelRecords.push(data);
    }
}
