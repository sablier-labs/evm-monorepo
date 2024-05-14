# Benchmarks for LockupDynamic

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15704     |
| `cancel`                                                   | 71840     |
| `renounce`                                                 | 41020     |
| `createWithDurations` (2 segments) (Broker fee set)        | 199085    |
| `createWithDurations` (2 segments) (Broker fee not set)    | 183577    |
| `createWithTimestamps` (2 segments) (Broker fee set)       | 183277    |
| `createWithTimestamps` (2 segments) (Broker fee not set)   | 178569    |
| `withdraw` (2 segments) (After End Time) (by Recipient)    | 19077     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)   | 27735     |
| `withdraw` (2 segments) (After End Time) (by Anyone)       | 13973     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)      | 27431     |
| `createWithDurations` (10 segments) (Broker fee set)       | 390783    |
| `createWithDurations` (10 segments) (Broker fee not set)   | 386082    |
| `createWithTimestamps` (10 segments) (Broker fee set)      | 380798    |
| `createWithTimestamps` (10 segments) (Broker fee not set)  | 376105    |
| `withdraw` (10 segments) (After End Time) (by Recipient)   | 14264     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)  | 32678     |
| `withdraw` (10 segments) (After End Time) (by Anyone)      | 13980     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)     | 32374     |
| `createWithDurations` (100 segments) (Broker fee set)      | 2705160   |
| `createWithDurations` (100 segments) (Broker fee not set)  | 2701423   |
| `createWithTimestamps` (100 segments) (Broker fee set)     | 2606849   |
| `createWithTimestamps` (100 segments) (Broker fee not set) | 2603145   |
| `withdraw` (100 segments) (After End Time) (by Recipient)  | 14264     |
| `withdraw` (100 segments) (Before End Time) (by Recipient) | 88561     |
| `withdraw` (100 segments) (After End Time) (by Anyone)     | 13960     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)    | 88257     |
