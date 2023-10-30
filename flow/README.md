## Decisions

Asset decimals can’t be passed in create function because one may create a fake stream with less or more decimals and in
this way he may extract more assets from stream.

We store the asset decimals, so that we don't have to make an external call to get the decimals of the asset each time a
deposit or an extraction is made. Decimals are `uint8`, meaning it is not an expensive operation to store them.

Recipient address **must** be checked because there is no NFT minted in `_create` function.

Sender address **must** be checked because there is no ERC20 transfer in `_create` function.

In `_cancel` function we can perform both sender and recipient ERC20 transfers because there is no NFT so we don’t have
to worry about [this issue](https://github.com/cantinasec/review-sablier/issues/11).

## Invariants:

_balance ≥ withdrawable amount + refundable amount_

_lastTimeUpdate ≤ block.timestamp;_

_if(isCanceled = true) then balance= 0_

_if(isCanceled = true) then amountPerSecond= 0_

_sum of withdrawn amounts ≤ sum of deposits_

## Issues:

- Amount per second precision for tokens with less decimals: if one wants to stream 10 USDC per day the
  `amountPerSecond` should be 0.00011574074074 but USDC having 6 decimals it would be 0.000115, resulting 9.936 at the
  end of the month. (0.064 loss at the end of the month)
  - Potential solution: normalization to 18 decimals for all stored amounts, i.e. `stream.amountPerSecond` and
    `stream.balance` (attempting this fix in
    [this branch](https://github.com/sablier-labs/v2-open-ended/tree/fix/amount-per-second-precision) )

## Questions:

Should we update the time in `_cancel`?

In `_cancel` who should receive(sender or recipient) the remainder in case of rounding issues?

Should we add TimeUpdated event?

Should we add pausable functionality? It would be basically a cancel function

### TODOs:

- createMultiple
- withdrawMultiple
- add broker fees and protocol fees (implicitely comptroller + adminable contract)
  - The fee should be on `create` or on `deposit` ? both?
- explain what is different
- explain how it works
