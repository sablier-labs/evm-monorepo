# Benchmarks for the Lockup Dynamic model

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 16053     |
| `cancel`                                                   | 65293     |
| `renounce`                                                 | 27655     |
| `createWithDurationsLD` (2 segments)                       | 205831    |
| `createWithTimestampsLD` (2 segments)                      | 190867    |
| `withdraw` (2 segments) (After End Time) (by Recipient)    | 33976     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)   | 29881     |
| `withdraw` (2 segments) (After End Time) (by Anyone)       | 19151     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)      | 29970     |
| `createWithDurationsLD` (10 segments)                      | 415957    |
| `createWithTimestampsLD` (10 segments)                     | 395232    |
| `withdraw` (10 segments) (After End Time) (by Recipient)   | 19050     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)  | 37168     |
| `withdraw` (10 segments) (After End Time) (by Anyone)      | 24250     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)     | 37257     |
| `createWithDurationsLD` (100 segments)                     | 2891124   |
| `createWithTimestampsLD` (100 segments)                    | 2697533   |
| `withdraw` (100 segments) (After End Time) (by Recipient)  | 24145     |
| `withdraw` (100 segments) (Before End Time) (by Recipient) | 119581    |
| `withdraw` (100 segments) (After End Time) (by Anyone)     | 81987     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)    | 119670    |
