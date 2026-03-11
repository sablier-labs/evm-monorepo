With WETH as the streaming token.

| Function                 | Tranches | Configuration                              | Gas Usage |
| :----------------------- | :------- | :----------------------------------------- | :-------- |
| `burn`                   | 2        | N/A                                        | 8455      |
| `cancel`                 | 2        | N/A                                        | 39,225    |
| `renounce`               | 2        | N/A                                        | 4434      |
| `createWithDurationsLT`  | 2        | N/A                                        | 193,256   |
| `createWithTimestampsLT` | 2        | N/A                                        | 188,819   |
| `withdraw`               | 2        | vesting ongoing && called by recipient     | 30,209    |
| `withdraw`               | 2        | vesting completed && called by recipient   | 30,561    |
| `withdraw`               | 2        | vesting ongoing && called by third-party   | 30,441    |
| `withdraw`               | 2        | vesting completed && called by third-party | 30,793    |
| `createWithDurationsLT`  | 10       | N/A                                        | 406,122   |
| `createWithTimestampsLT` | 10       | N/A                                        | 389,206   |
| `withdraw`               | 10       | vesting ongoing && called by recipient     | 35,187    |
| `withdraw`               | 10       | vesting completed && called by recipient   | 32,387    |
| `withdraw`               | 10       | vesting ongoing && called by third-party   | 35,419    |
| `withdraw`               | 10       | vesting completed && called by third-party | 32,619    |
| `createWithDurationsLT`  | 100      | N/A                                        | 2,804,215 |
| `createWithTimestampsLT` | 100      | N/A                                        | 2,645,245 |
| `withdraw`               | 100      | vesting ongoing && called by recipient     | 91,261    |
| `withdraw`               | 100      | vesting completed && called by recipient   | 53,001    |
| `withdraw`               | 100      | vesting ongoing && called by third-party   | 91,493    |
| `withdraw`               | 100      | vesting completed && called by third-party | 53,233    |
