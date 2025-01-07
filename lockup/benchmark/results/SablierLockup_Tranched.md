# Benchmarks for the Lockup Tranched model

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 15791     |
| `cancel`                                                     | 65885     |
| `renounce`                                                   | 27466     |
| `createWithDurationsLT` (2 tranches) (Broker fee set)        | 209723    |
| `createWithDurationsLT` (2 tranches) (Broker fee not set)    | 193473    |
| `createWithTimestampsLT` (2 tranches) (Broker fee set)       | 191747    |
| `createWithTimestampsLT` (2 tranches) (Broker fee not set)   | 186795    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)      | 19121     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)     | 16808     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)         | 14378     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)        | 16864     |
| `createWithDurationsLT` (10 tranches) (Broker fee set)       | 409546    |
| `createWithDurationsLT` (10 tranches) (Broker fee not set)   | 404601    |
| `createWithTimestampsLT` (10 tranches) (Broker fee set)      | 393063    |
| `createWithTimestampsLT` (10 tranches) (Broker fee not set)  | 388126    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)     | 14321     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)    | 23704     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)        | 14384     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)       | 23760     |
| `createWithDurationsLT` (100 tranches) (Broker fee set)      | 2819619   |
| `createWithDurationsLT` (100 tranches) (Broker fee not set)  | 2815177   |
| `createWithTimestampsLT` (100 tranches) (Broker fee set)     | 2659961   |
| `createWithTimestampsLT` (100 tranches) (Broker fee not set) | 2655537   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)    | 14308     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient)   | 101639    |
| `withdraw` (100 tranches) (After End Time) (by Anyone)       | 14364     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)      | 101695    |
