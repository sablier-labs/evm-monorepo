# Benchmarks for LockupTranched

| Implementation                                             | Gas Usage |
| ---------------------------------------------------------- | --------- |
| `burn`                                                     | 15738     |
| `cancel`                                                   | 63994     |
| `renounce`                                                 | 26501     |
| `createWithDurations` (2 tranches) (Broker fee set)        | 199536    |
| `createWithDurations` (2 tranches) (Broker fee not set)    | 183969    |
| `createWithTimestamps` (2 tranches) (Broker fee set)       | 189410    |
| `createWithTimestamps` (2 tranches) (Broker fee not set)   | 183945    |
| `withdraw` (2 tranches) (After End Time) (by Recipient)    | 20100     |
| `withdraw` (2 tranches) (Before End Time) (by Recipient)   | 14797     |
| `withdraw` (2 tranches) (After End Time) (by Anyone)       | 15199     |
| `withdraw` (2 tranches) (Before End Time) (by Anyone)      | 14695     |
| `createWithDurations` (10 tranches) (Broker fee set)       | 388757    |
| `createWithDurations` (10 tranches) (Broker fee not set)   | 383998    |
| `createWithTimestamps` (10 tranches) (Broker fee set)      | 397102    |
| `createWithTimestamps` (10 tranches) (Broker fee not set)  | 391750    |
| `withdraw` (10 tranches) (After End Time) (by Recipient)   | 17855     |
| `withdraw` (10 tranches) (Before End Time) (by Recipient)  | 19616     |
| `withdraw` (10 tranches) (After End Time) (by Anyone)      | 17760     |
| `withdraw` (10 tranches) (Before End Time) (by Anyone)     | 19514     |
| `createWithDurations` (100 tranches) (Broker fee set)      | 2672918   |
| `createWithDurations` (100 tranches) (Broker fee not set)  | 2668643   |
| `createWithTimestamps` (100 tranches) (Broker fee set)     | 2738297   |
| `createWithTimestamps` (100 tranches) (Broker fee not set) | 2734635   |
| `withdraw` (100 tranches) (After End Time) (by Recipient)  | 46746     |
| `withdraw` (100 tranches) (Before End Time) (by Recipient) | 73989     |
| `withdraw` (100 tranches) (After End Time) (by Anyone)     | 46644     |
| `withdraw` (100 tranches) (Before End Time) (by Anyone)    | 73887     |
