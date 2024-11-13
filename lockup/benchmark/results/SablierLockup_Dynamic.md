# Benchmarks for Lockup Dynamic

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 15737     |
| `cancel`                                                     | 69877     |
| `renounce`                                                   | 37913     |
| `createWithDurationsLD` (2 segments) (Broker fee set)        | 211048    |
| `createWithDurationsLD` (2 segments) (Broker fee not set)    | 194992    |
| `createWithTimestampsLD` (2 segments) (Broker fee set)       | 191907    |
| `createWithTimestampsLD` (2 segments) (Broker fee not set)   | 187158    |
| `withdraw` (2 segments) (After End Time) (by Recipient)      | 19081     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)     | 28414     |
| `withdraw` (2 segments) (After End Time) (by Anyone)         | 14337     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)        | 28470     |
| `createWithDurationsLD` (10 segments) (Broker fee set)       | 418495    |
| `createWithDurationsLD` (10 segments) (Broker fee not set)   | 413754    |
| `createWithTimestampsLD` (10 segments) (Broker fee set)      | 398397    |
| `createWithTimestampsLD` (10 segments) (Broker fee not set)  | 393659    |
| `withdraw` (10 segments) (After End Time) (by Recipient)     | 14268     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)    | 35941     |
| `withdraw` (10 segments) (After End Time) (by Anyone)        | 14345     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)       | 35997     |
| `createWithDurationsLD` (100 segments) (Broker fee set)      | 2917762   |
| `createWithDurationsLD` (100 segments) (Broker fee not set)  | 2914004   |
| `createWithTimestampsLD` (100 segments) (Broker fee set)     | 2725623   |
| `createWithTimestampsLD` (100 segments) (Broker fee not set) | 2721888   |
| `withdraw` (100 segments) (After End Time) (by Recipient)    | 14268     |
| `withdraw` (100 segments) (Before End Time) (by Recipient)   | 121045    |
| `withdraw` (100 segments) (After End Time) (by Anyone)       | 14324     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)      | 121101    |
