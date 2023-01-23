// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { NonCompliantERC20 } from "@prb/contracts/token/erc20/NonCompliantERC20.sol";
import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { eqString } from "@prb/test/Helpers.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { DeployComptroller } from "script/DeployComptroller.s.sol";
import { DeployLockupLinear } from "script/DeployLockupLinear.s.sol";
import { DeployLockupPro } from "script/DeployLockupPro.s.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupLinear } from "src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupPro } from "src/interfaces/ISablierV2LockupPro.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { Range, Segment } from "src/types/Structs.sol";

import { Assertions } from "./shared/helpers/Assertions.t.sol";
import { Constants } from "./shared/helpers/Constants.t.sol";
import { Utils } from "./shared/helpers/Utils.t.sol";

/// @title Base_Test
/// @notice Base test contract that contains common logic needed by all test contracts.
abstract contract Base_Test is Assertions, Constants, Utils, StdCheats {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

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

    IERC20 internal immutable DEFAULT_ASSET;
    uint40 internal immutable DEFAULT_CLIFF_TIME;
    Range internal DEFAULT_RANGE;
    Segment[] internal DEFAULT_SEGMENTS;
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal immutable DEFAULT_STOP_TIME;
    Segment[] internal MAX_SEGMENTS;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller internal comptroller;
    IERC20 internal dai = new ERC20("Dai Stablecoin", "DAI", 18);
    ISablierV2LockupLinear internal linear;
    NonCompliantERC20 internal nonCompliantAsset = new NonCompliantERC20("Non-Compliant ERC-20 Asset", "NCT", 18);
    ISablierV2LockupPro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_ASSET = dai;
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_STOP_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
        DEFAULT_RANGE = Range({ start: DEFAULT_START_TIME, cliff: DEFAULT_CLIFF_TIME, stop: DEFAULT_STOP_TIME });

        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 2_500e18,
                exponent: ud2x18(3.14e18),
                milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
            })
        );
        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 7_500e18,
                exponent: ud2x18(0.5e18),
                milestone: DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
            })
        );

        unchecked {
            uint128 amount = DEFAULT_NET_DEPOSIT_AMOUNT / uint128(DEFAULT_MAX_SEGMENT_COUNT);
            UD2x18 exponent = ud2x18(2.71e18);
            uint40 duration = DEFAULT_TOTAL_DURATION / uint40(DEFAULT_MAX_SEGMENT_COUNT);

            // Generate a bunch of segments with the same amount, same exponent, and with milestones
            // evenly spread apart.
            for (uint40 i = 0; i < DEFAULT_MAX_SEGMENT_COUNT; ++i) {
                MAX_SEGMENTS.push(
                    Segment({ amount: amount, exponent: exponent, milestone: DEFAULT_START_TIME + duration * (i + 1) })
                );
            }
        }
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
        segments[0].amount = ud(netDepositAmount).mul(ud(0.2e18)).intoUint128();
        segments[1].amount = netDepositAmount - segments[0].amount;
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /// @dev Helper function that replicates the logic of the {SablierV2LockupLinear-getStreamedAmount} function.
    function calculateStreamedAmount(
        uint40 currentTime,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime > DEFAULT_STOP_TIME) {
            return depositAmount;
        }
        unchecked {
            UD60x18 elapsedTime = ud(currentTime - DEFAULT_START_TIME);
            UD60x18 totalTime = ud(DEFAULT_TOTAL_DURATION);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            streamedAmount = elapsedTimePercentage.mul(ud(depositAmount)).intoUint128();
        }
    }

    /// @dev Helper function that replicates the logic of the
    /// {SablierV2LockupPro-calculateStreamedAmountForMultipleSegments} function.
    function calculateStreamedAmountForMultipleSegments(
        uint40 currentTime,
        Segment[] memory segments,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime >= segments[segments.length - 1].milestone) {
            return depositAmount;
        }

        unchecked {
            // Sum up the amounts found in all preceding segments.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = segments[0].milestone;
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += segments[index - 1].amount;
                currentSegmentMilestone = segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, whereas the previous segment
            // is found at `index - 2` (if there are at least two segments).
            SD59x18 currentSegmentAmount = segments[index - 1].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = segments[index - 1].exponent.intoSD59x18();
            currentSegmentMilestone = segments[index - 1].milestone;

            uint40 previousMilestone;
            if (index > 1) {
                // If the current segment is at an index that is >= 2, we use the previous segment's milestone.
                previousMilestone = segments[index - 2].milestone;
            } else {
                // Otherwise, there is only one segment, so we use the start of the stream as the previous milestone.
                previousMilestone = DEFAULT_START_TIME;
            }

            // Calculate how much time has elapsed since the segment started, and the total time of the segment.
            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            streamedAmount = previousSegmentAmounts + uint128(multiplier.mul(currentSegmentAmount).intoUint256());
        }
    }

    /// @dev Helper function that replicates the logic of the
    /// {SablierV2LockupPro-calculateStreamedAmountForOneSegment} function.
    function calculateStreamedAmountForOneSegment(
        uint40 currentTime,
        UD2x18 exponent,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime >= DEFAULT_STOP_TIME) {
            return depositAmount;
        }
        unchecked {
            // Calculate how much time has elapsed since the stream started, and the total time of the stream.
            SD59x18 elapsedTime = (currentTime - DEFAULT_START_TIME).intoSD59x18();
            SD59x18 totalTime = DEFAULT_TOTAL_DURATION.intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(exponent.intoSD59x18());
            streamedAmount = uint128(multiplier.mul(depositAmount.intoSD59x18()).intoUint256());
        }
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool result) {
        string memory profile = vm.envOr("FOUNDRY_PROFILE", string(""));
        result = eqString(profile, "test-optimized");
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Approves all Sablier contracts to spend ERC-20 assets from the sender, recipient, Alice and Eve,
    /// and then change the active prank back to the admin.
    function approveProtocol() internal {
        changePrank({ who: users.sender });
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ who: users.recipient });
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ who: users.alice });
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        changePrank({ who: users.eve });
        dai.approve({ spender: address(linear), value: UINT256_MAX });
        dai.approve({ spender: address(pro), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(linear), value: UINT256_MAX });
        nonCompliantAsset.approve({ spender: address(pro), value: UINT256_MAX });

        // Finally, change the active prank back to the admin.
        changePrank({ who: users.admin });
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million DAI,
    /// and 1 million non-compliant assets.
    function createUser(string memory name) internal returns (address payable addr) {
        addr = payable(address(uint160(uint256(keccak256(abi.encodePacked(name))))));
        vm.label({ account: addr, newLabel: name });
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(dai), to: addr, give: 1_000_000e18 });
        deal({ token: address(nonCompliantAsset), to: addr, give: 1_000_000e18 });
    }

    /// @dev Conditionally deploy contracts normally or from precompiled source.
    function deployProtocol() internal {
        // We deploy from precompiled source if the profile is "test-optimized".
        if (isTestOptimizedProfile()) {
            comptroller = ISablierV2Comptroller(
                deployCode("optimized-out/SablierV2Comptroller.sol/SablierV2Comptroller.json", abi.encode(users.admin))
            );
            linear = ISablierV2LockupLinear(
                deployCode(
                    "optimized-out/SablierV2LockupLinear.sol/SablierV2LockupLinear.json",
                    abi.encode(users.admin, address(comptroller), DEFAULT_MAX_FEE)
                )
            );
            pro = ISablierV2LockupPro(
                deployCode(
                    "optimized-out/SablierV2LockupPro.sol/SablierV2LockupPro.json",
                    abi.encode(users.admin, address(comptroller), DEFAULT_MAX_FEE, DEFAULT_MAX_SEGMENT_COUNT)
                )
            );
        }
        // We deploy normally in all other cases.
        else {
            comptroller = new DeployComptroller().run({ initialAdmin: users.admin });
            linear = new DeployLockupLinear().run({
                initialAdmin: users.admin,
                initialComptroller: comptroller,
                maxFee: DEFAULT_MAX_FEE
            });
            pro = new DeployLockupPro().run({
                initialAdmin: users.admin,
                initialComptroller: comptroller,
                maxFee: DEFAULT_MAX_FEE,
                maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
            });
        }

        // Finally, label all the contracts just deployed.
        vm.label({ account: address(comptroller), newLabel: "SablierV2Comptroller" });
        vm.label({ account: address(linear), newLabel: "SablierV2LockupLinear" });
        vm.label({ account: address(pro), newLabel: "SablierV2LockupPro" });
    }
}
