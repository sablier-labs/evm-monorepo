# Benchmarks for Lockup Linear Model

| Implementation                                                | Gas Usage |
| ------------------------------------------------------------- | --------- |
| `burn`                                                        | 15791     |
| `cancel`                                                      | 65885     |
| `renounce`                                                    | 27466     |
| `createWithDurationsLL` (Broker fee set) (cliff not set)      | 133431    |
| `createWithDurationsLL` (Broker fee not set) (cliff not set)  | 117148    |
| `createWithDurationsLL` (Broker fee set) (cliff set)          | 163961    |
| `createWithDurationsLL` (Broker fee not set) (cliff set)      | 158978    |
| `createWithTimestampsLL` (Broker fee set) (cliff not set)     | 118944    |
| `createWithTimestampsLL` (Broker fee not set) (cliff not set) | 113957    |
| `createWithTimestampsLL` (Broker fee set) (cliff set)         | 163481    |
| `createWithTimestampsLL` (Broker fee not set) (cliff set)     | 158494    |
| `withdraw` (After End Time) (by Recipient)                    | 29508     |
| `withdraw` (Before End Time) (by Recipient)                   | 21608     |
| `withdraw` (After End Time) (by Anyone)                       | 24764     |
| `withdraw` (Before End Time) (by Anyone)                      | 21420     |
