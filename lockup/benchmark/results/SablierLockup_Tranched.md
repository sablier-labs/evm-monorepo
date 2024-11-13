# Benchmarks for Lockup Tranched

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 15737     |
| `cancel`                                                     | 69877     |
| `renounce`                                                   | 37913     |
| `createWithDurationsLT` (2 tranches) (Broker fee set)        | 209326    |
| `createWithDurationsLT` (2 tranches) (Broker fee not set)    | 193271    |
| `createWithTimestampsLT` (2 tranches) (Broker fee set)       | 190646    |
| `createWithTimestampsLT` (2 tranches) (Broker fee not set)   | 185889    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)      | 19081     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)     | 17705     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)         | 14337     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)        | 17761     |
| `createWithDurationsLT` (10 tranches) (Broker fee set)       | 409136    |
| `createWithDurationsLT` (10 tranches) (Broker fee not set)   | 404389    |
| `createWithTimestampsLT` (10 tranches) (Broker fee set)      | 391945    |
| `createWithTimestampsLT` (10 tranches) (Broker fee not set)  | 387200    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)     | 14287     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)    | 26509     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)        | 14344     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)       | 26565     |
| `createWithDurationsLT` (100 tranches) (Broker fee set)      | 2819059   |
| `createWithDurationsLT` (100 tranches) (Broker fee not set)  | 2814813   |
| `createWithTimestampsLT` (100 tranches) (Broker fee set)     | 2658722   |
| `createWithTimestampsLT` (100 tranches) (Broker fee not set) | 2654477   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)    | 14268     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient)   | 126282    |
| `withdraw` (100 tranches) (After End Time) (by Anyone)       | 14324     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)      | 126338    |
