With WETH as the streaming token.

| Function                 | Configuration                              | Gas Usage |
| :----------------------- | :----------------------------------------- | :-------- |
| `burn`                   | N/A                                        | 8510      |
| `cancel`                 | N/A                                        | 39,195    |
| `renounce`               | N/A                                        | 4532      |
| `createWithDurationsLL`  | no cliff                                   | 145,964   |
| `createWithDurationsLL`  | with cliff                                 | 185,937   |
| `createWithTimestampsLL` | no cliff                                   | 145,249   |
| `createWithTimestampsLL` | with cliff                                 | 184,994   |
| `withdraw`               | vesting ongoing && called by recipient     | 32,194    |
| `withdraw`               | vesting completed && called by recipient   | 32,394    |
| `withdraw`               | vesting ongoing && called by third-party   | 32,433    |
| `withdraw`               | vesting completed && called by third-party | 32,633    |
