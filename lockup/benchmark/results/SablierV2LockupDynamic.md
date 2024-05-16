# Benchmarks for LockupDynamic

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15675     |
| `cancel`                                                   | 71687     |
| `renounce`                                                 | 40893     |
| `createWithDurations` (2 segments) (Broker fee set)        | 198964    |
| `createWithDurations` (2 segments) (Broker fee not set)    | 183487    |
| `createWithTimestamps` (2 segments) (Broker fee set)       | 183160    |
| `createWithTimestamps` (2 segments) (Broker fee not set)   | 178483    |
| `withdraw` (2 segments) (After End Time) (by Recipient)    | 19001     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)   | 27557     |
| `withdraw` (2 segments) (After End Time) (by Anyone)       | 13904     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)      | 27260     |
| `createWithDurations` (10 segments) (Broker fee set)       | 390614    |
| `createWithDurations` (10 segments) (Broker fee not set)   | 385944    |
| `createWithTimestamps` (10 segments) (Broker fee set)      | 380649    |
| `createWithTimestamps` (10 segments) (Broker fee not set)  | 375987    |
| `withdraw` (10 segments) (After End Time) (by Recipient)   | 14188     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)  | 32500     |
| `withdraw` (10 segments) (After End Time) (by Anyone)      | 13911     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)     | 32203     |
| `createWithDurations` (100 segments) (Broker fee set)      | 2704451   |
| `createWithDurations` (100 segments) (Broker fee not set)  | 2700745   |
| `createWithTimestamps` (100 segments) (Broker fee set)     | 2606340   |
| `createWithTimestamps` (100 segments) (Broker fee not set) | 2602667   |
| `withdraw` (100 segments) (After End Time) (by Recipient)  | 14188     |
| `withdraw` (100 segments) (Before End Time) (by Recipient) | 88383     |
| `withdraw` (100 segments) (After End Time) (by Anyone)     | 13891     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)    | 88086     |
