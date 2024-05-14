# Benchmarks for LockupTranched

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15739     |
| `cancel`                                                   | 61652     |
| `renounce`                                                 | 28759     |
| `createWithDurations` (2 tranches) (Broker fee set)        | 198189    |
| `createWithDurations` (2 tranches) (Broker fee not set)    | 182679    |
| `createWithTimestamps` (2 tranches) (Broker fee set)       | 188124    |
| `createWithTimestamps` (2 tranches) (Broker fee not set)   | 182715    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)    | 20258     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)   | 15063     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)       | 15155     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)      | 14759     |
| `createWithDurations` (10 tranches) (Broker fee set)       | 385386    |
| `createWithDurations` (10 tranches) (Broker fee not set)   | 380684    |
| `createWithTimestamps` (10 tranches) (Broker fee set)      | 393864    |
| `createWithTimestamps` (10 tranches) (Broker fee not set)  | 388568    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)   | 18013     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)  | 19946     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)      | 17716     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)     | 19642     |
| `createWithDurations` (100 tranches) (Broker fee set)      | 2646777   |
| `createWithDurations` (100 tranches) (Broker fee not set)  | 2642559   |
| `createWithTimestamps` (100 tranches) (Broker fee set)     | 2713099   |
| `createWithTimestamps` (100 tranches) (Broker fee not set) | 2709493   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)  | 46904     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient) | 75039     |
| `withdraw` (100 tranches) (After End Time) (by Anyone)     | 46600     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)    | 74735     |
