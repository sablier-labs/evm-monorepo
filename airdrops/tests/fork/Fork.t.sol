// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierFactoryMerkleExecute } from "src/interfaces/ISablierFactoryMerkleExecute.sol";
import { ISablierFactoryMerkleInstant } from "src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;
    address internal factoryAdmin;

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
        // Fork Ethereum Mainnet at the latest block number.
        vm.createSelectFork({ urlOrAlias: "ethereum" });

        // Load deployed addresses from Ethereum Mainnet.
        comptroller = ISablierComptroller(0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399);
        factoryMerkleExecute = ISablierFactoryMerkleExecute(0x75ca3677966737E70649336ee8f9be57AC9f74bA);
        factoryMerkleInstant = ISablierFactoryMerkleInstant(0xb2855845067e126207DE2155Ad1c8AD5C495cb3F);
        factoryMerkleLL = ISablierFactoryMerkleLL(0x3210E9b8ed75f9E2Db00ef17167C775e658c2221);
        factoryMerkleLT = ISablierFactoryMerkleLT(0x239BD5431aDa12F09cA95d0a5d4388A5644268e9);
        factoryMerkleVCA = ISablierFactoryMerkleVCA(0xe60Df8e04cE1616a06db8AD11ce71c05dDcB5D88);

        lockup = ISablierLockup(0x93b37Bd5B6b278373217333Ac30D7E74c85fBDCB);

        // Label the token contract.
        labelForkedToken(FORK_TOKEN);
    }
}
