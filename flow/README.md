## Sablier V2 Open-Ended

This repository contains the smart contracts for the EOES (EVM open-ended streams) product. By open-ended, we mean that
the streams have no fixed duration. This product is primarily beneficial for salaries and not for vesting or airdrops,
where lockups are more appropriate.

### Motivation

One of the most requested feature from Sablier users is the ability to create streams without depositing the full amount
at start, i.e. the top-up functionality, which introduces the idea of _debt_ . This has been made possible by
introducing an internal balance in the Stream entity:

```solidity
  struct Stream {
      uint128 balance;
      /// rest of the types
  }
```

### Features

- Top up, which are public (you can ask a friend to deposit money for you instead)
- No deposits are required at the time of stream creation; thus, creation and deposit are distinct operations.
- There are no deposit limits.
- Streams can be created for an indefinite period, they will be collecting debt until the sender cancels the stream.
- Ability to pause and restart streams.
- The sender can refund from the stream balance at any time.
  - This is only possible when the stream balance exceeds the withdrawable amount. For example, if a stream has a
    balance of 100 DAI and a withdrawable amount of 50 DAI, the sender can refund up to 50 DAI from the stream.

### Issues:

Due to the lack of a fixed duration and a fixed deposit amount, we must store a rate per second in the Stream entity,
which introduces a precision problem for assets with fewer decimals (e.g.
[USDC](https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48s), which has 6 decimals).

Let's consider this example: If someone wants to stream 10 USDC per day, the rate per second should be
0.000115740740740740740740... (with many decimals), but since USDC only has 6 decimals, the rate per second would be
limited to _0.000115_. This leads to _0.000115\*one_day_in_seconds = 9.936000_ at the end of the day, resulting in a
_0.064000_ loss each day. As you can see this is problematic.

#### How to prevent this

In the contracts we normalize to 18 decimals all internal amounts, i.e. the rate per second and the balance. While this
doesn't completely solves the issue, it minimizes it significantly.

Using the above example (stream of 10 USDC per day), if the rate per seconds has 18 decimals, at the end of the day the
result would be _0.000115740740740740\*one_day_in_seconds = 9.999999999999936000_. A _0.0000000000000064000_ loss at the
end of each day. This is not ideal but clearly much better, especially if you do the math: _0.000000000002336_ loss at
the end of the year.

Currently, I don't think it's possible to address this precision problem entirely, given the nature of open-endedness.

### Technical decisions

We use 18 fixed-point numbers for all internal amounts (`balance`, `ratePerSecond`, `withdrawable`, `refundable`) to
avoid the overload of conversion to actual `ERC20` balances. The only time we perform these conversions is during
external calls, i.e. the deposit and extract operations.

We need to either increase or reduce the calculated amount based on the each asset decimals:

- if the asset has fewer decimals, the transfer amount is reduced
- if the asset has more decimals, the transfer amount is increased

Asset decimals can’t be passed in `create` function because one may create a fake stream with more decimals and in this
way he may extract more assets from stream.

We store the asset decimals, so that we don't have to make an external call to get the decimals of the asset each time a
deposit or an extraction is made. Decimals are `uint8`, meaning it is not an expensive operation to store them.

Recipient address **must** be checked because there is no NFT minted in `_create` function.

Sender address **must** be checked because there is no `ERC20` transfer in `_create` function.

In `_cancel` function we can perform both sender and recipient `ERC20` transfers because there is no NFT so we don’t
have to worry about [this issue](https://github.com/cantinasec/review-sablier/issues/11).

### Invariants:

_balance = withdrawable amount + refundable amount_

_withdrawable amount ≤ streamed amount_

_lastTimeUpdate ≤ block.timestamp;_

_if(isCanceled = true) then balance= 0 && ratePerSecond= 0_

_sum of withdrawn amounts ≤ sum of deposits_

_sum of stream balances normilized to asset decimals ≤ asset.balanceOf(SablierV2OpenEnded)_

### Questions:

Should we update the time in `_cancel`?

Should we add `TimeUpdated` event?

Should we add `pause` function? Basically it would be a duplication of `cancel` function.

### TODOs:

- createMultiple
- withdrawMultiple
- add broker fees and protocol fees (implicitely comptroller + adminable contract)
  - The fee should be on `create` or on `deposit` ? both?
