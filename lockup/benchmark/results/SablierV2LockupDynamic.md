# Benchmarks for LockupDynamic

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15716     |
| `cancel`                                                   | 74341     |
| `renounce`                                                 | 39001     |
| `createWithDurations` (2 segments) (Broker fee set)        | 200605    |
| `createWithDurations` (2 segments) (Broker fee not set)    | 185039    |
| `createWithTimestamps` (2 segments) (Broker fee set)       | 184785    |
| `createWithTimestamps` (2 segments) (Broker fee not set)   | 180023    |
| `withdraw` (2 segments) (After End Time) (by Recipient)    | 19109     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)   | 27554     |
| `withdraw` (2 segments) (After End Time) (by Anyone)       | 14241     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)      | 27485     |
| `createWithDurations` (10 segments) (Broker fee set)       | 395105    |
| `createWithDurations` (10 segments) (Broker fee not set)   | 390350    |
| `createWithTimestamps` (10 segments) (Broker fee set)      | 385155    |
| `createWithTimestamps` (10 segments) (Broker fee not set)  | 380410    |
| `withdraw` (10 segments) (After End Time) (by Recipient)   | 14295     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)  | 32545     |
| `withdraw` (10 segments) (After End Time) (by Anyone)      | 14249     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)     | 32476     |
| `createWithDurations` (100 segments) (Broker fee set)      | 2741072   |
| `createWithDurations` (100 segments) (Broker fee not set)  | 2737309   |
| `createWithTimestamps` (100 segments) (Broker fee set)     | 2643302   |
| `createWithTimestamps` (100 segments) (Broker fee not set) | 2639574   |
| `withdraw` (100 segments) (After End Time) (by Recipient)  | 14295     |
| `withdraw` (100 segments) (Before End Time) (by Recipient) | 88968     |
| `withdraw` (100 segments) (After End Time) (by Anyone)     | 14226     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)    | 88899     |
