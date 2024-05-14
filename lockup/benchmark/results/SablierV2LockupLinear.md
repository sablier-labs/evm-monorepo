# Benchmarks for LockupLinear

| Implementation                                              | Gas Usage |
| ----------------------------------------------------------- | --------- |
| `burn`                                                      | 15695     |
| `cancel`                                                    | 54245     |
| `renounce`                                                  | 21373     |
| `createWithDurations` (Broker fee set) (cliff not set)      | 127827    |
| `createWithDurations` (Broker fee not set) (cliff not set)  | 112288    |
| `createWithDurations` (Broker fee set) (cliff set)          | 136615    |
| `createWithDurations` (Broker fee not set) (cliff set)      | 131874    |
| `createWithTimestamps` (Broker fee set) (cliff not set)     | 113929    |
| `createWithTimestamps` (Broker fee not set) (cliff not set) | 109182    |
| `createWithTimestamps` (Broker fee set) (cliff set)         | 136217    |
| `createWithTimestamps` (Broker fee not set) (cliff set)     | 131472    |
| `withdraw` (After End Time) (by Recipient)                  | 29618     |
| `withdraw` (Before End Time) (by Recipient)                 | 19100     |
| `withdraw` (After End Time) (by Anyone)                     | 24514     |
| `withdraw` (Before End Time) (by Anyone)                    | 18796     |
