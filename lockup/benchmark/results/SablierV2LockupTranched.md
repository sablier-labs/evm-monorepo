# Benchmarks for LockupTranched

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15738     |
| `cancel`                                                   | 63994     |
| `renounce`                                                 | 26495     |
| `createWithDurations` (2 tranches) (Broker fee set)        | 199538    |
| `createWithDurations` (2 tranches) (Broker fee not set)    | 183973    |
| `createWithTimestamps` (2 tranches) (Broker fee set)       | 195734    |
| `createWithTimestamps` (2 tranches) (Broker fee not set)   | 190260    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)    | 20102     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)   | 14797     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)       | 15201     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)      | 14695     |
| `createWithDurations` (10 tranches) (Broker fee set)       | 388774    |
| `createWithDurations` (10 tranches) (Broker fee not set)   | 384017    |
| `createWithTimestamps` (10 tranches) (Broker fee set)      | 403722    |
| `createWithTimestamps` (10 tranches) (Broker fee not set)  | 398385    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)   | 17857     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)  | 19616     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)      | 17763     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)     | 19514     |
| `createWithDurations` (100 tranches) (Broker fee set)      | 2673124   |
| `createWithDurations` (100 tranches) (Broker fee not set)  | 2668870   |
| `createWithTimestamps` (100 tranches) (Broker fee set)     | 2747871   |
| `createWithTimestamps` (100 tranches) (Broker fee not set) | 2744348   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)  | 46746     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient) | 73989     |
| `withdraw` (100 tranches) (After End Time) (by Anyone)     | 46644     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)    | 73887     |
