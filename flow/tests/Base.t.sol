// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { CommonBase } from "@sablier/evm-utils/tests/Base.sol";
import { ERC20Mock } from "@sablier/evm-utils/tests/mocks/erc20/ERC20Mock.sol";
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

    ERC20Mock internal tokenWithoutDecimals;

    ISablierFlow internal flow;
    FlowNFTDescriptor internal nftDescriptor;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Set up the common base.
        CommonBase.setUp();

        users.admin = payable(makeAddr("admin"));

        if (!isBenchmarkProfile() && !isTestOptimizedProfile()) {
            nftDescriptor = new FlowNFTDescriptor();
            flow = new SablierFlow(users.admin, nftDescriptor);
        } else {
            flow = deployOptimizedSablierFlow();
        }

        // Label the contracts.
        vm.label({ account: address(flow), newLabel: "Flow" });

        // Deploy the token without decimals and push it to the tokens array from CommonBase.
        tokenWithoutDecimals = new ERC20Mock("Token Without Decimals", "TWD", 0);
        tokens.push(tokenWithoutDecimals);

        address[] memory spenders = new address[](1);
        spenders[0] = address(flow);

        // Create the users.
        users.eve = createUser("eve", spenders);
        users.operator = createUser("operator", spenders);
        users.recipient = createUser("recipient", spenders);
        users.sender = createUser("sender", spenders);

        // Set the variables in Modifiers contract.
        setVariables(users);

        resetPrank(users.sender);

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2025 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploys {SablierFlow} from an optimized source compiled with `--via-ir`.
    function deployOptimizedSablierFlow() internal returns (SablierFlow) {
        nftDescriptor = FlowNFTDescriptor(deployCode("out-optimized/FlowNFTDescriptor.sol/FlowNFTDescriptor.json"));

        return SablierFlow(
            deployCode(
                "out-optimized/SablierFlow.sol/SablierFlow.json", abi.encode(users.admin, address(nftDescriptor))
            )
        );
    }
}
