With WETH as the streaming token.

| Function                 | Segments | Configuration                              | Gas Usage |
| :----------------------- | :------- | :----------------------------------------- | :-------- |
| `burn`                   | 2        | N/A                                        | 8510      |
| `cancel`                 | 2        | N/A                                        | 50,777    |
| `renounce`               | 2        | N/A                                        | 4532      |
| `createWithDurationsLD`  | 2        | N/A                                        | 197,298   |
| `createWithTimestampsLD` | 2        | N/A                                        | 191,161   |
| `withdraw`               | 2        | vesting ongoing && called by recipient     | 43,779    |
| `withdraw`               | 2        | vesting completed && called by recipient   | 32,628    |
| `withdraw`               | 2        | vesting ongoing && called by third-party   | 44,018    |
| `withdraw`               | 2        | vesting completed && called by third-party | 32,867    |
| `createWithDurationsLD`  | 10       | N/A                                        | 421,226   |
| `createWithTimestampsLD` | 10       | N/A                                        | 399,192   |
| `withdraw`               | 10       | vesting ongoing && called by recipient     | 48,903    |
| `withdraw`               | 10       | vesting completed && called by recipient   | 34,816    |
| `withdraw`               | 10       | vesting ongoing && called by third-party   | 49,142    |
| `withdraw`               | 10       | vesting completed && called by third-party | 35,055    |
| `createWithDurationsLD`  | 100      | N/A                                        | 2,947,148 |
| `createWithTimestampsLD` | 100      | N/A                                        | 2,742,934 |
| `withdraw`               | 100      | vesting ongoing && called by recipient     | 106,703   |
| `withdraw`               | 100      | vesting completed && called by recipient   | 59,586    |
| `withdraw`               | 100      | vesting ongoing && called by third-party   | 106,942   |
| `withdraw`               | 100      | vesting completed && called by third-party | 59,825    |
