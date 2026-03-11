With WETH as the streaming token.

| Function                 | Segments | Configuration                              | Gas Usage |
| :----------------------- | :------- | :----------------------------------------- | :-------- |
| `burn`                   | 2        | N/A                                        | 8455      |
| `cancel`                 | 2        | N/A                                        | 50,585    |
| `renounce`               | 2        | N/A                                        | 4434      |
| `createWithDurationsLD`  | 2        | N/A                                        | 195,680   |
| `createWithTimestampsLD` | 2        | N/A                                        | 189,827   |
| `withdraw`               | 2        | vesting ongoing && called by recipient     | 41,572    |
| `withdraw`               | 2        | vesting completed && called by recipient   | 30,484    |
| `withdraw`               | 2        | vesting ongoing && called by third-party   | 41,804    |
| `withdraw`               | 2        | vesting completed && called by third-party | 30,716    |
| `createWithDurationsLD`  | 10       | N/A                                        | 416,016   |
| `createWithTimestampsLD` | 10       | N/A                                        | 394,914   |
| `withdraw`               | 10       | vesting ongoing && called by recipient     | 46,672    |
| `withdraw`               | 10       | vesting completed && called by recipient   | 32,672    |
| `withdraw`               | 10       | vesting ongoing && called by third-party   | 46,904    |
| `withdraw`               | 10       | vesting completed && called by third-party | 32,904    |
| `createWithDurationsLD`  | 100      | N/A                                        | 2,901,528 |
| `createWithTimestampsLD` | 100      | N/A                                        | 2,705,536 |
| `withdraw`               | 100      | vesting ongoing && called by recipient     | 104,202   |
| `withdraw`               | 100      | vesting completed && called by recipient   | 57,442    |
| `withdraw`               | 100      | vesting ongoing && called by third-party   | 104,434   |
| `withdraw`               | 100      | vesting completed && called by third-party | 57,674    |
