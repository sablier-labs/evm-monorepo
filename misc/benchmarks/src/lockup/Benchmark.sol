// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ERC20Mock } from "@sablier/evm-utils/src/mocks/erc20/ERC20Mock.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { BaseTest } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { ISablierBatchLockup } from "@sablier/lockup/src/interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { Defaults } from "@sablier/lockup/tests/utils/Defaults.sol";
import { Users } from "@sablier/lockup/tests/utils/Types.sol";

/// @notice Base contract with common logic needed to get gas benchmarks for Lockup streams.
abstract contract LockupBenchmark is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint128 internal immutable AMOUNT_PER_SEGMENT = 100e18;
    uint128 internal immutable AMOUNT_PER_TRANCHE = 100e18;

    /// @dev The name of the file where the benchmark results are stored. Each derived contract must set this.
    string internal IMM_RESULTS_FILE;

    /// @dev A variable used to store the content to append to the results file.
    string internal contentToAppend;

    /// @dev Minimum fee requires to withdraw from Lockup streams.
    uint256 internal minFeeWei;

    Users internal users;

    ERC20Mock internal weth;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierBatchLockup internal batchLockup;
    Defaults internal defaults;
    ISablierLockup internal lockup;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        logBlue("Setting up Lockup benchmarks...");

        // Fork Ethereum Mainnet at the latest block.
        setUpForkEthereum();
        logGreen("Forked Ethereum Mainnet");

        // Load deployed addresses from Ethereum mainnet.
        // See https://docs.sablier.com/guides/lockup/deployments
        batchLockup = ISablierBatchLockup(0x0636D83B184D65C242c43de6AAd10535BFb9D45a);
        lockup = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);
        logGreen("Loaded Sablier contracts");

        // Load WETH token.
        weth = ERC20Mock(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        tokens.push(weth);
        logGreen("Loaded WETH token contract");

        // Create test users and deal WETH to them.
        address[] memory spenders = new address[](2);
        spenders[0] = address(batchLockup);
        spenders[1] = address(lockup);
        users.alice = createUser("alice", spenders);
        users.recipient = createUser("recipient", spenders);
        users.sender = createUser("sender", spenders);
        logGreen("Created test users, funded WETH and approved contracts");

        setMsgSender(users.sender);

        defaults = new Defaults();
        defaults.setToken(weth);
        defaults.setUsers(users);

        // Create test streams.
        _setUpStreams();
        logGreen("Created test streams");
        logBlue("Setup complete! Ready to run benchmarks.");

        // Set value for minFeeWei.
        minFeeWei = lockup.comptroller().calculateMinFeeWei({ protocol: ISablierComptroller.Protocol.Lockup });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    SHARED LOGIC
    //////////////////////////////////////////////////////////////////////////*/

    function instrument_Burn(uint256 streamId) internal returns (uint256 gasUsed) {
        setMsgSender(users.recipient);
        // Warp to the end of the stream.
        vm.warp({ newTimestamp: lockup.getEndTime(streamId) });

        lockup.withdrawMax{ value: minFeeWei }(streamId, users.recipient);

        uint256 initialGas = gasleft();
        lockup.burn(streamId);
        gasUsed = initialGas - gasleft();
    }

    function instrument_Cancel(uint256 streamId) internal returns (uint256 gasUsed) {
        setMsgSender(users.sender);

        // Warp to right before the end of the stream.
        vm.warp({ newTimestamp: lockup.getEndTime(streamId) - 1 seconds });

        uint256 initialGas = gasleft();
        lockup.cancel(streamId);
        gasUsed = initialGas - gasleft();
    }

    function instrument_Renounce(uint256 streamId) internal returns (uint256 gasUsed) {
        setMsgSender(users.sender);
        // Warp to halfway through the stream.
        vm.warp({ newTimestamp: lockup.getEndTime(streamId) / 2 });

        uint256 initialGas = gasleft();
        lockup.renounce(streamId);
        gasUsed = initialGas - gasleft();
    }

    function instrument_Withdraw(uint256 streamId, address caller) internal returns (uint256 gasUsed) {
        setMsgSender(caller);

        uint128 withdrawAmount = lockup.withdrawableAmountOf(streamId);
        if (withdrawAmount == 0) {
            revert(string.concat("Withdraw amount is 0 for stream ", vm.toString(streamId)));
        }

        uint256 initialGas = gasleft();
        lockup.withdraw{ value: minFeeWei }(streamId, users.recipient, withdrawAmount);
        gasUsed = initialGas - gasleft();
    }

    function instrument_WithdrawCompleted(
        uint256 streamId,
        address caller
    )
        internal
        returns (uint256 gasUsed, string memory config)
    {
        // Warp to right past the end of the stream.
        vm.warp({ newTimestamp: lockup.getEndTime(streamId) + 1 seconds });

        gasUsed = instrument_Withdraw(streamId, caller);

        if (caller == users.recipient) {
            config = "vesting completed && called by recipient";
        } else {
            config = "vesting completed && called by third-party";
        }
    }

    function instrument_WithdrawOngoing(
        uint256 streamId,
        address caller
    )
        internal
        returns (uint256 gasUsed, string memory config)
    {
        // Warp to right before the end of the stream.
        vm.warp({ newTimestamp: lockup.getEndTime(streamId) - 1 seconds });
        gasUsed = instrument_Withdraw(streamId, caller);

        if (caller == users.recipient) {
            config = "vesting ongoing && called by recipient";
        } else {
            config = "vesting ongoing && called by third-party";
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Private function to create one stream with each model. These streams will help in initializing the state
    /// variables.
    function _setUpStreams() private {
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        lockup.createWithTimestampsLD({ params: params, segments: defaults.segments() });
        lockup.createWithTimestampsLL({
            params: params,
            unlockAmounts: defaults.unlockAmounts(),
            cliffTime: defaults.CLIFF_TIME()
        });
        lockup.createWithTimestampsLT({ params: params, tranches: defaults.tranches() });
    }
}
