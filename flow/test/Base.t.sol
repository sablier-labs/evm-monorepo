// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Test } from "forge-std/Test.sol";

import { SablierV2OpenEnded } from "src/SablierV2OpenEnded.sol";

import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { ERC20MissingReturn } from "./mocks/ERC20MissingReturn.sol";

struct Users {
    address sender;
    address recipient;
}

abstract contract Base_Test is Test {
    using SafeCast for uint256;

    // Testing contract
    SablierV2OpenEnded internal openEnded;

    // Contract constants
    uint128 amountPerSecond = 0.001e18; // 86.4 daily
    uint128 depositAmount = 0;

    // Users
    Users internal users;

    // Assets
    ERC20Mock internal dai = new ERC20Mock("Dai stablecoin", "DAI");
    ERC20MissingReturn internal usdt = new ERC20MissingReturn("USDT stablecoin", "USDT", 6);

    // Set up
    function setUp() public virtual {
        openEnded = new SablierV2OpenEnded();

        users.sender = createUser("sender");
        users.recipient = createUser("recipient");

        vm.label(address(openEnded), "Open Ended");
        vm.label(address(dai), "DAI");
        vm.label(address(usdt), "USDT");
    }

    // Helpers
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(dai), to: user, give: 1_000_000e18 });
        deal({ token: address(usdt), to: user, give: 1_000_000e18 });
        return user;
    }

    function normalizeToAssetDecimals(
        uint256 streamId,
        uint128 amount
    )
        internal
        view
        returns (uint128 normalizedAmount)
    {
        // Retrieve the asset's decimals from storage.
        uint8 assetDecimals = openEnded.getAssetDecimals(streamId);

        // Return the original amount if it's already in the standard 18-decimal format.
        if (assetDecimals == 18) {
            return amount;
        }

        bool isGreaterThan18 = assetDecimals > 18;

        uint8 normalizationFactor = isGreaterThan18 ? assetDecimals - 18 : 18 - assetDecimals;

        normalizedAmount = isGreaterThan18
            ? (amount / (10 ** normalizationFactor)).toUint128()
            : (amount * (10 ** normalizationFactor)).toUint128();
    }
}
