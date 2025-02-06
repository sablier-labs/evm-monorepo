# Benchmarks for the Lockup Linear model

| Implementation                              | Gas Usage |
| ------------------------------------------- | --------- |
| `burn`                                      | 16053     |
| `cancel`                                    | 65293     |
| `renounce`                                  | 27655     |
| `createWithDurationsLL` (cliff not set)     | 121163    |
| `createWithDurationsLL` (cliff set)         | 163149    |
| `createWithTimestampsLL` (cliff not set)    | 117841    |
| `createWithTimestampsLL` (cliff set)        | 162424    |
| `withdraw` (After End Time) (by Recipient)  | 33157     |
| `withdraw` (Before End Time) (by Recipient) | 23281     |
| `withdraw` (After End Time) (by Anyone)     | 29539     |
| `withdraw` (Before End Time) (by Anyone)    | 22793     |
