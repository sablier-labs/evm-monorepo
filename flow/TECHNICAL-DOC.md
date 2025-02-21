# Technical documentation

## How Flow works

One can create a flow stream without any upfront deposit, so the initial stream balance begins at zero. The sender can
later deposit any amount into the stream at any time. To improve the experience, a `createAndDeposit` function has also
been implemented to allow both create and deposit in a single transaction.

One can also start a stream without setting an rps. If rps is set to non-zero at the beginning, it begins streaming as
soon as the transaction is confirmed on the blockchain. These streams have no end date, but it allows the sender to
pause it or void it at a later date.

A stream is represented by a struct, which can be found in
[`DataTypes.sol`](https://github.com/sablier-labs/flow/blob/ba1c9ba64907200c82ccfaeaa6ab91f6229c433d/src/types/DataTypes.sol#L41-L76).

The debt is tracked using "snapshot debt" and "snapshot time". At snapshot, the following events are taking place:

1. snapshot debt is incremented by ongoing debt where
   $\text{ongoing debt} = rps \cdot (\text{block timestamp} - \text{snapshot time})$.
2. snapshot time is updated to block timestamp.

The recipient can withdraw the streamed amount at any point. However, if there aren't sufficient funds, the recipient
can only withdraw the available balance.

## Abbreviations

| Terms                       | Abbreviations |
| --------------------------- | ------------- |
| Block Timestamp             | now           |
| Covered Debt                | cd            |
| Ongoing Debt                | od            |
| Rate per second             | rps           |
| Refundable Amount           | ra            |
| Scale Factor                | sf            |
| Snapshot Debt               | sd            |
| Snapshot Time               | st            |
| Stream Balance              | bal           |
| Time elapsed since snapshot | elt           |
| Total Debt                  | td            |
| Uncovered Debt              | ud            |
| Witdrawable Amount          | wa            |

## Access Control

| Action              |         Sender         | Recipient | Operator(s) |      Unknown User      |
| ------------------- | :--------------------: | :-------: | :---------: | :--------------------: |
| AdjustRatePerSecond |           ✅           |    ❌     |     ❌      |           ❌           |
| Deposit             |           ✅           |    ✅     |     ✅      |           ✅           |
| Pause               |           ✅           |    ❌     |     ❌      |           ❌           |
| Refund              |           ✅           |    ❌     |     ❌      |           ❌           |
| Restart             |           ✅           |    ❌     |     ❌      |           ❌           |
| Transfer NFT        |           ❌           |    ✅     |     ✅      |           ❌           |
| Void                |           ✅           |    ✅     |     ✅      |           ❌           |
| Withdraw            | ✅ (only to Recipient) |    ✅     |     ✅      | ✅ (only to Recipient) |

## Invariants

1. for any token:

   - $\sum$ stream balances = aggregate balance
   - token.balanceOf(SablierFlow) $`\ge \sum`$ stream balances
   - $\sum$ stream balances = $\sum$ deposited amount - $\sum$ refunded amount - $\sum$ withdrawn amount

2. for any token, token.balanceOf(SablierFlow) $\ge$ flow.aggregateBalance(token)

3. for any non-voided stream the snapshot time should never decrease

4. for any non-pending stream, $st \le now$

5. if $ud > 0 \implies cd = bal$

6. if $rps \gt 0$ and no deposits are made $\implies \frac{d(ud)}{dt} \ge 0$

7. if $rps \gt 0$, and no withdraw is made $\implies \frac{d(td)}{dt} \ge 0$

8. sum of deposited amounts $\ge$ sum of withdrawn amounts + sum of refunded

9. sum of all deposited amounts $\ge$ sum of all withdrawn amounts + sum of all refunded

10. next stream id = current stream id + 1

11. if $` ud = 0 \implies cd = td`$

12. $bal = ra + cd$

13. if $rps \gt 0 \implies isPaused = false$ and Flow.Status is either PENDING, STREAMING_SOLVENT or
    STREAMING_INSOLVENT.

14. for any non-voided stream, if $rps = 0 \implies isPaused = true$ and Flow.Status is either PAUSED_SOLVENT or
    PAUSED_INSOLVENT.

15. for any PENDING stream, $rps > 0$ and $td = 0$

16. if $isPaused = true \implies rps = 0$

17. if $isVoided = true \implies isPaused = true$ and $ud = 0$

18. if $isVoided = false \implies \text{expected amount streamed} = td + \text{amount withdrawn}$

## Limitation

- ERC-20 tokens with decimals higher than 18 are not supported.

## Core components

### 1. Ongoing debt

The ongoing debt (od) is the debt accrued since the last snapshot. It is defined as the rate per second (rps) multiplied
by the time elapsed since the snapshot time.

$od = rps \cdot elt = rps \cdot (now - st)$

### 2. Snapshot debt

The snapshot debt (sd) is the amount that the sender owed to the recipient at the snapshot time. During a snapshot, the
snapshot debt increases by the ongoing debt.

$sd = sd + od$

### 3. Total debt

The total debt (td) is the total amount the sender owes to the recipient. It is calculated as the sum of the snapshot
debt and the ongoing debt.

$td = sd + od$

### 4. Covered debt

The part of the total debt that covered by the stream balance. This is the same as the withdrawable amount, which is an
alias.

The covered debt (cd) is defined as the minimum of the total debt and the stream balance.

$`cd = \begin{cases} td & \text{if } td \le bal \\ bal & \text{if } td \gt bal \end{cases}`$

### 5. Uncovered debt

The part of the total debt that is not covered by the stream balance. This is what the sender owes to the stream.

The uncovered debt (ud) is defined as the difference between the total debt and the stream balance, applicable only when
the total debt exceeds the balance.

$`ud = \begin{cases} td - bal & \text{if } td \gt bal \\ 0 & \text{if } td \le bal \end{cases}`$

Together, covered debt and uncovered debt make up the total debt.

### 6. Refundable amount

The refundable amount (ra) is the amount that can be refunded to the sender. It is defined as the difference between the
stream balance and the total debt.

$`ra = \begin{cases} bal - td & \text{if } ud = 0 \\ 0 & \text{if } ud > 0 \end{cases}`$

## About precision

The `rps` introduces a precision problem for tokens with fewer decimals (e.g.
[USDC](https://etherscan.io/token/0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48s), which has 6 decimals).

Let's consider an example: if a user wants to stream 10 USDC per day, the _rps_ should be:

$rps = 0.000115740740740740740740 \text{...}$ (infinite decimals)

But since USDC only has 6 decimals, the _rps_ would be limited to $0.000115$, leading to
$0.000115 \cdot \text{seconds in one day} = 9.936000$ USDC streamed in one day. This results in a shortfall of
$0.064000$ USDC per day, which is problematic.

## Defining rps as 18-decimal fixed point number

In the contracts, we scale the rate per second to 18 decimals. While this doesn't completely solve the issue, it
significantly minimizes it.

<a name="10-per-day-example"></a> Using the same example (streaming 10 USDC per day), if _rps_ has 18 decimals, the
end-of-day result would be:

$0.000115740740740740 \cdot \text{seconds in one day} = 9.999999999999936000$

The difference would be:

$10.000000000000000000 - 9.999999999999936000 = 0.000000000000006400$

This is an improvement by $\approx 10^{11}$. While not perfect, it is clearly much better as the recipient may have to
wait just a bit longer to receive the full 10 USDC per day. Using the 18 decimals format would delay it by just 1 more
second:

$0.000115740740740740 \cdot (\text{seconds in one day} + 1 second) = 10.000115740740677000$

Currently, it's not possible to address this precision problem entirely.

<!-- prettier-ignore -->
> [!IMPORTANT]
> The issues described in this section, as well as those discussed below,
> will not lead to a loss of funds but may affect the streaming experience for users.

### Problem 1: Relative delay

From the previous section, we can define the **Relative Delay** as the minimum period (in seconds) that a N-decimal
`rps` system would require to stream the same amount of tokens that the 18-decimal `rps` system would.

```math
\text{relative\_delay}_N = \frac{ (rps_{18} - rps_N) }{rps_N} \cdot T_{\text{interval}}
```

In a 6-decimal `rps` system, for the `rps` values provided in the example [above](#10-per-day-example), we can calculate
the relative delay over a one-day period as follows:

```math
\text{relative\_delay}_6 = \frac{ (0.000115740740740740 - 0.000115)}{0.000115} \cdot 86400 \approx 556 \, \text{seconds}
```

Similarly, relative delays for other time intervals can be calculated:

- 7 days: ~1 hour, 5 minutes
- 30 days: ~4 hours, 38 minutes
- 1 year: ~2 days, 8 hours

### Problem 2: Minimum Transferable Value

**Minimum Transferable Value (MVT)** is defined as the smallest amount of tokens that can be transferred. In an
N-decimal `rps` system, the MVT cannot be less than 1 token. For example, in case of USDC, the MVT is `0.000001e6`,
which is would to stream `0.0864e6` USDC per day. If we were to stream a high priced token, such as a wrapped Bitcoin
with 6 decimals, then such system could not allow users to stream less than `0.0864e6 WBTC = $5184` per day (price taken
at $60,000 per BTC).

By using an 18-decimal `rps` system, we can allow streaming of amount less than Minimum Transferable Value.

### Conclusion

The above issues are inherent to **all** decimal systems, and get worse as the number of decimals used to represent
`rps` decreases. Therefore, we took the decision to define `rps` as an 18-decimal number so that it can minimize, if not
rectify, the above two problems. Along with this, we also need to consider the following:

- Store snapshot debt in 18-decimals fixed point number.
- Calculate ongoing debt in 18-decimals fixed point number.
- Convert the total debt from 18-decimals to the token's decimals before calculating the withdrawable amount.
