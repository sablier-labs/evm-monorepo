# Benchmarks for BatchLockup

| Function                 | Lockup Type     | Segments/Tranches | Batch Size | Gas Usage |
| ------------------------ | --------------- | ----------------- | ---------- | --------- |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 5          | 770796    |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 5          | 730532    |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 5          | 3935335   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 5          | 3797841   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 5          | 3844973   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 5          | 3726799   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 10         | 1413200   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 10         | 1410133   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 10         | 7785667   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 10         | 7547946   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 10         | 7596904   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 10         | 7406060   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 20         | 2775981   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 20         | 2771033   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 20         | 15547587  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 20         | 15056228  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 20         | 15143062  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 20         | 14770870  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 30         | 4133268   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 30         | 4136198   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 30         | 23351853  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 30         | 22583299  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 30         | 22691758  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 30         | 22152793  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 50         | 6854756   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 50         | 6872537   |
| `createWithDurationsLD`  | Lockup Dynamic  | 12                | 50         | 22883512  |
| `createWithTimestampsLD` | Lockup Dynamic  | 12                | 50         | 22241640  |
| `createWithDurationsLT`  | Lockup Tranched | 12                | 50         | 22314003  |
| `createWithTimestampsLT` | Lockup Tranched | 12                | 50         | 21891398  |
