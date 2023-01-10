// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { sd1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Range, Segment } from "src/types/Structs.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Linear } from "src/interfaces/ISablierV2Linear.sol";
import { ISablierV2Pro } from "src/interfaces/ISablierV2Pro.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { Assertions } from "./helpers/Assertions.t.sol";
import { Constants } from "./helpers/Constants.t.sol";
import { Utils } from "./helpers/Utils.t.sol";

/// @title BaseTest
/// @notice Base test contract that contains common logic needed by all test contracts.
abstract contract BaseTest is Assertions, Constants, Utils, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Users {
        // Default admin of all Sablier V2 contracts.
        address payable admin;
        // Neutral user.
        address payable alice;
        // Default stream broker.
        address payable broker;
        // Malicious user.
        address payable eve;
        // Default NFT operator.
        address payable operator;
        // Default stream recipient.
        address payable recipient;
        // Default stream sender.
        address payable sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal immutable DEFAULT_CLIFF_TIME;
    Range internal DEFAULT_RANGE;
    Segment[] internal DEFAULT_SEGMENTS;
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal immutable DEFAULT_STOP_TIME;

    /*//////////////////////////////////////////////////////////////////////////
                                      STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller internal comptroller;
    IERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);
    ISablierV2Linear internal linear;
    NonCompliantERC20 internal nonCompliantToken = new NonCompliantERC20("Non-Compliant Token", "NCT", 18);
    ISablierV2Pro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_STOP_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
        DEFAULT_RANGE = Range({ start: DEFAULT_START_TIME, cliff: DEFAULT_CLIFF_TIME, stop: DEFAULT_STOP_TIME });

        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 2_500e18,
                exponent: sd1x18(3.14e18),
                milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
            })
        );
        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 7_500e18,
                exponent: sd1x18(0.5e18),
                milestone: DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Create users for testing.
        users = Users({
            admin: createUser("Admin"),
            alice: createUser("Alice"),
            broker: createUser("Broker"),
            eve: createUser("Eve"),
            operator: createUser("Operator"),
            recipient: createUser("Recipient"),
            sender: createUser("Sender")
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Adjust the amounts in the default segments as two fractions of the provided net deposit amount,
    /// one 20%, the other 80%.
    function adjustSegmentAmounts(Segment[] memory segments, uint128 netDepositAmount) internal pure {
        segments[0].amount = uint128(UD60x18.unwrap(ud(netDepositAmount).mul(ud(0.2e18))));
        segments[1].amount = netDepositAmount - segments[0].amount;
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal view returns (bool result) {
        string memory profile = tryEnvString("FOUNDRY_PROFILE");
        result = eqString(profile, "test-optimized");
    }

    /// @dev Tries to read an environment variable as a string, returning an empty string if the variable
    /// is not defined.
    function tryEnvString(string memory name) internal view returns (string memory) {
        try vm.envString(name) returns (string memory value) {
            return value;
        } catch {
            return "";
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all Sablier contracts to spend tokens from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the admin.
    function approveSablierContracts() internal {
        changePrank(users.sender);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.recipient);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.alice);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank(users.eve);
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantToken.approve({ spender: address(pro), value: UINT256_MAX });

        // Finally, change the active prank back to the admin.
        changePrank(users.admin);
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    /// and 1 million non-compliant tokens.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label({ account: addr, newLabel: name });
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(nonCompliantToken), to: addr, give: 1_000_000e18 });
    }

    /// @dev Conditionally deploy contracts normally or from precompiled source.
    function deploySablierContracts() internal {
        // We deploy all contracts with the admin as the caller.
        vm.startPrank({ msgSender: users.admin });

        // We deploy from precompiled source if the profile is "test-optimized".
        if (isTestOptimizedProfile()) {
            comptroller = ISablierV2Comptroller(
                deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json")
            );
            linear = ISablierV2Linear(
                deployCode(
                    "optimized-out/SablierV2Linear.sol/SablierV2Linear.json",
                    abi.encode(address(comptroller), DEFAULT_MAX_FEE)
                )
            );
            pro = ISablierV2Pro(
                deployCode(
                    "optimized-out/SablierV2Pro.sol/SablierV2Pro.json",
                    abi.encode(address(comptroller), DEFAULT_MAX_FEE, DEFAULT_MAX_SEGMENT_COUNT)
                )
            );
        }
        // We deploy normally in all other cases.
        else {
            comptroller = new SablierV2Comptroller();
            linear = new SablierV2Linear({ initialComptroller: comptroller, maxFee: DEFAULT_MAX_FEE });
            pro = new SablierV2Pro({
                initialComptroller: comptroller,
                maxFee: DEFAULT_MAX_FEE,
                maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(linear), newLabel: "SablierV2Linear" });
        vm.label({ account: address(pro), newLabel: "SablierV2Pro" });
    }
}
