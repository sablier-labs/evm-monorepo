# Benchmarks for BatchLockup

| Function                 | Lockup Type     | Segments/Tranches | Batch Size | Gas Usage |
| ------------------------ | --------------- | ----------------- | ---------- | --------- |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 5          | 937003    |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 5          | 898916    |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 5          | 4123217   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 5          | 3895052   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 5          | 4013105   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 5          | 3822707   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 10         | 1740955   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 10         | 1747416   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 10         | 8202890   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 10         | 7741699   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 10         | 7974447   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 10         | 7597402   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 20         | 3433786   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 20         | 3447467   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 20         | 16380960  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 20         | 15440827  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 20         | 15896070  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 20         | 15152551  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 30         | 5125959   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 30         | 5155292   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 30         | 24603376  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 30         | 23157026  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 30         | 23818565  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 30         | 22725003  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 50         | 8532644   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 50         | 8582221   |
| `createWithDurationsLD`  | Lockup Dynamic  | 12                | 50         | 24275049  |
| `createWithTimestampsLD` | Lockup Dynamic  | 12                | 50         | 23058857  |
| `createWithDurationsLT`  | Lockup Tranched | 12                | 50         | 23611123  |
| `createWithTimestampsLT` | Lockup Tranched | 12                | 50         | 22718936  |
