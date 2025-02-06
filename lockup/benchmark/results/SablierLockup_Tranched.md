# Benchmarks for the Lockup Tranched model

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 16053     |
| `cancel`                                                   | 65293     |
| `renounce`                                                 | 27655     |
| `createWithDurationsLT` (2 tranches)                       | 203624    |
| `createWithTimestampsLT` (2 tranches)                      | 190027    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)    | 33976     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)   | 18481     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)       | 18865     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)      | 18570     |
| `createWithDurationsLT` (10 tranches)                      | 406767    |
| `createWithTimestampsLT` (10 tranches)                     | 389988    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)   | 18764     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)  | 25381     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)      | 23400     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)     | 25470     |
| `createWithDurationsLT` (100 tranches)                     | 2800057   |
| `createWithTimestampsLT` (100 tranches)                    | 2641130   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)  | 23296     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient) | 103233    |
| `withdraw` (100 tranches) (After End Time) (by Anyone)     | 74597     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)    | 103322    |
