# Benchmarks for LockupTranched

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15713     |
| `cancel`                                                   | 61537     |
| `renounce`                                                 | 28738     |
| `createWithDurations` (2 tranches) (Broker fee set)        | 198066    |
| `createWithDurations` (2 tranches) (Broker fee not set)    | 182587    |
| `createWithTimestamps` (2 tranches) (Broker fee set)       | 187974    |
| `createWithTimestamps` (2 tranches) (Broker fee not set)   | 182597    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)    | 20204     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)   | 15009     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)       | 15108     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)      | 14712     |
| `createWithDurations` (10 tranches) (Broker fee set)       | 385207    |
| `createWithDurations` (10 tranches) (Broker fee not set)   | 380536    |
| `createWithTimestamps` (10 tranches) (Broker fee set)      | 393650    |
| `createWithTimestamps` (10 tranches) (Broker fee not set)  | 388386    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)   | 17959     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)  | 19892     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)      | 17669     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)     | 19595     |
| `createWithDurations` (100 tranches) (Broker fee set)      | 2645968   |
| `createWithDurations` (100 tranches) (Broker fee not set)  | 2641781   |
| `createWithTimestamps` (100 tranches) (Broker fee set)     | 2712165   |
| `createWithTimestamps` (100 tranches) (Broker fee not set) | 2708591   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)  | 46850     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient) | 74985     |
| `withdraw` (100 tranches) (After End Time) (by Anyone)     | 46553     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)    | 74688     |
