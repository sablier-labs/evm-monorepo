### List of Invariants Implemented in [Invariant.t.sol](./Invariant.t.sol)

1. Next stream id = Current stream id + 1

1. For a token:
   - Aggregate amount = (Total deposited - Total refunded - Total withdrawn)
   - token.balanceOf(lockup) $`\ge`$ (Total deposited - Total refunded - Total withdrawn)

1. For a stream:
   - Deposited amount $`\ge`$ Streamed amount
   - Deposited amount $`\ge`$ Withdrawable amount
   - Deposited amount $`\ge`$ Withdrawn amount
   - Deposited amount $`\ge`$ 0
   - End time > Start time
   - Start time $`\ge`$ 0
   - Streamed amount $`\ge`$ Withdrawable amount
   - Streamed amount $`\ge`$ Withdrawn amount

1. For a canceled stream:
   - Refunded amount > 0
   - Stream should not be cancelable anymore
   - Refundable amount = 0
   - Withdrawable amount > 0

1. For a depleted stream:
   - Withdrawn amount = (Deposited amount - Refunded amount)
   - Stream should not be cancelable anymore
   - Refundable amount = 0
   - Withdrawable amount = 0

1. For a pending stream:
   - Refunded amount = 0
   - Withdrawn amount = 0
   - Refundable amount = Deposited amount
   - Streamed amount = 0
   - Withdrawable amount = 0

1. For a settled stream:
   - Refunded amount = 0
   - Stream should not be cancelable anymore
   - Refundable amount = 0
   - Streamed amount = Deposited amount

1. For a streaming stream:
   - Refunded amount = 0
   - Streamed amount < Deposited amount

1. State transitions:
   - PENDING $`\not\to`$ DEPLETED
   - STREAMING $`\not\to`$ PENDING
   - SETTLED $`\not\to`$ { PENDING, STREAMING, CANCELED }
   - CANCELED $`\not\to`$ { PENDING, STREAMING, SETTLED }
   - DEPLETED $`\to`$ DEPLETED

1. For a Dynamic stream, segment timestamps should be strictly increasing.

1. For a Linear stream,
   - If Cliff time > 0, $`\implies`$ Cliff time > Start time.
   - End time > Cliff time

1. For a Tranched stream, tranche timestamps should be strictly increasing.
