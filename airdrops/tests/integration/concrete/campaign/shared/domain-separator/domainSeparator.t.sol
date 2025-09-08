// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Utilities } from "tests/utils/Utilities.sol";
import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract DomainSeparator_Integration_Test is Integration_Test {
    function test_WhenChainIDMatchesCachedChainID() external view {
        // It should return the cached domain separator.
        bytes32 actualDomainSeparator = merkleBase.domainSeparator();
        bytes32 expectedDomainSeparator = Utilities.computeEIP712DomainSeparator(address(merkleBase));
        assertEq(actualDomainSeparator, expectedDomainSeparator, "domain separator");
    }

    function test_WhenChainIDNotMatchCachedChainID() external {
        // Set a different chain ID.
        vm.chainId(1000);

        // It should return the computed domain separator.
        bytes32 actualDomainSeparator = merkleBase.domainSeparator();
        bytes32 expectedDomainSeparator = Utilities.computeEIP712DomainSeparator(address(merkleBase));
        assertEq(actualDomainSeparator, expectedDomainSeparator, "domain separator");
    }
}
