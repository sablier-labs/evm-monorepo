// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) {
        FORK_TOKEN = forkToken;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a block number after the Sablier deployment.
        // TODO: uncomment the following line after deployment.
        // vm.createSelectFork({ blockNumber: 21_718_689, urlOrAlias: "mainnet" });

        // TODO: update the flow contract address once deployed and uncomment the following lines.
        // Load mainnet address.
        // flow = ISablierFlow(0x3DF2AAEdE81D2F6b261F79047517713B8E844E04);
        // Label the flow contract.
        // vm.label(address(flow), "Flow");

        // TODO: comment the following two lines after deployment.
        Base_Test.setUp();
        vm.etch(address(FORK_TOKEN), address(usdc).code);

        // Label the token.
        vm.label({ account: address(FORK_TOKEN), newLabel: IERC20Metadata(address(FORK_TOKEN)).symbol() });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks the fuzzed users.
    /// @dev The reason for not using `vm.assume` is because the compilation takes longer.
    function checkUsers(address sender, address recipient) internal virtual {
        // Ensure that flow is not assigned as the fuzzed sender.
        if (sender == address(flow)) {
            sender = address(uint160(sender) + 1);
        }

        // Ensure that flow is not assigned as the fuzzed recipient.
        if (recipient == address(flow)) {
            recipient = address(uint160(recipient) + 1);
        }

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_TOKEN), sender);
        assumeNoBlacklisted(address(FORK_TOKEN), recipient);
    }

    /// @dev Helper function to deposit on a stream.
    function depositOnStream(uint256 streamId, uint128 depositAmount) internal {
        address sender = flow.getSender(streamId);
        setMsgSender(sender);
        deal({ token: address(FORK_TOKEN), to: sender, give: depositAmount });
        safeApprove(depositAmount);
        flow.deposit({
            streamId: streamId,
            amount: depositAmount,
            sender: sender,
            recipient: flow.getRecipient(streamId)
        });
    }

    /// @dev Use a low-level call to ignore reverts in case of USDT.
    function safeApprove(uint256 amount) internal {
        (bool success,) = address(FORK_TOKEN).call(abi.encodeCall(IERC20.approve, (address(flow), amount)));
        success;
    }
}
