# Benchmarks for BatchLockup

| Function                 | Lockup Type     | Segments/Tranches | Batch Size | Gas Usage |
| ------------------------ | --------------- | ----------------- | ---------- | --------- |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 5          | 928890    |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 5          | 885308    |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 5          | 4113825   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 5          | 3882573   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 5          | 3996547   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 5          | 3809398   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 10         | 1724494   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 10         | 1719878   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 10         | 8182888   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 10         | 7715546   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 10         | 7940495   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 10         | 7569104   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 20         | 3399923   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 20         | 3391255   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 20         | 16336489  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 20         | 15385080  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 20         | 15826078  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 20         | 15092338  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 30         | 5068344   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 30         | 5068237   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 30         | 24526058  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 30         | 23065957  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 30         | 23709972  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 30         | 22626325  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 50         | 8424832   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 50         | 8430179   |
| `createWithDurationsLD`  | Lockup Dynamic  | 12                | 50         | 24147020  |
| `createWithTimestampsLD` | Lockup Dynamic  | 12                | 50         | 22896172  |
| `createWithDurationsLT`  | Lockup Tranched | 12                | 50         | 23417003  |
| `createWithTimestampsLT` | Lockup Tranched | 12                | 50         | 22542212  |
