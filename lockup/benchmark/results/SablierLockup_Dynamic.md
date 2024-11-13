# Benchmarks for Lockup Dynamic Model

| Implementation                                               | Gas Usage |
| ------------------------------------------------------------ | --------- |
| `burn`                                                       | 15759     |
| `cancel`                                                     | 68674     |
| `renounce`                                                   | 37726     |
| `createWithDurationsLD` (2 segments) (Broker fee set)        | 210925    |
| `createWithDurationsLD` (2 segments) (Broker fee not set)    | 194672    |
| `createWithTimestampsLD` (2 segments) (Broker fee set)       | 191434    |
| `createWithTimestampsLD` (2 segments) (Broker fee not set)   | 186483    |
| `withdraw` (2 segments) (After End Time) (by Recipient)      | 19035     |
| `withdraw` (2 segments) (Before End Time) (by Recipient)     | 28249     |
| `withdraw` (2 segments) (After End Time) (by Anyone)         | 14291     |
| `withdraw` (2 segments) (Before End Time) (by Anyone)        | 28305     |
| `createWithDurationsLD` (10 segments) (Broker fee set)       | 418459    |
| `createWithDurationsLD` (10 segments) (Broker fee not set)   | 413521    |
| `createWithTimestampsLD` (10 segments) (Broker fee set)      | 398011    |
| `createWithTimestampsLD` (10 segments) (Broker fee not set)  | 393076    |
| `withdraw` (10 segments) (After End Time) (by Recipient)     | 14222     |
| `withdraw` (10 segments) (Before End Time) (by Recipient)    | 35552     |
| `withdraw` (10 segments) (After End Time) (by Anyone)        | 14299     |
| `withdraw` (10 segments) (Before End Time) (by Anyone)       | 35608     |
| `createWithDurationsLD` (100 segments) (Broker fee set)      | 2918719   |
| `createWithDurationsLD` (100 segments) (Broker fee not set)  | 2914766   |
| `createWithTimestampsLD` (100 segments) (Broker fee set)     | 2726237   |
| `createWithTimestampsLD` (100 segments) (Broker fee not set) | 2722308   |
| `withdraw` (100 segments) (After End Time) (by Recipient)    | 14222     |
| `withdraw` (100 segments) (Before End Time) (by Recipient)   | 118136    |
| `withdraw` (100 segments) (After End Time) (by Anyone)       | 14278     |
| `withdraw` (100 segments) (Before End Time) (by Anyone)      | 118192    |
