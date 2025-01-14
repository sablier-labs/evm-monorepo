# Benchmarks for the Lockup Linear model

| Implementation                                                | Gas Usage |
| ------------------------------------------------------------- | --------- |
| `burn`                                                        | 16141     |
| `cancel`                                                      | 65381     |
| `renounce`                                                    | 27721     |
| `createWithDurationsLL` (Broker fee set) (cliff not set)      | 138649    |
| `createWithDurationsLL` (Broker fee not set) (cliff not set)  | 122287    |
| `createWithDurationsLL` (Broker fee set) (cliff set)          | 169335    |
| `createWithDurationsLL` (Broker fee not set) (cliff set)      | 164278    |
| `createWithTimestampsLL` (Broker fee set) (cliff not set)     | 125100    |
| `createWithTimestampsLL` (Broker fee not set) (cliff not set) | 120038    |
| `createWithTimestampsLL` (Broker fee set) (cliff set)         | 169682    |
| `createWithTimestampsLL` (Broker fee not set) (cliff set)     | 164614    |
| `withdraw` (After End Time) (by Recipient)                    | 33179     |
| `withdraw` (Before End Time) (by Recipient)                   | 23303     |
| `withdraw` (After End Time) (by Anyone)                       | 29561     |
| `withdraw` (Before End Time) (by Anyone)                      | 22815     |
