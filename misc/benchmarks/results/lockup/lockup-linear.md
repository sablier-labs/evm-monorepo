With WETH as the streaming token.

| Function                 | Configuration                              | Gas Usage |
| :----------------------- | :----------------------------------------- | :-------- |
| `burn`                   | N/A                                        | 8455      |
| `cancel`                 | N/A                                        | 39,017    |
| `renounce`               | N/A                                        | 4434      |
| `createWithDurationsLL`  | no cliff                                   | 121,705   |
| `createWithDurationsLL`  | with cliff                                 | 161,769   |
| `createWithTimestampsLL` | no cliff                                   | 121,059   |
| `createWithTimestampsLL` | with cliff                                 | 160,895   |
| `withdraw`               | vesting ongoing && called by recipient     | 30,001    |
| `withdraw`               | vesting completed && called by recipient   | 30,027    |
| `withdraw`               | vesting ongoing && called by third-party   | 30,233    |
| `withdraw`               | vesting completed && called by third-party | 30,259    |
