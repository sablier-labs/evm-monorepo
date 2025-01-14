# Benchmarks for the Lockup Tranched model

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 16141     |
| `cancel`                                                     | 65381     |
| `renounce`                                                   | 27721     |
| `createWithDurationsLT` (2 tranches) (Broker fee set)        | 215994    |
| `createWithDurationsLT` (2 tranches) (Broker fee not set)    | 199665    |
| `createWithTimestampsLT` (2 tranches) (Broker fee set)       | 196988    |
| `createWithTimestampsLT` (2 tranches) (Broker fee not set)   | 191964    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)      | 23599     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)     | 18503     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)         | 18889     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)        | 18592     |
| `createWithDurationsLT` (10 tranches) (Broker fee set)       | 414411    |
| `createWithDurationsLT` (10 tranches) (Broker fee not set)   | 409394    |
| `createWithTimestampsLT` (10 tranches) (Broker fee set)      | 397045    |
| `createWithTimestampsLT` (10 tranches) (Broker fee not set)  | 392026    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)     | 23318     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)    | 25403     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)        | 23427     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)       | 25492     |
| `createWithDurationsLT` (100 tranches) (Broker fee set)      | 2808652   |
| `createWithDurationsLT` (100 tranches) (Broker fee not set)  | 2804166   |
| `createWithTimestampsLT` (100 tranches) (Broker fee set)     | 2649659   |
| `createWithTimestampsLT` (100 tranches) (Broker fee not set) | 2645177   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)    | 74530     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient)   | 103255    |
| `withdraw` (100 tranches) (After End Time) (by Anyone)       | 74619     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)      | 103344    |
