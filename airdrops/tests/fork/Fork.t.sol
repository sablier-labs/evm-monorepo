// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleInstant } from "src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

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
        factoryMerkleInstant = ISablierFactoryMerkleInstant(0x7f70bA7C7373BaA4047cE450168cD24968321Bda);
        factoryMerkleLL = ISablierFactoryMerkleLL(0x0781Ad660a5ED0041B45d44d45009a163CC0B578);
        factoryMerkleLT = ISablierFactoryMerkleLT(0x336d464276e2c7C76927d975Ef866Df8a7Ecf8DD);
        factoryMerkleVCA = ISablierFactoryMerkleVCA(0x91FdBd7077d615f951a0defA81Ec30Bfd68dbd8D);

        // Update lockup address.
        lockup = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);
    }
}
