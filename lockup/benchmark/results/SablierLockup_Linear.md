# Benchmarks for Lockup Linear Model

| Implementation                                                | Gas Usage |
| ------------------------------------------------------------- | --------- |
| `burn`                                                        | 15759     |
| `cancel`                                                      | 68674     |
| `renounce`                                                    | 37726     |
| `createWithDurationsLL` (Broker fee set) (cliff not set)      | 131057    |
| `createWithDurationsLL` (Broker fee not set) (cliff not set)  | 114740    |
| `createWithDurationsLL` (Broker fee set) (cliff set)          | 139354    |
| `createWithDurationsLL` (Broker fee not set) (cliff set)      | 134336    |
| `createWithTimestampsLL` (Broker fee set) (cliff not set)     | 116950    |
| `createWithTimestampsLL` (Broker fee not set) (cliff not set) | 111929    |
| `createWithTimestampsLL` (Broker fee set) (cliff set)         | 139254    |
| `createWithTimestampsLL` (Broker fee not set) (cliff set)     | 134231    |
| `withdraw` (After End Time) (by Recipient)                    | 29422     |
| `withdraw` (Before End Time) (by Recipient)                   | 22353     |
| `withdraw` (After End Time) (by Anyone)                       | 24678     |
| `withdraw` (Before End Time) (by Anyone)                      | 20457     |
