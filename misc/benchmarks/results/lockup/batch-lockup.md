With WETH as the streaming token.

| Lockup Model | Function                 | Batch Size | Segments/Tranches | Gas Usage  |
| :----------- | :----------------------- | :--------- | :---------------- | :--------- |
| Linear       | `createWithDurationsLL`  | 5          | N/A               | 932,214    |
| Linear       | `createWithTimestampsLL` | 5          | N/A               | 881,168    |
| Dynamic      | `createWithDurationsLD`  | 5          | 24                | 4,123,784  |
| Dynamic      | `createWithTimestampsLD` | 5          | 24                | 3,889,173  |
| Tranched     | `createWithDurationsLT`  | 5          | 24                | 4,000,267  |
| Tranched     | `createWithTimestampsLT` | 5          | 24                | 3,812,529  |
| Linear       | `createWithDurationsLL`  | 10         | N/A               | 1,717,160  |
| Linear       | `createWithTimestampsLL` | 10         | N/A               | 1,711,202  |
| Dynamic      | `createWithDurationsLD`  | 10         | 24                | 8,202,650  |
| Dynamic      | `createWithTimestampsLD` | 10         | 24                | 7,728,482  |
| Tranched     | `createWithDurationsLT`  | 10         | 24                | 7,947,522  |
| Tranched     | `createWithTimestampsLT` | 10         | 24                | 7,575,444  |
| Linear       | `createWithDurationsLL`  | 20         | N/A               | 3,384,943  |
| Linear       | `createWithTimestampsLL` | 20         | N/A               | 3,373,595  |
| Dynamic      | `createWithDurationsLD`  | 20         | 24                | 16,376,109 |
| Dynamic      | `createWithTimestampsLD` | 20         | 24                | 15,410,578 |
| Tranched     | `createWithDurationsLT`  | 20         | 24                | 15,839,644 |
| Tranched     | `createWithTimestampsLT` | 20         | 24                | 15,104,597 |
| Linear       | `createWithDurationsLL`  | 50         | N/A               | 8,396,459  |
| Linear       | `createWithTimestampsLL` | 50         | N/A               | 8,371,701  |
| Dynamic      | `createWithDurationsLD`  | 50         | 12                | 24,139,520 |
| Dynamic      | `createWithTimestampsLD` | 50         | 12                | 22,889,479 |
| Tranched     | `createWithDurationsLT`  | 50         | 12                | 23,412,922 |
| Tranched     | `createWithTimestampsLT` | 50         | 12                | 22,517,108 |
