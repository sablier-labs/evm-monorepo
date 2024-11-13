# Benchmarks for BatchLockup

| Function                 | Lockup Type     | Segments/Tranches | Batch Size | Gas Usage |
| ------------------------ | --------------- | ----------------- | ---------- | --------- |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 5          | 779252    |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 5          | 737531    |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 5          | 4119940   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 5          | 3888761   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 5          | 3995338   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 5          | 3804250   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 10         | 1425098   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 10         | 1424116   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 10         | 8190322   |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 10         | 7728484   |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 10         | 7938702   |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 10         | 7559817   |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 20         | 2799677   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 20         | 2798898   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 20         | 16351825  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 20         | 15412578  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 20         | 15824057  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 20         | 15075556  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 30         | 4168931   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 30         | 4177876   |
| `createWithDurationsLD`  | Lockup Dynamic  | 24                | 30         | 24550618  |
| `createWithTimestampsLD` | Lockup Dynamic  | 24                | 30         | 23110560  |
| `createWithDurationsLT`  | Lockup Tranched | 24                | 30         | 23709058  |
| `createWithTimestampsLT` | Lockup Tranched | 24                | 30         | 22605337  |
| `createWithDurationsLL`  | Lockup Linear   | N/A               | 50         | 6914041   |
| `createWithTimestampsLL` | Lockup Linear   | N/A               | 50         | 6941746   |
| `createWithDurationsLD`  | Lockup Dynamic  | 12                | 50         | 24037239  |
| `createWithTimestampsLD` | Lockup Dynamic  | 12                | 50         | 22827992  |
| `createWithDurationsLT`  | Lockup Tranched | 12                | 50         | 23314745  |
| `createWithTimestampsLT` | Lockup Tranched | 12                | 50         | 22415432  |
