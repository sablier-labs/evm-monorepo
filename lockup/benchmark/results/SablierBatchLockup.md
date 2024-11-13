# Benchmarks for BatchLockup

| Function                 | Lockup Type     | Segments/Tranches | Batch Size | Gas Usage |
| ------------------------ | --------------- | ----------------- | ---------- | --------- |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 5          | 778232    |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 5          | 738090    |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 5          | 4117172   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 5          | 3887412   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 5          | 3993178   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 5          | 3806069   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 10         | 1423058   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 10         | 1425240   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 10         | 8189792   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 10         | 7725792   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 10         | 7934383   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 10         | 7563478   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 20         | 2795598   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 20         | 2801161   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 20         | 16350772  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 20         | 15407205  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 20         | 15815419  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 20         | 15082887  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 30         | 4162811   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 30         | 4181289   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 30         | 24549048  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 30         | 23102525  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 30         | 23696100  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 30         | 22616357  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 50         | 6903841   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 50         | 6947495   |
| `createWithDurationsLD`  | Lockup Dynamic  | 12                | 50         | 24028066  |
| `createWithTimestampsLD` | Lockup Dynamic  | 12                | 50         | 22808040  |
| `createWithDurationsLT`  | Lockup Tranched | 12                | 50         | 23292554  |
| `createWithTimestampsLT` | Lockup Tranched | 12                | 50         | 22433243  |
