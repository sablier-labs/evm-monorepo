With WETH as the streaming token.

| Lockup Model | Function                 | Batch Size | Segments/Tranches | Gas Usage  |
| :----------- | :----------------------- | :--------- | :---------------- | :--------- |
| Linear       | `createWithDurationsLL`  | 5          | N/A               | 1,050,118  |
| Linear       | `createWithTimestampsLL` | 5          | N/A               | 998,961    |
| Dynamic      | `createWithDurationsLD`  | 5          | 24                | 4,183,356  |
| Dynamic      | `createWithTimestampsLD` | 5          | 24                | 3,938,420  |
| Tranched     | `createWithDurationsLT`  | 5          | 24                | 4,046,168  |
| Tranched     | `createWithTimestampsLT` | 5          | 24                | 3,853,698  |
| Linear       | `createWithDurationsLL`  | 10         | N/A               | 1,952,882  |
| Linear       | `createWithTimestampsLL` | 10         | N/A               | 1,946,687  |
| Dynamic      | `createWithDurationsLD`  | 10         | 24                | 8,321,775  |
| Dynamic      | `createWithTimestampsLD` | 10         | 24                | 7,826,938  |
| Tranched     | `createWithDurationsLT`  | 10         | 24                | 8,039,187  |
| Tranched     | `createWithTimestampsLT` | 10         | 24                | 7,657,724  |
| Linear       | `createWithDurationsLL`  | 20         | N/A               | 3,856,454  |
| Linear       | `createWithTimestampsLL` | 20         | N/A               | 3,844,693  |
| Dynamic      | `createWithDurationsLD`  | 20         | 24                | 16,614,741 |
| Dynamic      | `createWithTimestampsLD` | 20         | 24                | 15,607,548 |
| Tranched     | `createWithDurationsLT`  | 20         | 24                | 16,022,800 |
| Tranched     | `createWithTimestampsLT` | 20         | 24                | 15,269,123 |
| Linear       | `createWithDurationsLL`  | 50         | N/A               | 9,576,314  |
| Linear       | `createWithTimestampsLL` | 50         | N/A               | 9,550,888  |
| Dynamic      | `createWithDurationsLD`  | 50         | 12                | 24,460,057 |
| Dynamic      | `createWithTimestampsLD` | 50         | 12                | 23,154,421 |
| Tranched     | `createWithDurationsLT`  | 50         | 12                | 23,662,837 |
| Tranched     | `createWithTimestampsLT` | 50         | 12                | 22,742,309 |
