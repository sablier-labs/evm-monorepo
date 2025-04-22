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

6. For any stream, if rps $\gt$ 0 $\implies$ Flow.Status $\in$ {PENDING, STREAMING_SOLVENT, STREAMING_INSOLVENT}.

7. For any stream, if rps $\gt$ 0, and no withdraw is made $\implies \frac{d(td)}{dt} \ge 0$

8. For any stream, if rps $\gt$ 0 and no deposits are made $\implies \frac{d(ud)}{dt} \ge 0$

9. For any non-voided stream, if rps = 0 $\implies$ Flow.Status $\in$ {PAUSED_SOLVENT, PAUSED_INSOLVENT}

10. For any stream:

    - If previous status is not pending, the current status should not be pending.
    - If previous status is pending, the current status should neither be paused-solvent nor paused-insolvent.
    - If previous status is paused-solvent, the current status should not be paused-insolvent.
    - If previous status is voided, the current status should also be voided.

11. For any non-pending stream, st $\le$ now.

12. For any non-voided stream, the snapshot time should never decrease

13. For any non-voided stream, total streams = total debt + total withdrawals.

14. For any pending stream, rps > 0 and td = 0

15. For any paused stream, rps = 0.

16. For any voided stream, ud = 0

17. ud = 0 $\implies$ cd = td

18. ud > 0 $\implies$ cd = bal
