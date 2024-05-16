# Benchmarks for LockupLinear

| Implementation                                              | Gas Usage |
| ----------------------------------------------------------- | --------- |
| `burn`                                                      | 15669     |
| `cancel`                                                    | 54116     |
| `renounce`                                                  | 21338     |
| `createWithDurations` (Broker fee set) (cliff not set)      | 127727    |
| `createWithDurations` (Broker fee not set) (cliff not set)  | 112219    |
| `createWithDurations` (Broker fee set) (cliff set)          | 136514    |
| `createWithDurations` (Broker fee not set) (cliff set)      | 131804    |
| `createWithTimestamps` (Broker fee set) (cliff not set)     | 113830    |
| `createWithTimestamps` (Broker fee not set) (cliff not set) | 109114    |
| `createWithTimestamps` (Broker fee set) (cliff set)         | 136117    |
| `createWithTimestamps` (Broker fee not set) (cliff set)     | 131403    |
| `withdraw` (After End Time) (by Recipient)                  | 29557     |
| `withdraw` (Before End Time) (by Recipient)                 | 19032     |
| `withdraw` (After End Time) (by Anyone)                     | 24460     |
| `withdraw` (Before End Time) (by Anyone)                    | 18735     |
