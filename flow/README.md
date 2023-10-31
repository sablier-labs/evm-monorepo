## Decisions

Asset decimals can’t be passed in create function because one may create a fake stream with less or more decimals and in
this way he may extract more assets from stream.

We store the asset decimals, so that we don't have to make an external call to get the decimals of the asset each time a
deposit or an extraction is made. Decimals are `uint8`, meaning it is not an expensive operation to store them.

We use 18 fixed-point numbers for all internal amounts (`balance`, `amountPerSecond`, `withdrawable`, `refundable`) to
avoid the overload of conversion to actual ERC20 balances. The only time we perform these conversions is during external
calls, i.e. the deposit and extract operations.

Recipient address **must** be checked because there is no NFT minted in `_create` function.

Sender address **must** be checked because there is no ERC20 transfer in `_create` function.

In `_cancel` function we can perform both sender and recipient ERC20 transfers because there is no NFT so we don’t have
to worry about [this issue](https://github.com/cantinasec/review-sablier/issues/11).

## Invariants:

_balance = withdrawable amount + refundable amount_

_withdrawable amount ≤ streamed amount_

_lastTimeUpdate ≤ block.timestamp;_

_if(isCanceled = true) then balance= 0 && amountPerSecond= 0_

_sum of withdrawn amounts ≤ sum of deposits_

_sum of stream balances normilized to asset decimals ≤ asset.balanceOf(SablierV2OpenEnded)_

## Issues:

#### Precision

- Amount per second precision for tokens with fewer decimals: If one wants to stream 10 USDC per day, the
  `amountPerSecond` should be 0.00011574074074074.., but with USDC having 6 decimals, it would be 0.000115, resulting in
  9.936000 at the end of the day. (0.064000 loss at the end of the day)
  - The solution approach: Normalize to 18 decimals for all stored amounts, i.e., `stream.amountPerSecond` and
    `stream.balance`. Although this does not completely fix the issue, it minimizes it as much as possible. For the
    example from above, at the end of the day the result would be 9.999999999999936000 (0.0000000000000064000 loss at
    the end of the day). Currently, I don't think it's possible to address this precision problem entirely, given the
    nature of open-endedness(no explicit duration of the stream).

## Questions:

Should we update the time in `_cancel`?

Should we add TimeUpdated event?

Should we add pausable functionality? It would be basically a cancel function

### TODOs:

- createMultiple
- withdrawMultiple
- add broker fees and protocol fees (implicitely comptroller + adminable contract)
  - The fee should be on `create` or on `deposit` ? both?
- explain what is different
- explain how it works
