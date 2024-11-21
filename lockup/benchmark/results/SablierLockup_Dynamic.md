# Benchmarks for Lockup Dynamic Model

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 15791     |
| `cancel`                                                     | 65885     |
| `renounce`                                                   | 27466     |
| `createWithDurationsLD` (2 segments) (Broker fee set)        | 211605    |
| `createWithDurationsLD` (2 segments) (Broker fee not set)    | 195353    |
| `createWithTimestampsLD` (2 segments) (Broker fee set)       | 192136    |
| `createWithTimestampsLD` (2 segments) (Broker fee not set)   | 187185    |
| `withdraw` (2 segments) (After End Time) (by Recipient)      | 19121     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)     | 28328     |
| `withdraw` (2 segments) (After End Time) (by Anyone)         | 14377     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)        | 28384     |
| `createWithDurationsLD` (10 segments) (Broker fee set)       | 419147    |
| `createWithDurationsLD` (10 segments) (Broker fee not set)   | 414209    |
| `createWithTimestampsLD` (10 segments) (Broker fee set)      | 398718    |
| `createWithTimestampsLD` (10 segments) (Broker fee not set)  | 393783    |
| `withdraw` (10 segments) (After End Time) (by Recipient)     | 14308     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)    | 35631     |
| `withdraw` (10 segments) (After End Time) (by Anyone)        | 14385     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)       | 35687     |
| `createWithDurationsLD` (100 segments) (Broker fee set)      | 2919492   |
| `createWithDurationsLD` (100 segments) (Broker fee not set)  | 2915538   |
| `createWithTimestampsLD` (100 segments) (Broker fee set)     | 2727003   |
| `createWithTimestampsLD` (100 segments) (Broker fee not set) | 2723074   |
| `withdraw` (100 segments) (After End Time) (by Recipient)    | 14308     |
| `withdraw` (100 segments) (Before End Time) (by Recipient)   | 118217    |
| `withdraw` (100 segments) (After End Time) (by Anyone)       | 14364     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)      | 118273    |
