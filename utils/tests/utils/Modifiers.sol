// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

abstract contract Modifiers {
    modifier whenAccountHasRole() {
        _;
    }

    modifier whenAccountNotAdmin() {
        _;
    }

    modifier whenAccountNotHaveRole() {
        _;
    }

    modifier whenCallerAdmin() {
        _;
    }

    modifier whenCallerNotAdmin() {
        _;
    }

    modifier whenFunctionExists() {
        _;
    }

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    modifier whenNonStateChangingFunction() {
        _;
    }

    modifier whenNotPayable() {
        _;
    }

    modifier whenPayable() {
        _;
    }

    modifier whenStateChangingFunction() {
        _;
    }
}
