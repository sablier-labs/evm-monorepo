# Benchmarks for the Lockup Dynamic model

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 16141     |
| `cancel`                                                     | 65381     |
| `renounce`                                                   | 27721     |
| `createWithDurationsLD` (2 segments) (Broker fee set)        | 216788    |
| `createWithDurationsLD` (2 segments) (Broker fee not set)    | 200461    |
| `createWithTimestampsLD` (2 segments) (Broker fee set)       | 197652    |
| `createWithTimestampsLD` (2 segments) (Broker fee not set)   | 192627    |
| `withdraw` (2 segments) (After End Time) (by Recipient)      | 23885     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)     | 29903     |
| `withdraw` (2 segments) (After End Time) (by Anyone)         | 19175     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)        | 29992     |
| `createWithDurationsLD` (10 segments) (Broker fee set)       | 422199    |
| `createWithDurationsLD` (10 segments) (Broker fee not set)   | 417189    |
| `createWithTimestampsLD` (10 segments) (Broker fee set)      | 402125    |
| `createWithTimestampsLD` (10 segments) (Broker fee not set)  | 397126    |
| `withdraw` (10 segments) (After End Time) (by Recipient)     | 24167     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)    | 37190     |
| `withdraw` (10 segments) (After End Time) (by Anyone)        | 24278     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)       | 37279     |
| `createWithDurationsLD` (100 segments) (Broker fee set)      | 2898563   |
| `createWithDurationsLD` (100 segments) (Broker fee not set)  | 2894573   |
| `createWithTimestampsLD` (100 segments) (Broker fee set)     | 2706641   |
| `createWithTimestampsLD` (100 segments) (Broker fee not set) | 2702660   |
| `withdraw` (100 segments) (After End Time) (by Recipient)    | 81920     |
| `withdraw` (100 segments) (Before End Time) (by Recipient)   | 119603    |
| `withdraw` (100 segments) (After End Time) (by Anyone)       | 82009     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)      | 119692    |
