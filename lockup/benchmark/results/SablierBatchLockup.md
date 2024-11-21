# Benchmarks for BatchLockup

| Function                 | Lockup Type     | Segments/Tranches | Batch Size | Gas Usage |
| ------------------------ | --------------- | ----------------- | ---------- | --------- |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 5          | 903159    |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 5          | 861441    |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 5          | 4120769   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 5          | 3891095   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 5          | 3996698   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 5          | 3809816   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 10         | 1673021   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 10         | 1672189   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 10         | 8197426   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 10         | 7733344   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 10         | 7941453   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 10         | 7571162   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 20         | 3296857   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 20         | 3295805   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 20         | 16367660  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 20         | 15422847  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 20         | 15829541  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 20         | 15098785  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 30         | 4918016   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 30         | 4924864   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 30         | 24577948  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 30         | 23127215  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 30         | 23717265  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 30         | 22641404  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 50         | 8178730   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 50         | 8190836   |
| `createWithDurationsLD`  | Lockup Dynamic  | 12                | 50         | 24075414  |
| `createWithTimestampsLD` | Lockup Dynamic  | 12                | 50         | 22851294  |
| `createWithDurationsLT`  | Lockup Tranched | 12                | 50         | 23330071  |
| `createWithTimestampsLT` | Lockup Tranched | 12                | 50         | 22477363  |
