### List of Invariants Implemented in [Flow.t.sol](./Flow.t.sol)

1. For any token:

   - token.balanceOf(SablierFlow) $`\ge`$ aggregate amount
   - token.balanceOf(SablierFlow) $`\ge \sum`$ stream balances
   - $\sum$ stream balances = aggregate amount
   - $\sum$ stream balances = $\sum$ deposited amount - $\sum$ refunded amount - $\sum$ withdrawn amount

2. For any stream, total deposits $\ge$ total withdrawals + total refunds

3. For any token, total deposits $\ge$ total withdrawals + total refunds

4. next stream id = current stream id + 1

5. For any stream, stream balance = covered debt + refundable amount

6. For any stream, if isPaused = true $\implies$ rps = 0

7. For any stream, if rps $\gt$ 0 $\implies$ isPaused = false and Flow.Status $\in$ {PENDING, STREAMING_SOLVENT,
   STREAMING_INSOLVENT}.

8. For any stream, if rps $\gt$ 0, and no withdraw is made $\implies \frac{d(td)}{dt} \ge 0$

9. For any stream, if rps $\gt$ 0 and no deposits are made $\implies \frac{d(ud)}{dt} \ge 0$

10. For any non-voided stream, if rps = 0 $\implies$ isPaused = true and Flow.Status $\in$ {PAUSED_SOLVENT,
    PAUSED_INSOLVENT}

11. For any non-pending stream, st $\le$ now.

12. For any non-voided stream, the snapshot time should never decrease

13. For any non-voided stream, total streams = total debt + total withdrawals.

14. For any pending stream, rps > 0 and td = 0

15. For any paused stream, rps = 0.

16. For any voided stream, isPaused = true and ud = 0

17. ud = 0 $\implies$ cd = td

18. ud > 0 $\implies$ cd = bal
