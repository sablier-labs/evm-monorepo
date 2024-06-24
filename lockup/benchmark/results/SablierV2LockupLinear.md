# Benchmarks for LockupLinear

| Implementation                                              | Gas Usage |
| ----------------------------------------------------------- | --------- |
| `burn`                                                      | 15694     |
| `cancel`                                                    | 56829     |
| `renounce`                                                  | 19381     |
| `createWithDurations` (Broker fee set) (cliff not set)      | 129276    |
| `createWithDurations` (Broker fee not set) (cliff not set)  | 113680    |
| `createWithDurations` (Broker fee set) (cliff set)          | 138071    |
| `createWithDurations` (Broker fee not set) (cliff set)      | 133273    |
| `createWithTimestamps` (Broker fee set) (cliff not set)     | 115334    |
| `createWithTimestamps` (Broker fee not set) (cliff not set) | 110530    |
| `createWithTimestamps` (Broker fee set) (cliff set)         | 137629    |
| `createWithTimestamps` (Broker fee not set) (cliff set)     | 132827    |
| `withdraw` (After End Time) (by Recipient)                  | 29701     |
| `withdraw` (Before End Time) (by Recipient)                 | 19104     |
| `withdraw` (After End Time) (by Anyone)                     | 24799     |
| `withdraw` (Before End Time) (by Anyone)                    | 19002     |
