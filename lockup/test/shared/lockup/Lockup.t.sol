// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2Config } from "../../../src/interfaces/ISablierV2Config.sol";
import { ISablierV2Lockup } from "../../../src/interfaces/ISablierV2Lockup.sol";
import { Broker } from "../../../src/types/DataTypes.sol";

import { Base_Test } from "test/Base.t.sol";

/// @title Lockup_Shared_Test
/// @dev There is a lot of common logic between the {SablierV2LockupLinear} and the {SablierV2LockupPro} contracts,
/// specifically that they both inherit from the {SablierV2Config} and the {SablierV2Lockup} abstract contracts. We
/// wrote this test contract to avoid duplicating tests.
abstract contract Lockup_Shared_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A test contract that is meant to be overridden by the child contract.
    /// This will be either the {SablierV2LockupLinear} or the {SablierV2LockupPro} contract.
    ISablierV2Config internal config;

    /// @dev A test contract that is meant to be overridden by the child contract.
    /// This will be either the {SablierV2LockupLinear} or the {SablierV2LockupPro} contract.
    ISablierV2Lockup internal lockup;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream but make it non-cancelable.
    function createDefaultStreamNonCancelable() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided address.
    function createDefaultStreamWithAsset(IERC20 asset) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided broker.
    function createDefaultStreamWithBroker(Broker memory broker) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided start time.
    function createDefaultStreamWithStartTime(uint40 startTime) internal virtual returns (uint256 streamId);
}
