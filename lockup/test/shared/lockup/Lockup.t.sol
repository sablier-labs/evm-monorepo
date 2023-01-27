// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Config } from "src/interfaces/ISablierV2Config.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Base_Test } from "test/Base.t.sol";

/// @title Lockup_Shared_Test
/// @dev There is a lot of common logic between the {SablierV2LockupLinear} and the {SablierV2LockupPro} contracts,
/// specifically that both inherit from the {SablierV2Config} and the {SablierV2Lockup} contracts. We wrote this test
/// contract to avoid duplicating tests.
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
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream but make it non-cancelable.
    function createDefaultStreamNonCancelable() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal virtual returns (uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();
    }
}
