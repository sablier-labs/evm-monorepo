# Benchmarks for LockupDynamic

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15716     |
| `cancel`                                                   | 74341     |
| `renounce`                                                 | 39007     |
| `createWithDurations` (2 segments) (Broker fee set)        | 200602    |
| `createWithDurations` (2 segments) (Broker fee not set)    | 185037    |
| `createWithTimestamps` (2 segments) (Broker fee set)       | 184780    |
| `createWithTimestamps` (2 segments) (Broker fee not set)   | 180015    |
| `withdraw` (2 segments) (After End Time) (by Recipient)    | 19108     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)   | 27554     |
| `withdraw` (2 segments) (After End Time) (by Anyone)       | 14239     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)      | 27485     |
| `createWithDurations` (10 segments) (Broker fee set)       | 395084    |
| `createWithDurations` (10 segments) (Broker fee not set)   | 390326    |
| `createWithTimestamps` (10 segments) (Broker fee set)      | 385125    |
| `createWithTimestamps` (10 segments) (Broker fee not set)  | 380375    |
| `withdraw` (10 segments) (After End Time) (by Recipient)   | 14295     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)  | 32545     |
| `withdraw` (10 segments) (After End Time) (by Anyone)      | 14246     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)     | 32476     |
| `createWithDurations` (100 segments) (Broker fee set)      | 2740781   |
| `createWithDurations` (100 segments) (Broker fee not set)  | 2736987   |
| `createWithTimestamps` (100 segments) (Broker fee set)     | 2642946   |
| `createWithTimestamps` (100 segments) (Broker fee not set) | 2639185   |
| `withdraw` (100 segments) (After End Time) (by Recipient)  | 14295     |
| `withdraw` (100 segments) (Before End Time) (by Recipient) | 88968     |
| `withdraw` (100 segments) (After End Time) (by Anyone)     | 14226     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)    | 88899     |
