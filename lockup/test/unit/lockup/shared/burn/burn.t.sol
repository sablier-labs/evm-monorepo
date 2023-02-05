// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Burn_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient (owner of the NFT) the caller in this test suite.
        changePrank({ who: users.recipient });
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCanceledOrDepleted.selector, nullStreamId)
        );
        lockup.burn(nullStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamActive() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCanceledOrDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    /// @dev This modifier runs the test twice, once with a canceled stream, and once with a depleted stream.
    modifier streamCanceledOrDepleted() {
        lockup.cancel(streamId);
        _;
        changePrank({ who: users.recipient });
        streamId = createDefaultStream();
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized() external streamCanceledOrDepleted {
        // Make Eve the caller in the rest of this test.
        changePrank({ who: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, streamId, users.eve));
        lockup.burn(streamId);
    }

    modifier callerAuthorized() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_NFTNonExistent() external streamCanceledOrDepleted callerAuthorized {
        // Burn the NFT so that it no longer exists.
        lockup.burn(streamId);

        // Run the test.
        vm.expectRevert("ERC721: invalid token ID");
        lockup.burn(streamId);
    }

    modifier nftExistent() {
        _;
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerApprovedOperator() external streamCanceledOrDepleted callerAuthorized nftExistent {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the approved operator the caller in this test.
        changePrank({ who: users.operator });

        // Burn the NFT.
        lockup.burn(streamId);

        // Assert that the NFT has been burned.
        address actualNFTOwner = lockup.getRecipient(streamId);
        address expectedNFTOwner = address(0);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerNFTOwner() external streamCanceledOrDepleted callerAuthorized nftExistent {
        lockup.burn(streamId);
        address actualNFTOwner = lockup.getRecipient(streamId);
        address expectedNFTOwner = address(0);
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
