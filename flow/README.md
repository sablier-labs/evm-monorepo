## Sablier V2 Open-Ended

This repository contains the smart contracts for the EOES (EVM open-ended streams) concept. By open-ended, we mean that
the streams have no fixed duration and no deposit amount at stream creation. This concept is primarily beneficial for
salaries and not for vesting or airdrops, where lockups are more appropriate.

### Motivation

One of the most requested feature from Sablier users is the ability to create streams without depositing the full amount
at start, i.e. the top-up functionality, which introduces the idea of _debt_ . This is enabled by the introduction of an
internal balance and a rate-per-second in the Stream entity:

```solidity
  struct Stream {
      uint128 balance;
      uint128 ratePerSecond;
      /// rest of the types
  }
```

### New features

- Top up, which are public (you can ask a friend to deposit money for you instead)
- No deposits are required at the time of stream creation; thus, creation and deposit are distinct operations.
- There are no deposit limits.
- Streams can be created for an indefinite period, they will be collecting debt until the sender deposits or pauses the
  stream.
- Ability to pause and restart streams.
- The sender can refund from the stream balance at any time.
  - This is only possible when the stream balance exceeds the withdrawable amount. For example, if a stream has a
    balance of 100 DAI and a withdrawable amount of 50 DAI, the sender can refund up to 50 DAI from the stream.

### How it works

As mentioned above, the creation and deposit operations are distinct. This means that the balance is set to 0 when a
stream is created, and deposits are made afterward. However, a `createAndDeposit` function is implemented to maintain
the same user experience.

Since the streams are open-ended, we don't have a start time nor an end time, instead we have a time reference
(`lastTimeUpdate`) which will be set to `block.timestamp` at the creation of the stream. There are several actions that
will update this time reference:

- when a withdrawal is made

  - `lastTimeUpdate` will be set to the given `time` parameter passed in the function, you can see why this parameter is
    needed in the explantion from [this PR](https://github.com/sablier-labs/v2-open-ended/pull/4)

- when the rate per second is changed
  - `lastTimeUpdate` will be set to `block.timestamp`, this time update is required in the `_adjustRatePerSecond`
    function because it would cause loss of funds for the recipient if the previous rate was higher or gain of funds if
    the previous rate was lower
- when the stream is restarted
  - `lastTimeUpdate` will be set to `block.timestamp`

### Amounts calculation

#### Streamed amount

The streamed amount (sa) is calculated simply by multiplying the rate per second (rps) by the delta between the current
time and the time stored in the stream `lastTimeUpdate` (ltu):

$\ sa = rps \times (now - ltu) \$

_sa_ can be higher than the balance, this explaines the _debt_ I was referring to. The _debt_ is the difference between
_sa_ and the actual balance - which is **not** stored in the contracts but calculated dynamically in a view function.

#### Withdrawable amount

The withdrawable amount is actually the streamed amount when there is no debt or the balance itself when there is debt.

#### Refundable amount

The refundable amount is calculated by subtracting the streamed amount from the balance.

#### Abbreviation table

| Full Name          | Abbreviation |
| ------------------ | ------------ |
| lastTimeUpdate     | ltu          |
| block.timestamp    | now          |
| balance            | bal          |
| ratePerSecond      | rps          |
| remainingAmount    | ra           |
| streamedAmount     | sa           |
| debt               | debt         |
| withdrawableAmount | wa           |
| refundableAmount   | rfa          |

### Issues:

Due to the lack of a fixed duration and a fixed deposit amount, the rate per second (rps) introduces a precision problem
for assets with fewer decimals (e.g. [USDC](https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48s),
which has 6 decimals).

Let's consider this example: If someone wants to stream 10 USDC per day, the _rps_ should be

$\ rps = 0.000115740740740740740740... \$(with many decimals)

But since USDC only has 6 decimals, the _rps_ would be limited to $\ rps = 0.000115 \$, this leads to $\ 0.000115 \times
oneDayInSeconds = 9.936000 \$, at the end of the day, resulting less with $\ 0.064000 \$.

As you can see this is problematic.

#### How to prevent this

In the contracts we normalize to 18 decimals all internal amounts, i.e. the _rps_ and the balance. While this doesn't
completely solves the issue, it minimizes it significantly.

Using the above example (stream of 10 USDC per day), if the _rps_ has 18 decimals, at the end of the day the result
would be:

$\ 0.000115740740740740 \times oneDayInSeconds = 9.999999999999936000 \$

$\ 10.000000000000000000 - 9.999999999999936000 = 0.0000000000000064000 \$

An improvement by $\ \approx 10^{11} \$, this is not ideal but clearly much better.

It is important to mention that the funds will never be stuck on the contract, the recipient will just have to wait more
time to get that 10 per day "streamed", using the 18 decimals format would delay it to 1 more second:

$\ 0.000115740740740740 \times (oneDayInSeconds + 1 second) = 10.000115740740677000 \$

Currently, I don't think it's possible to address this precision problem entirely, given the nature of open-endedness.

### Technical decisions

We use 18 fixed-point numbers for all internal amounts and calcalation functions (`balance`, `ratePerSecond`,
`withdrawable`, `refundable` etc.) to avoid the overload of conversion to actual `ERC20` balances. The only time we
perform these conversions is during external calls to `ERC20`'s transfer/transferFrom, i.e. the deposit and extract
operations as you can see in contracts. When we perform these actions, we need to either increase or reduce the
calculated amount(`withdrawable` or `refundable`) based on the each asset decimals:

- if the asset has fewer decimals, the transfer amount is reduced
- if the asset has more decimals, the transfer amount is increased

Asset decimals can’t be passed in `create` function because one may create a fake stream with more decimals and in this
way he may extract more assets from stream.

We store the asset decimals, so that we don't have to make an external call to get the decimals of the asset each time a
deposit or an extraction is made. Decimals are `uint8`, meaning it is not an expensive to store them.

Sender address **must** be checked because there is no `ERC20` transfer in `_create` function.

### Invariants:

_wa ≤ bal_

_if(debt = 0) then wa = sa + ra_

_if(debt = 0 && isPaused = true) then wa = ra_

_if(debt > 0) then wa = bal_

_bal = sum of deposits - sum of withdrawals_

_sum of withdrawn amounts ≤ sum of deposits_

_sum of stream balances normalized to asset decimals ≤ asset.balanceOf(SablierV2OpenEnded)_

_ltu ≤ now_

_if(isPaused = true) then rps = 0_

### Actions Access Control:

| Action              | Sender | Recipient | Operator(s) |      Unknown User      |
| ------------------- | :----: | :-------: | :---------: | :--------------------: |
| AdjustRatePerSecond |   ✅   |    ❌     |     ❌      |           ❌           |
| Deposit             |   ✅   |    ✅     |     ✅      |           ✅           |
| RefundFromStream    |   ✅   |    ❌     |     ❌      |           ❌           |
| RestartStream       |   ✅   |    ❌     |     ❌      |           ❌           |
| Pause               |   ✅   |    ❌     |     ❌      |           ❌           |
| Transfer NFT        |   ❌   |    ✅     |     ✅      |           ❌           |
| Withdraw            |   ✅   |    ✅     |     ✅      | ✅ (only to Recipient) |
