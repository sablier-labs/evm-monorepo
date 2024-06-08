// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlowNFTDescriptor } from "../../src/interfaces/ISablierFlowNFTDescriptor.sol";

abstract contract Events {
    /*//////////////////////////////////////////////////////////////////////////
                                      ERC-721
    //////////////////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////////////////
                                      ERC-4906
    //////////////////////////////////////////////////////////////////////////*/

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    event MetadataUpdate(uint256 _tokenId);

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-FLOW-STATE
    //////////////////////////////////////////////////////////////////////////*/

    event SetNFTDescriptor(
        address indexed admin, ISablierFlowNFTDescriptor oldNFTDescriptor, ISablierFlowNFTDescriptor newNFTDescriptor
    );

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-FLOW
    //////////////////////////////////////////////////////////////////////////*/

    event AdjustFlowStream(
        uint256 indexed streamId, uint128 amountOwed, uint128 newRatePerSecond, uint128 oldRatePerSecond
    );

    event CreateFlowStream(
        uint256 indexed streamId,
        IERC20 indexed asset,
        address indexed sender,
        address recipient,
        uint40 lastTimeUpdate,
        uint128 ratePerSecond
    );

    event DepositFlowStream(uint256 indexed streamId, address indexed funder, uint128 depositAmount);

    event PauseFlowStream(uint256 indexed streamId, address recipient, address sender, uint128 amountOwed);

    event RefundFromFlowStream(uint256 indexed streamId, address indexed sender, uint128 refundAmount);

    event RestartFlowStream(uint256 indexed streamId, address sender, uint128 ratePerSecond);

    event WithdrawFromFlowStream(uint256 indexed streamId, address indexed to, uint128 withdrawnAmount);
}
