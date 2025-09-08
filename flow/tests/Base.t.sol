// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20Mock } from "@sablier/evm-utils/src/mocks/erc20/ERC20Mock.sol";
import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { FlowNFTDescriptor } from "src/FlowNFTDescriptor.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { SablierFlow } from "src/SablierFlow.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users } from "./utils/Types.sol";
import { Vars } from "./utils/Vars.sol";

abstract contract Base_Test is Assertions, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;
    Vars internal vars;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierFlow internal flow;
    FlowNFTDescriptor internal nftDescriptor;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmUtilsBase.setUp();

        if (!isTestOptimizedProfile()) {
            nftDescriptor = new FlowNFTDescriptor();
            flow = new SablierFlow(address(comptroller), address(nftDescriptor));
        } else {
            flow = deployOptimizedSablierFlow();
        }

        // Label the contracts.
        vm.label({ account: address(flow), newLabel: "Flow" });

        // Deploy the token without decimals and push it to the tokens array from CommonBase.
        IERC20 tokenWithoutDecimals = new ERC20Mock("Token Without Decimals", "TWD", 0);
        tokens.push(tokenWithoutDecimals);

        // Create users for testing.
        createTestUsers();

        setMsgSender(users.sender);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Create users for testing and assign roles if applicable.
    function createTestUsers() internal {
        // Create users for testing. Note that due to ERC-20 approvals, this has to go after the protocol deployment.
        address[] memory spenders = new address[](1);
        spenders[0] = address(flow);

        // Create test users.
        users.accountant = createUser("Accountant", spenders);
        users.eve = createUser("eve", spenders);
        users.operator = createUser("operator", spenders);
        users.recipient = createUser("recipient", spenders);
        users.sender = createUser("sender", spenders);
    }

    /// @dev Deploys {SablierFlow} from an optimized source compiled with `--via-ir`.
    function deployOptimizedSablierFlow() internal returns (SablierFlow) {
        nftDescriptor = FlowNFTDescriptor(deployCode("out-optimized/FlowNFTDescriptor.sol/FlowNFTDescriptor.json"));

        return SablierFlow(
            deployCode(
                "out-optimized/SablierFlow.sol/SablierFlow.json",
                abi.encode(address(comptroller), address(nftDescriptor))
            )
        );
    }
}
