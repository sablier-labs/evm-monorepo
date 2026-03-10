// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { BaseTest } from "src/tests/BaseTest.sol";

abstract contract Modifiers is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNotInitialized() {
        _;
    }

    modifier givenOracleNotZero() {
        _;
    }

    modifier givenSymbolAsString() {
        _;
    }

    modifier givenSymbolImplemented() {
        _;
    }

    modifier givenSymbolNotLongerThan30Chars() {
        _;
    }

    modifier givenTokenBalanceNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAccountHasRole() {
        _;
    }

    modifier whenAccountNotAdmin() {
        _;
    }

    modifier whenAccountNotHaveRole() {
        _;
    }

    modifier whenAddressesHaveFee() {
        _;
    }

    modifier whenAddressesImplementIComptrollerable() {
        _;
    }

    modifier whenCalledOnProxy() {
        _;
    }

    modifier whenCallerAdmin() {
        setMsgSender(admin);
        _;
    }

    modifier whenCallerCurrentComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCallerNotAdmin() {
        _;
    }

    modifier whenCallerWithoutFeeCollectorRole() {
        _;
    }

    modifier whenCallReverts() {
        _;
    }

    modifier whenCampaignImplementsSablierMerkle() {
        _;
    }

    modifier whenCampaignReturnsTrueForSablierMerkle() {
        _;
    }

    modifier whenComptrollerWithMinimalInterfaceId() {
        _;
    }

    modifier whenDecimalsCallNotFail() {
        _;
    }

    modifier whenFeeRecipientContract() {
        _;
    }

    modifier whenFeeRecipientNotZero() {
        _;
    }

    modifier whenFeeUSDNotZero() {
        _;
    }

    modifier whenFunctionExists() {
        _;
    }

    modifier whenInitialAirdropFeeNotExceedMaxFee() {
        _;
    }

    modifier whenInitialBobFeeNotExceedMaxFee() {
        _;
    }

    modifier whenInitialFlowFeeNotExceedMaxFee() {
        _;
    }

    modifier whenLatestRoundCallNotFail() {
        _;
    }

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    modifier whenNewFeeNotExceedMaxFee() {
        _;
    }

    modifier whenNonStateChangingFunction() {
        _;
    }

    modifier whenNormalizedPriceNotExceedUint128Max() {
        _;
    }

    modifier whenNotEmptyString() {
        _;
    }

    modifier whenNotPayable() {
        _;
    }

    modifier whenOracleAddressNotZero() {
        _;
    }

    modifier whenOracleDecimalsNotTooHigh() {
        _;
    }

    modifier whenOracleDecimalsNotZero() {
        _;
    }

    modifier whenOracleNotMissDecimals() {
        _;
    }

    modifier whenOracleNotMissLatestRoundData() {
        _;
    }

    modifier whenNewOracleNotZero() {
        _;
    }

    modifier whenOraclePriceNotExceedUint128Max() {
        _;
    }

    modifier whenOraclePriceNotOutdated() {
        _;
    }

    modifier whenOraclePricePositive() {
        _;
    }

    modifier whenOracleUpdatedTimeNotInFuture() {
        _;
    }

    modifier whenPayable() {
        _;
    }

    modifier whenRecipientNotZeroAddress() {
        _;
    }

    modifier whenSafeOraclePriceNotZero() {
        _;
    }

    modifier whenStateChangingFunction() {
        _;
    }

    modifier whenTargetContract() {
        _;
    }

    modifier whenPriceNormalized() {
        _;
    }

    modifier whenPriceNotNormalized() {
        _;
    }

    modifier whenTokenContract() {
        _;
    }
}
