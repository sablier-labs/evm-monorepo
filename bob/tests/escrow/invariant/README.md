### List of Invariants Implemented in [Invariant.t.sol](./Invariant.t.sol)

1. For a given filled order,

   - For sell token, amount transferred to buyer + amount transferred to comptroller = sell amount.
   - For buy token, amount transferred to seller + amount transferred to comptroller = fill amount.

2. For a given sell token, contract balance = $`\sum`$ sell amount of all open and expired orders.

3. For a given order, only one of `wasFilled` or `wasCanceled` can be true.
