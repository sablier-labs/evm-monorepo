### List of Invariants Implemented in [Invariant.t.sol](./Invariant.t.sol)

1. For a given filled order,

   - For sell token, amount transferred to buyer + amount transferred to comptroller = sell amount.
   - For buy token, amount transferred to seller + amount transferred to comptroller = fill amount.

2. For a given sell token, contract balance = $`\sum`$ sell amount of all open and expired orders.

3. (Inv 36) On cancellation, the full `sellAmount` must be returned to the seller.

4. (Inv 50) `wasFilled` and `wasCanceled` must never both be true for the same order.
