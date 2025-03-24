// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Base_Test } from "./../Base.t.sol";

/// @notice Base logic needed by the fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;
    address internal forkTokenHolder;
    uint128 internal initialHolderBalance;

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
        // Fork Ethereum Mainnet at a specific block number.
        // TODO: Uncomment the following after deployment.
        // vm.createSelectFork({ blockNumber: 21_719_029, urlOrAlias: "mainnet" });

        // TODO: Uncomment and load deployed addresses from Ethereum mainnet.
        // Load deployed addresses from Ethereum mainnet.
        // batchLockup = ISablierBatchLockup(0x3F6E8a8Cffe377c4649aCeB01e6F20c60fAA356c);
        // nftDescriptor = ILockupNFTDescriptor(0xA9dC6878C979B5cc1d98a1803F0664ad725A1f56);
        // lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);

        // TODO: Remove the following two lines after deployment.
        Base_Test.setUp();
        vm.etch(address(FORK_TOKEN), address(usdc).code);

        // Create a custom user for this test suite.
        forkTokenHolder = payable(makeAddr(string.concat(IERC20Metadata(address(FORK_TOKEN)).symbol(), "_HOLDER")));

        // Label the addresses.
        labelContracts();

        // Deal 1M tokens to the user.
        initialHolderBalance = uint128(1e6 * (10 ** IERC20Metadata(address(FORK_TOKEN)).decimals()));
        deal({ token: address(FORK_TOKEN), to: forkTokenHolder, give: initialHolderBalance });

        setMsgSender({ msgSender: forkTokenHolder });

        // Approve {SablierLockup} to transfer the holder's tokens.
        approveContract({ token_: address(FORK_TOKEN), from: forkTokenHolder, spender: address(lockup) });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address lockupContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0));

        // The goal is to not have overlapping users because the forked token balance tests would fail otherwise.
        vm.assume(sender != recipient);
        vm.assume(sender != forkTokenHolder && recipient != forkTokenHolder);
        vm.assume(sender != lockupContract && recipient != lockupContract);

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_TOKEN), sender);
        assumeNoBlacklisted(address(FORK_TOKEN), recipient);

        // Make the holder the caller.
        setMsgSender(forkTokenHolder);
    }

    /// @dev Labels the most relevant addresses.
    function labelContracts() internal {
        vm.label({ account: address(FORK_TOKEN), newLabel: IERC20Metadata(address(FORK_TOKEN)).symbol() });
        vm.label({ account: forkTokenHolder, newLabel: "Fork Token Holder" });
    }

    // TODO: Remove the following function after deployment. This is to mock multicall.
    function getTokenBalances(
        address token,
        address[] memory addresses
    )
        internal
        view
        override
        returns (uint256[] memory balances)
    {
        balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; ++i) {
            balances[i] = IERC20(token).balanceOf(addresses[i]);
        }
    }
}
