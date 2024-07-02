# Sablier Flow

This repository contains the smart contracts for Sablier Flow. Streams created with Sablier Flow have no end time and
require no upfront deposit. This is ideal for regular payments such as salaries and subscriptions, where an end time is
not specified. For vesting or airdrops, refer to [our Lockup protocol](https://github.com/sablier-labs/v2-core/).

## Motivation

One of the most requested features from users is the ability to create streams without an upfront deposit. This requires
the protocol to manage _"debt"_, which is the amount the sender owes the recipient but is not yet available in the
stream. The following struct defines a Flow stream:

```solidity
struct Stream {
  uint128 balance;
  uint128 ratePerSecond;
  address sender;
  uint40 lastTimeUpdate;
  bool isStream;
  bool isPaused;
  bool isTransferable;
  IERC20 asset;
  uint8 assetDecimals;
  uint128 remainingAmount;
}
```

## Features

- Streams can be created indefinitely.
- No deposits are required at creation; thus, creation and deposit are separate operations.
- Anyone can deposit into a stream, allowing others to fund your streams.
- No limit on deposits; any amount can be deposited or refunded if not yet streamed to recipients.
- Streams without sufficient balance will accumulate debt until paused or sufficiently funded.
- Senders can pause and restart streams without losing track of debt and the amount owed to the recipient.

## How It Works

When a stream is created, no deposit is required, so the initial stream balance can be zero. The sender can deposit any
amount into the stream at any time. To improve experience for some users, a `createAndDeposit` function has been
implemented to allow both create and deposit operations in a single transaction.

Streams begin streaming as soon as the transaction is confirmed on the blockchain. They have no end date, but the sender
can pause the stream at any time. This stops the streaming of assets but retains the record of the amount owed to the
recipient up to that point.

The `lastTimeUpdate` value, set to `block.timestamp` when the stream is created, is crucial for tracking the amount owed
over time. The recipient can withdraw the streamed amount at any point. If there are insufficient funds in the stream,
the recipient can only withdraw the available balance.

## Abbreviations

| Full Name          | Abbreviation |
| ------------------ | ------------ |
| amount owed        | ao           |
| balance            | bal          |
| block.timestamp    | now          |
| debt               | debt         |
| lastTimeUpdate     | ltu          |
| ratePerSecond      | rps          |
| recentAmount       | rca          |
| refundableAmount   | rfa          |
| remainingAmount    | ra           |
| withdrawableAmount | wa           |

## Core Components

### 1. Recent amount

The recent amount (rca) is calculated as the rate per second (rps) multiplied by the delta between the current time and
`lastTimeUpdate`.

$rca = rps \times (now - ltu)$

### 2. Remaining amount

The remaining amount (ra) is the amount that the sender owed to the recipient until the last time update. When
`lastTimeUpdate` is updated, the remaining amount increases by the recent amount.

$ra = \sum rca_t$

### 3. Amount Owed

The amount owed (ao) is the total amount the sender owes to the recipient. It is calculated as the sum of the remaining
amount and the recent amount.

$ao = ra + rca$

### 4. Debt

The debt is the difference between the amount owed and the actual balance, applicable when the amount owed exceeds the
balance.

$`debt = \begin{cases} ao - bal & \text{if } ao \gt bal \\ 0 & \text{if } ao \le bal \end{cases}`$

### 5. Withdrawable amount

The withdrawable amount (wa) is the amount owed when there is no debt. If there is debt, the withdrawable amount is the
stream balance

$`wa = \begin{cases} ao & \text{if } debt = 0 \\ bal & \text{if } debt \gt 0 \end{cases}`$

### 6. Refundable amount

The refundable amount (rfa) is the amount that the sender can refund from the stream. It is the difference between the
stream balance and the amount owed

$`rfa = \begin{cases} bal - ao & \text{if } debt = 0 \\ 0 & \text{if } debt > 0 \end{cases}`$

## Precision Issues

The `rps` introduces a precision problem for assets with fewer decimals (e.g.
[USDC](https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48s), which has 6 decimals).

Let's consider an example: if a user wants to stream 10 USDC per day, the _rps_ should be

$rps = 0.000115740740740740740740...$ (infinite decimals)

But since USDC only has 6 decimals, the _rps_ would be limited to $0.000115$, leading to
$0.000115 \times \text{seconds in one day} = 9.936000$ USDC streamed in one day. This results in a shortfall of
$0.064000$ USDC per day, which is problematic

### Solution

In the contracts, we normalize all internal amounts (e.g. `rps`, `bal`, `ra`, `ao`) to 18 decimals. While this doesn't
completely solve the issue, it significantly minimizes it.

Using the same example (streaming 10 USDC per day), if _rps_ has 18 decimals, the end-of-day result would be:

$0.000115740740740740 \times \text{seconds in one day} = 9.999999999999936000$

The difference would be:

$10.000000000000000000 - 9.999999999999936000 = 0.000000000000006400$

This is an improvement by $\approx 10^{11}$. While not perfect, it is clearly much better.

The funds will never be stuck in the contract; the recipient may have to wait a bit longer to receive the full 10 USDC
per day. Using the 18 decimals format would delay it by just 1 more second:

$0.000115740740740740 \times (\text{seconds in one day} + 1 second) = 10.000115740740677000$

Currently, it's not possible to address this precision problem entirely.

### Technical Implementaion

We use 18 fixed-point numbers for all internal amounts and calculation functions to avoid the overload of conversion to
actual `ERC20` balances. The only time we perform these conversions is during external calls to `ERC20`'s
`transfer`/`transferFrom` (i.e. deposit, withdraw and refund operations). When performing these actions, we adjust the
calculated amount (withdrawable or refundable) based on the asset's decimals:

Deposit:

- if the asset has 18 decimals, the internal deposited amount remains same as the transfer amount
- if the asset has fewer decimals, the internal deposited amount is increased by the difference between the asset
  decimals and 18

Withdraw and Refund:

- if the asset has 18 decimals, the transfer amount is the same as the internal amount
- if the asset has fewer decimals, the transfer amount is decreased by the difference between 18 and asset decimals

Asset decimal is retrieved directly from the ERC20 contract. We store the asset decimals to avoid making an external
call to get the decimals of the asset each time a deposit or withdraw is made. Decimals are stored as `uint8`, making
them inexpensive to store.

### Limitations

- ERC20 tokens with decimals higher than 18 are not supported.

## Invariants

1. for any stream, $ltu \le now$

2. for a given asset, $\sum$ stream balances normalized to asset decimal $\leq$ asset.balanceOf(SablierFlow)

3. for any stream, if $debt > 0 \implies wa = bal$

4. if $rps \gt 0$ and no deposits are made $\implies \frac{d(debt)}{dt} \ge 0$

5. if $rps \gt 0$, and no withdraw is made $\implies \frac{d(ao)}{dt} \ge 0$

6. for any stream, sum of deposited amounts $\ge$ sum of withdrawn amounts + sum of refunded

7. sum of all deposited amounts $\ge$ sum of all withdrawn amounts + sum of all refunded

8. next stream id = current stream id + 1

9. if $debt = 0$ and $isPaused = true \implies wa = ra$

10. if $debt = 0$ and $isPaused = false \implies wa = ra + rca$

11. $bal = rfa + wa$

12. if $isPaused = true \implies rps = 0$
