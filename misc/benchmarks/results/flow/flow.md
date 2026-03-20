With USDC as the streaming token.

| Function              | Stream Solvency | Gas Usage |
| :-------------------- | :-------------- | :-------- |
| `adjustRatePerSecond` | N/A             | 44,520    |
| `create`              | N/A             | 127,027   |
| `deposit`             | N/A             | 37,028    |
| `pause`               | N/A             | 8312      |
| `refund`              | Solvent         | 24,767    |
| `refundMax`           | Solvent         | 25,802    |
| `restart`             | N/A             | 7536      |
| `void`                | Solvent         | 10,100    |
| `void`                | Insolvent       | 37,601    |
| `withdraw`            | Insolvent       | 69,289    |
| `withdraw`            | Solvent         | 47,757    |
| `withdrawMax`         | Solvent         | 61,693    |
