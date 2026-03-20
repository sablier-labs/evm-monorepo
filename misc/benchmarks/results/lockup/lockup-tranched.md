With WETH as the streaming token.

| Function                 | Tranches | Configuration                              | Gas Usage |
| :----------------------- | :------- | :----------------------------------------- | :-------- |
| `burn`                   | 2        | N/A                                        | 8510      |
| `cancel`                 | 2        | N/A                                        | 39,459    |
| `renounce`               | 2        | N/A                                        | 4532      |
| `createWithDurationsLT`  | 2        | N/A                                        | 194,663   |
| `createWithTimestampsLT` | 2        | N/A                                        | 190,054   |
| `withdraw`               | 2        | vesting ongoing && called by recipient     | 32,458    |
| `withdraw`               | 2        | vesting completed && called by recipient   | 32,810    |
| `withdraw`               | 2        | vesting ongoing && called by third-party   | 32,697    |
| `withdraw`               | 2        | vesting completed && called by third-party | 33,049    |
| `createWithDurationsLT`  | 10       | N/A                                        | 410,233   |
| `createWithTimestampsLT` | 10       | N/A                                        | 392,857   |
| `withdraw`               | 10       | vesting ongoing && called by recipient     | 37,460    |
| `withdraw`               | 10       | vesting completed && called by recipient   | 34,636    |
| `withdraw`               | 10       | vesting ongoing && called by third-party   | 37,699    |
| `withdraw`               | 10       | vesting completed && called by third-party | 34,875    |
| `createWithDurationsLT`  | 100      | N/A                                        | 2,838,746 |
| `createWithTimestampsLT` | 100      | N/A                                        | 2,676,076 |
| `withdraw`               | 100      | vesting ongoing && called by recipient     | 93,804    |
| `withdraw`               | 100      | vesting completed && called by recipient   | 55,250    |
| `withdraw`               | 100      | vesting ongoing && called by third-party   | 94,043    |
| `withdraw`               | 100      | vesting completed && called by third-party | 55,489    |
