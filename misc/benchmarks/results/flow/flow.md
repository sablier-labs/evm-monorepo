With USDC as the streaming token.

| Function              | Stream Solvency | Gas Usage |
| :-------------------- | :-------------- | :-------- |
| `adjustRatePerSecond` | N/A             | 44,520    |
| `create`              | N/A             | 127,027   |
| `deposit`             | N/A             | 37,028    |
| `pause`               | N/A             | 8312      |
| `refund`              | Solvent         | 24,785    |
| `refundMax`           | Solvent         | 25,820    |
| `restart`             | N/A             | 7514      |
| `void`                | Solvent         | 10,100    |
| `void`                | Insolvent       | 37,601    |
| `withdraw`            | Insolvent       | 67,477    |
| `withdraw`            | Solvent         | 45,945    |
| `withdrawMax`         | Solvent         | 59,881    |
