# Benchmarks for Lockup Tranched Model

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 15759     |
| `cancel`                                                     | 68674     |
| `renounce`                                                   | 37726     |
| `createWithDurationsLT` (2 tranches) (Broker fee set)        | 209043    |
| `createWithDurationsLT` (2 tranches) (Broker fee not set)    | 192794    |
| `createWithTimestampsLT` (2 tranches) (Broker fee set)       | 191023    |
| `createWithTimestampsLT` (2 tranches) (Broker fee not set)   | 186072    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)      | 19035     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)     | 16714     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)         | 14292     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)        | 16770     |
| `createWithDurationsLT` (10 tranches) (Broker fee set)       | 408861    |
| `createWithDurationsLT` (10 tranches) (Broker fee not set)   | 403916    |
| `createWithTimestampsLT` (10 tranches) (Broker fee set)      | 392335    |
| `createWithTimestampsLT` (10 tranches) (Broker fee not set)  | 387399    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)     | 14235     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)    | 23465     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)        | 14298     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)       | 23521     |
| `createWithDurationsLT` (100 tranches) (Broker fee set)      | 2818875   |
| `createWithDurationsLT` (100 tranches) (Broker fee not set)  | 2814433   |
| `createWithTimestampsLT` (100 tranches) (Broker fee set)     | 2659191   |
| `createWithTimestampsLT` (100 tranches) (Broker fee not set) | 2654768   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)    | 14222     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient)   | 99780     |
| `withdraw` (100 tranches) (After End Time) (by Anyone)       | 14278     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)      | 99836     |
