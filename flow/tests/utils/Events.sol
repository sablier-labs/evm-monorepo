// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

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
                                 SABLIER-FLOW-BASE
    //////////////////////////////////////////////////////////////////////////*/

    event CollectProtocolRevenue(address indexed admin, IERC20 indexed token, address to, uint128 revenue);

    event SetNFTDescriptor(
        address indexed admin, ISablierFlowNFTDescriptor oldNFTDescriptor, ISablierFlowNFTDescriptor newNFTDescriptor
    );

    event SetProtocolFee(address indexed admin, IERC20 indexed token, UD60x18 oldProtocolFee, UD60x18 newProtocolFee);

    /*//////////////////////////////////////////////////////////////////////////
                                    SABLIER-FLOW
    //////////////////////////////////////////////////////////////////////////*/

    event AdjustFlowStream(
        uint256 indexed streamId, uint128 totalDebt, UD21x18 oldRatePerSecond, UD21x18 newRatePerSecond
    );

    event CreateFlowStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        UD21x18 ratePerSecond,
        IERC20 indexed token,
        bool transferable
    );

    event DepositFlowStream(uint256 indexed streamId, address indexed funder, uint128 amount);

    event PauseFlowStream(
        uint256 indexed streamId, address indexed sender, address indexed recipient, uint128 totalDebt
    );

    event Recover(address indexed admin, IERC20 indexed token, address to, uint256 surplus);

    event RefundFromFlowStream(uint256 indexed streamId, address indexed sender, uint128 amount);

    event RestartFlowStream(uint256 indexed streamId, address indexed sender, UD21x18 ratePerSecond);

    event VoidFlowStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        address caller,
        uint128 newTotalDebt,
        uint128 writtenOffDebt
    );

    event WithdrawFromFlowStream(
        uint256 indexed streamId,
        address indexed to,
        IERC20 indexed token,
        address caller,
        uint128 withdrawAmount,
        uint128 protocolFeeAmount
    );
}
