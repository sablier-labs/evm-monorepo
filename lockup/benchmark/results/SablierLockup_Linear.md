# Benchmarks for Lockup Linear

| Implementation                                                | Gas Usage |
| ------------------------------------------------------------- | --------- |
| `burn`                                                        | 15737     |
| `cancel`                                                      | 69877     |
| `renounce`                                                    | 37913     |
| `createWithDurationsLL` (Broker fee set) (cliff not set)      | 131096    |
| `createWithDurationsLL` (Broker fee not set) (cliff not set)  | 115013    |
| `createWithDurationsLL` (Broker fee set) (cliff set)          | 139355    |
| `createWithDurationsLL` (Broker fee not set) (cliff set)      | 134567    |
| `createWithTimestampsLL` (Broker fee set) (cliff not set)     | 116775    |
| `createWithTimestampsLL` (Broker fee not set) (cliff not set) | 111988    |
| `createWithTimestampsLL` (Broker fee set) (cliff set)         | 139034    |
| `createWithTimestampsLL` (Broker fee not set) (cliff set)     | 134244    |
| `withdraw` (After End Time) (by Recipient)                    | 29468     |
| `withdraw` (Before End Time) (by Recipient)                   | 23600     |
| `withdraw` (After End Time) (by Anyone)                       | 24724     |
| `withdraw` (Before End Time) (by Anyone)                      | 20646     |
