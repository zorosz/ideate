# Combined hedge — dynamic lot sizing + variations

## Thesis

The validated combined hedge (H=5, Cap=6, LotInc=0.025) uses fixed
lot sizes which masks true risk in backtests. Dynamic lot sizing
scales position size with balance, maintaining consistent risk %
and enabling compound growth.

## Base parameters (from validated v5)
- HarvestPips = 5
- MaxPositionsPerSide = 6
- BatchCloseMinPositions = 4
- MaxFloatingLossPct = 4
- No-trade window: 23:00 - 00:00

## v1: Balance-based lot sizing

Replace FixedLotSize and LotIncrement with dynamic calculation:

```
input double RiskPctPerLot = 0.5;    // Base lot as % of balance
input double IncrementRatio = 0.5;   // LotIncrement = baseLot * this

Every time a new position opens:
  baseLot = NormalizeLots(AccountBalance * RiskPctPerLot / 100 / 1000)
  // 1000 = approximate margin per 0.01 lot EURUSD at 1:30

  For the first position on accumulated side: lot = baseLot
  For each subsequent: lot = baseLot + (positionIndex * baseLot * IncrementRatio)

  Example at 10,000 balance, RiskPctPerLot=0.5:
    baseLot = 10000 * 0.005 / 1000 = 0.05
    Position 1: 0.05
    Position 2: 0.05 + (1 * 0.05 * 0.5) = 0.075
    Position 3: 0.05 + (2 * 0.05 * 0.5) = 0.10
    
  At 50,000 balance:
    baseLot = 50000 * 0.005 / 1000 = 0.25
    Position 1: 0.25
    Position 2: 0.375
    Position 3: 0.50
```

The winning side always opens at baseLot.
Lot recalculated at each position open (not cached).

## v2: Conservative — lower risk per lot

RiskPctPerLot = 0.25 (half of v1).
Slower compound but more resilient to drawdowns.

## v3: Aggressive — higher risk per lot

RiskPctPerLot = 1.0, IncrementRatio = 0.75.
Faster compound, bigger drawdowns.

## v4: Fixed increment ratio test

RiskPctPerLot = 0.5, IncrementRatio = 0.25 (lower increment).
Tests whether the lot increment matters as much when base lot 
already scales with balance.

## v5: Cap variations with dynamic lots

RiskPctPerLot = 0.5, IncrementRatio = 0.5
Test with MaxPositionsPerSide = 4 (instead of 6).
Lower cap with bigger dynamic lots might be safer.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| RiskPctPerLot | 0.5 | 0.1-1.0 | 0.1 |
| IncrementRatio | 0.5 | 0.1-1.0 | 0.1 |
| HarvestPips | 5 | 3-10 | 1 |
| MaxPositionsPerSide | 6 | 3-8 | 1 |
| BatchCloseMinPositions | 4 | 2-6 | 1 |
| MaxFloatingLossPct | 4 | 3-8 | 1 |

## Backtest settings
- Deposit: 10000 USD
- Leverage: 1:30
- Period: 2024.01.01 - 2026.01.01 (2 years)
- Then validate on 2020.01.01 - 2024.01.01 (4 years OOS)

## Notes
- The key metric is now PERCENTAGE return, not dollar return
  (because lot size scales, dollar returns are meaningless)
- Compare monthly return % and max DD % across versions
- A good result: consistent 3-5% monthly return with < 8% max DD
- Watch for: the dynamic lot making the martingale MORE dangerous
  because larger lots amplify the accumulated side faster
- The balance should be read ONCE when opening a position, not
  continuously — prevents the lot from shrinking mid-drawdown
  which would make recovery harder