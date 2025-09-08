### List of Invariants Implemented in [Flow.t.sol](./Flow.t.sol)

1. Next stream id = Current stream id + 1

1. For any token:
   - token.balanceOf(SablierFlow) $`\ge`$ aggregate amount
   - token.balanceOf(SablierFlow) $`\ge \sum`$ stream balances
   - $\sum$ stream balances = aggregate amount
   - $\sum$ stream balances = $\sum$ deposited amount - $\sum$ refunded amount - $\sum$ withdrawn amount
   - total deposits $\ge$ total withdrawals + total refunds

1. For any stream:
   - total deposits $\ge$ total withdrawals + total refunds
   - stream balance = covered debt + refundable amount
   - if rps $\gt$ 0 $\implies$ Flow.Status $\in$ {PENDING, STREAMING_SOLVENT, STREAMING_INSOLVENT}.
   - if rps $\gt$ 0, and no withdraw is made $\implies \frac{d(td)}{dt} \ge 0$
   - if rps $\gt$ 0 and no deposits are made $\implies \frac{d(ud)}{dt} \ge 0$

1. For any non-pending stream, st $\le$ now.

1. For any non-voided stream,
   - if rps = 0 $\implies$ Flow.Status $\in$ {PAUSED_SOLVENT, PAUSED_INSOLVENT}
   - the snapshot time should never decrease
   - total streams = total debt + total withdrawals.

1. For any pending stream, rps > 0 and td = 0

1. For any paused stream, rps = 0.

1. For any voided stream, ud = 0

1. State transitions:
   - { STREAMING_SOLVENT, STREAMING_INSOLVENT, PAUSED_SOLVENT, PAUSED_INSOLVENT, VOIDED} $`\not\to`$ PENDING
   - PENDING $`\not\to`$ { PAUSED_SOLVENT, PAUSED_INSOLVENT }
   - PAUSED_SOLVENT $`\not\to`$ PAUSED_SOLVENT
   - VOIDED $`\to`$ VOIDED

1. ud = 0 $\implies$ cd = td

1. ud > 0 $\implies$ cd = bal
