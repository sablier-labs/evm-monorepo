# Bob Architecture Diagrams

## Contract Architecture

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                              SablierBob                                      │
│                                                                              │
│  Central contract managing price-target vaults                               │
│  • Creates and tracks vaults                                                 │
│  • Coordinates deposits and redemptions                                      │
│  • Routes to adapter when yield-bearing                                      │
└─────────────────────────────────────────────────────────────────────────────-┘
         │                    │                     │
         │                    │                     │
    yield-bearing        share token           non-adapter
    vault actions        management            token custody
         │                    │                     │
         ▼                    ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ SablierBob-     │  │ BobVaultShare   │  │ Deposit Tokens  │
│ Adapter         │  │ (per vault)     │  │ (ERC20)         │
│                 │  │                 │  │                 │
│ Stakes tokens   │  │ ERC20 shares    │  │ Held directly   │
│ for yield       │  │ representing    │  │ by SablierBob   │
│ (e.g. Lido)     │  │ vault deposits  │  │ for non-adapter │
└─────────────────┘  └─────────────────┘  │ vaults          │
         │                    │           └─────────────────┘
         │           notifies on transfer
         │                    │
         └────────────────────┘
              wstETH attribution sync
```

## Vault Lifecycle

```text
                              ┌─────────────┐
                              │   CREATE    │
                              │   VAULT     │
                              └──────┬──────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                ACTIVE                                        │
│                                                                              │
│  • Users can deposit tokens and receive shares                               │
│  • Price can be synced from oracle                                           │
│                                                                              │
│  Transitions when:                                                           │
│  • lastSyncedPrice >= targetPrice (after manual sync) → SETTLED              │
│  • block.timestamp >= expiry → EXPIRED                                       │
└───────────────────────────────────────────────────────────────────────────---┘
                                     │
           ┌─────────────────────────┴─────────────────────────┐
           │                                                   │
           ▼                                                   ▼
┌──────────────────────┐                             ┌──────────────────────┐
│       SETTLED        │                             │       EXPIRED        │
│                      │                             │                      │
│ Price target met     │                             │ Expiry time passed   │
│ (via sync)           │                             │                      │
│                      │                             │                      │
│ • Deposits blocked   │                             │ • Deposits blocked   │
│ • Users can redeem   │                             │ • Users can redeem   │
│ • Permanent: stays   │                             │                      │
│   SETTLED even if    │                             └──────────────────────┘
│   live price drops   │
│                      │
└──────────────────────┘
```

## User Flows

```text
                              USER INTERACTIONS
                              ═════════════════

    ┌─────────┐
    │  USER   │
    └────┬────┘
         │
         ├─────────── DEPOSIT ──────────────────────────────────────────┐
         │                                                              │
         │            ┌────────────────┐                                │
         │            │  SablierBob    │                                │
         │            │                │                                │
         │            │  Receives      │──── With Adapter ────┐         │
         │            │  tokens,       │                      │         │
         │            │  mints shares  │                      ▼         │
         │            └───────┬────────┘              ┌──────────────┐  │
         │                    │                       │   Adapter    │  │
         │                    │                       │              │  │
         │                    │                       │ Stakes for   │  │
         │                    ▼                       │ yield        │  │
         │            ┌──────────────┐                └──────────────┘  │
         │            │ BobVaultShare│                                  │
         │            │ minted to    │                                  │
         │            │ user         │                                  │
         │            └──────────────┘                                  │
         │                                                              │
         ├─────────── REDEEM (after settlement or expiry) ──────────────┤
         │                                                              │
         │            ┌────────────────┐                                │
         │            │  SablierBob    │                                │
         │            │                │                                │
         │      ┌─────│  Burns shares, │─────┐                          │
         │      │     │  returns       │     │                          │
         │      │     │  tokens        │     │                          │
         │      │     └────────────────┘     │                          │
         │      │                            │                          │
         │      ▼                            ▼                          │
         │  ┌──────────────┐         ┌──────────────┐                   │
         │  │ No Adapter   │         │ With Adapter │                   │
         │  │              │         │              │                   │
         │  │ Native fee   │         │ Yield fee    │                   │
         │  │ paid by user │         │ taken from   │                   │
         │  │ on redeem    │         │ staking      │                   │
         │  │              │         │ rewards      │                   │
         │  └──────────────┘         └──────────────┘                   │
         │                                                              │
         └─────────── SYNC PRICE ───────────────────────────────────────┘

                      ┌────────────────┐
           Anyone ───►│  SablierBob    │
                      │                │
                      │  Queries       │───────────► Oracle
                      │  oracle,       │◄───────────
                      │  updates       │  price data
                      │  vault price   │
                      └────────────────┘
```

## Adapter Flow (Yield-Bearing Vaults)

```text
                           ADAPTER INTEGRATION
                           ════════════════════

    The adapter enables yield generation on deposited tokens.
    Currently implemented: Lido (WETH → wstETH)

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                           ON DEPOSIT                                    │
    │                                                                         │
    │    Deposit Token ───► Yield Token ───► Held by Adapter                  │
    │    (e.g. WETH)        (e.g. wstETH)    (tracks per-user attribution)    │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                       ON SHARE TRANSFER                                 │
    │                                                                         │
    │    Share token notifies SablierBob                                      │
    │    SablierBob notifies Adapter                                          │
    │    Adapter moves yield attribution proportionally                       │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      ON SETTLEMENT (unstake)                            │
    │                                                                         │
    │    Yield Token ───► Deposit Token ───► Held by SablierBob               │
    │    (all at once)    (e.g. wstETH → WETH via DEX)                        │
    │                                                                         │
    │    Total includes principal + accrued yield                             │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                           ON REDEEM                                     │
    │                                                                         │
    │    User receives: proportional share of total                           │
    │    Yield fee: percentage of positive yield (capped at 20%)              │
    │    Fee is snapshotted at vault creation (immune to later changes)       │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Fee Model

```text
                              FEE STRUCTURE
                              ═════════════

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      NON-ADAPTER VAULTS                                 │
    │                                                                         │
    │    Fee paid in native token (ETH) at redemption time                    │
    │    Set via Comptroller (per-protocol fee)                               │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                       ADAPTER VAULTS                                    │
    │                                                                         │
    │    No native fee at redemption                                          │
    │    Yield fee: percentage of positive staking rewards                    │
    │    • Capped at 20% maximum                                              │
    │    • Snapshotted when vault is created                                  │
    │    • Sent to comptroller                                                │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

```

______________________________________________________________________

# Sablier Escrow Architecture Diagrams

High-level architectural overview of the SablierEscrow OTC token swap protocol.

## Contract Architecture

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                            SablierEscrow                                     │
│                                                                              │
│  OTC (over-the-counter) token swap protocol                                  │
│  • Creates and manages escrow orders                                         │
│  • Holds seller's tokens in escrow                                           │
│  • Facilitates atomic token swaps                                            │
│  • Supports open and private orders                                          │
└──────────────────────────────────────────────────────────────────────────────┘
         │                              │                              │
         │                              │                              │
    sell tokens                    buy tokens                    trade fees
    (escrowed)                    (from buyer)               (to comptroller)
         │                              │                              │
         ▼                              ▼                              ▼
┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
│ Seller's ERC20  │          │ Buyer's ERC20   │          │ Comptroller     │
│                 │          │                 │          │ (contract)      │
│ Held in escrow  │          │ Transferred to  │          │                 │
│ until order     │          │ seller when     │          │ Receives trade  │
│ completion      │          │ order filled    │          │ fees (max 2%)   │
└─────────────────┘          └─────────────────┘          └─────────────────┘
```

## Order Lifecycle

```text
                              ┌─────────────┐
                              │   CREATE    │
                              │   ORDER     │
                              └──────┬──────┘
                                     │
                          seller deposits sell tokens
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                  OPEN                                        │
│                                                                              │
│  • Sell tokens are held in escrow                                            │
│  • Waiting for buyer to fill                                                 │
│  • Seller can cancel at any time                                             │
│  • Open order: anyone can fill                                               │
│  • Private order: only designated buyer can fill                             │
│                                                                              │
│  Transitions when:                                                           │
│  • Buyer fills → FILLED                                                      │
│  • Seller cancels → CANCELLED                                                │
│  • Expiry passes (no action) → EXPIRED                                       │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
           ┌─────────────────────────┼─────────────────────────┐
           │                         │                         │
           ▼                         ▼                         ▼
    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
    │    FILLED    │         │  CANCELLED   │         │   EXPIRED    │
    │              │         │              │         │              │
    │ Buyer paid   │         │ Seller       │         │ No buyer     │
    │ buy tokens   │         │ reclaimed    │         │ filled       │
    │              │         │ sell tokens  │         │ before       │
    │ Seller got   │         │              │         │ expiry       │
    │ buy tokens   │         │ No fees      │         │              │
    │              │         │ charged      │         │ Seller can   │
    │ Buyer got    │         │              │         │ still cancel │
    │ sell tokens  │         │              │         │ to reclaim   │
    │              │         │              │         │              │
    │ Trade fees   │         │              │         │              │
    │ deducted     │         │              │         │              │
    └──────────────┘         └──────────────┘         └──────────────┘
```

## User Flows

```text
                              USER INTERACTIONS
                              ═════════════════

    ┌─────────┐
    │ SELLER  │
    └────┬────┘
         │
         ├─────────── CREATE ORDER ────────────────────────────────────────────┐
         │                                                                     │
         │            ┌────────────────┐                                       │
         │            │ SablierEscrow  │                                       │
         │            │                │                                       │
         │  sell      │  Escrows sell  │                                       │
         │  tokens ──►│  tokens        │                                       │
         │            │                │                                       │
         │            │  Creates order │                                       │
         │            │  with params:  │                                       │
         │            │  • sellToken   │                                       │
         │            │  • sellAmount  │                                       │
         │            │  • buyToken    │                                       │
         │            │  • minBuyAmt   │                                       │
         │            │  • buyer (opt) │                                       │
         │            │  • expiryTime  │                                       │
         │            └────────────────┘                                       │
         │                                                                     │
         ├─────────── CANCEL ORDER ────────────────────────────────────────────┤
         │                                                                     │
         │            ┌────────────────┐                                       │
         │            │ SablierEscrow  │                                       │
         │            │                │                                       │
         │            │  Returns sell  │───► sell tokens back to seller        │
         │            │  tokens        │                                       │
         │            │                │                                       │
         │            │  Order status  │                                       │
         │            │  → CANCELLED   │                                       │
         │            └────────────────┘                                       │
         │                                                                     │
         └─────────────────────────────────────────────────────────────────────┘

    ┌─────────┐
    │  BUYER  │
    └────┬────┘
         │
         └─────────── FILL ORDER ──────────────────────────────────────────────┐
                                                                               │
                      ┌────────────────┐                                       │
                      │ SablierEscrow  │                                       │
                      │                │                                       │
            buy       │  Validates:    │                                       │
            tokens ──►│  • Order OPEN  │                                       │
                      │  • Not expired │                                       │
                      │  • Buyer auth  │                                       │
                      │  • Amount OK   │                                       │
                      │                │                                       │
                      │  Executes:     │                                       │
                      │  ┌───────────────────────────────────────────┐         │
                      │  │ sell tokens ──► buyer (minus fee)         │         │
                      │  │ buy tokens  ──► seller (minus fee)        │         │
                      │  │ trade fees  ──► comptroller (contract)    │         │
                      │  └───────────────────────────────────────────┘         │
                      │                │                                       │
                      │  Order status  │                                       │
                      │  → FILLED      │                                       │
                      └────────────────┘                                       │
                                                                               │
                      Note: Buyer can pay MORE than minBuyAmount               │
                      for price improvement (better deal for seller)           │
                                                                               │
                      ─────────────────────────────────────────────────────────┘
```

## Order Types

```text
                              ORDER TYPES
                              ═══════════

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                         OPEN ORDER                                      │
    │                                                                         │
    │    buyer = address(0)                                                   │
    │                                                                         │
    │    • Anyone can fill the order                                          │
    │    • First come, first served                                           │
    │    • Useful for public OTC offers                                       │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                        PRIVATE ORDER                                    │
    │                                                                         │
    │    buyer = specific address                                             │
    │                                                                         │
    │    • Only designated buyer can fill                                     │
    │    • Pre-negotiated deal between parties                                │
    │    • Useful for private OTC trades                                      │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Fee Model

```text
                              FEE STRUCTURE
                              ═════════════

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                         TRADE FEE                                       │
    │                                                                         │
    │    Applied when order is filled (atomic swap)                           │
    │                                                                         │
    │    • Maximum: 2% (0.02e18 in UD60x18)                                   │
    │    • Set by comptroller admin via setTradeFee()                         │
    │    • Applied to both sell and buy amounts                               │
    │    • Fees sent to comptroller (contract)                                │
    │                                                                         │
    │    Example (1% fee, 100 TOKEN_A for 200 TOKEN_B):                       │
    │    ┌───────────────────────────────────────────────────────────────┐    │
    │    │ Seller receives: 200 - 2 = 198 TOKEN_B                        │    │
    │    │ Buyer receives:  100 - 1 = 99 TOKEN_A                         │    │
    │    │ Comptroller receives: 1 TOKEN_A + 2 TOKEN_B (fees)            │    │
    │    └───────────────────────────────────────────────────────────────┘    │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────┐
    │                      ORDER CANCELLATION                                 │
    │                                                                         │
    │    No fee charged                                                       │
    │    Seller gets full sell amount back                                    │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Trade Flow Example

```text
                           COMPLETE TRADE EXAMPLE
                           ══════════════════════

    Alice wants to sell 1000 USDC for at least 0.5 ETH
    Bob wants to buy USDC with ETH

    Step 1: Alice creates order
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  createOrder(                                                           │
    │      sellToken: USDC,                                                   │
    │      sellAmount: 1000e6,      // 1000 USDC                              │
    │      buyToken: WETH,                                                    │
    │      minBuyAmount: 0.5e18,    // 0.5 ETH minimum                        │
    │      buyer: address(0),       // open order                             │
    │      expiryTime: block.timestamp + 1 days                               │
    │  )                                                                      │
    │                                                                         │
    │  → 1000 USDC transferred from Alice to Escrow                           │
    │  → Order #1 created                                                     │
    └─────────────────────────────────────────────────────────────────────────┘

    Step 2: Bob fills order (offers 0.6 ETH for price improvement)
    ┌─────────────────────────────────────────────────────────────────────────┐
    │  fillOrder(                                                             │
    │      orderId: 1,                                                        │
    │      buyAmount: 0.6e18        // 0.6 ETH (better than min)              │
    │  )                                                                      │
    │                                                                         │
    │  Assuming 1% trade fee:                                                 │
    │  → Alice receives: 0.6 ETH - 0.006 ETH = 0.594 ETH                      │
    │  → Bob receives: 1000 USDC - 10 USDC = 990 USDC                         │
    │  → Comptroller receives: 0.006 ETH + 10 USDC                            │
    │  → Order #1 status → FILLED                                             │
    └─────────────────────────────────────────────────────────────────────────┘
```
