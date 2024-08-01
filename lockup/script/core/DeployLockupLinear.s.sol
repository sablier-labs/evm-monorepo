// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { ILockupNFTDescriptor } from "../../src/core/interfaces/ILockupNFTDescriptor.sol";
import { SablierLockupLinear } from "../../src/core/SablierLockupLinear.sol";

import { BaseScript } from "../Base.s.sol";

contract DeployLockupLinear is BaseScript {
    function run(
        address initialAdmin,
        ILockupNFTDescriptor initialNFTDescriptor
    )
        public
        virtual
        broadcast
        returns (SablierLockupLinear lockupLinear)
    {
        lockupLinear = new SablierLockupLinear(initialAdmin, initialNFTDescriptor);
    }
}
