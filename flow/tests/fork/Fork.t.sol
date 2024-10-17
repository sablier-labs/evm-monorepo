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

    /// @dev A typical 18-decimal ERC-20 token with a normal total supply.
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /// @dev An ERC-20 token with 2 decimals.
    IERC20 private constant EURS = IERC20(0xdB25f211AB05b1c97D595516F45794528a807ad8);

    /// @dev An ERC-20 token with a large total supply.
    IERC20 private constant SHIBA = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);

    /// @dev An ERC-20 token with 6 decimals.
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @dev An ERC-20 token that suffers from the missing return value bug.
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    IERC20 internal token;

    /// @dev The list of tokens to test.
    IERC20[5] internal tokens = [DAI, EURS, SHIBA, USDC, USDT];

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number. The block number is for the `OCT_1_2024` date.
        vm.createSelectFork({ blockNumber: 20_866_919, urlOrAlias: "mainnet" });

        // The base is set up after the fork is selected so that the base test contracts are deployed on the fork.
        Base_Test.setUp();

        // Label the tokens.
        for (uint256 i = 0; i < tokens.length; ++i) {
            vm.label({ account: address(tokens[i]), newLabel: IERC20Metadata(address(tokens[i])).symbol() });
        }
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
        if (token == USDC || token == USDT) {
            // 4-byte selector for `isBlacklisted(address)`, used by USDC.
            (bool isSenderBlacklisted,) = address(token).staticcall(abi.encodeWithSelector(0xfe575a87, sender));
            if (isSenderBlacklisted) {
                sender = address(uint160(sender) + 1);
            }

            // 4-byte selector for `isBlackListed(address)`, used by USDT.
            (bool isRecipientBlacklisted,) = address(token).staticcall(abi.encodeWithSelector(0xe47d6060, recipient));
            if (isRecipientBlacklisted) {
                recipient = address(uint160(recipient) + 1);
            }
        }
    }

    /// @dev Helper function to deposit on a stream.
    function depositOnStream(uint256 streamId, uint128 depositAmount) internal {
        address sender = flow.getSender(streamId);
        resetPrank({ msgSender: sender });
        deal({ token: address(token), to: sender, give: depositAmount });
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
        (bool success,) = address(token).call(abi.encodeCall(IERC20.approve, (address(flow), amount)));
        success;
    }
}
