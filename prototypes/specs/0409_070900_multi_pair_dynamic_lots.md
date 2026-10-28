# Combined hedge — single EA, multi-pair simultaneous

## Thesis

Run the validated accumulating hedge on multiple pairs from a single
EA instance. This allows seeing the combined equity curve, total
drawdown, and cross-pair behavior in one backtest. Each pair has
independent state (positions, counters) but shares the same balance
for dynamic lot calculation.

## Implementation

Single EA attached to ONE chart (e.g. EURUSD M1). The EA manages
ALL pairs internally using iClose/SymbolInfoDouble for price data
and CTrade for order execution on each symbol.

### Pair configuration

```cpp
input string Pair1 = "EURUSD";    // First pair
input string Pair2 = "GBPUSD";    // Second pair (empty = disabled)
input string Pair3 = "USDJPY";    // Third pair (empty = disabled)
input int    BaseMagic = 408500;   // Pair1=+1, Pair2=+2, Pair3=+3
```

### Per-pair state

Each pair gets its own complete state:
```cpp
struct PairState {
   string symbol;
   int    magicNumber;
   ulong  longTickets[];     // accumulated BUY positions
   ulong  shortTickets[];    // accumulated SELL positions
   int    longCount;
   int    shortCount;
   double lastHarvestPrice;  // if distance-based, not needed for per-position
};

PairState g_pairs[3];
```

### Per-pair logic

Each pair runs the FULL accumulating hedge logic independently:
- Per-position harvest (H=5)
- Accumulation with cap (MaxPositionsPerSide=6)
- Count-based batch close (BatchCloseMinPositions=4)
- Lot increment on accumulated side
- Dynamic lot sizing from SHARED balance

### Shared balance, split risk

```
Total risk per pair = RiskPctPerLot / number of active pairs

If 3 pairs active and RiskPctPerLot = 0.21:
  Each pair uses 0.07% per lot

baseLot per pair = AccountBalance * 0.07 / 100 / 1000
```

### OnTick flow

```
OnTick():
  1. CheckEmergencyKill()   — checks ALL pairs combined floating loss
  2. for each active pair:
       ManageSlots(pair)    — detect fills, closes
       CheckHarvest(pair)   — per-position harvest
       CheckBatchClose(pair)— count-based batch close
       EnsureIntegrity(pair)— always 1 BUY + 1 SELL minimum
```

### Emergency kill — combined

```
Total floating loss across ALL pairs and ALL positions.
if totalFloatingLoss > balance * MaxFloatingLossPct / 100:
  Close ALL positions on ALL pairs
  Cancel ALL pending orders on ALL pairs
```

### New bar detection — per pair

```
Each pair tracks its own lastBarTime using:
  iTime(pair.symbol, PERIOD_M1, 0)
  
Some pairs may have new bars at different times (different 
broker feed timing), so each pair's logic runs on its own 
bar clock.
```

## v1: EURUSD + GBPUSD + USDJPY (majors)

Three major pairs. Highest liquidity, tightest spreads.
RiskPctPerLot = 0.21 (0.07 per pair).

## v2: EURUSD + USDJPY only (two pairs)

Skip GBPUSD. RiskPctPerLot = 0.14 (0.07 per pair).
Tests if 2 pairs is enough diversification.

## v3: Full risk per pair

RiskPctPerLot = 0.07 per pair but NOT divided.
Each pair trades at 0.07 regardless of how many pairs active.
Total risk = 0.21% with 3 pairs (same as v1).
Control test — same as v1 but expressed differently.

## v4: Risk-weighted by spread

Different risk per pair based on typical spread:
- EURUSD: RiskPctPerLot = 0.10 (tightest spread)
- GBPUSD: RiskPctPerLot = 0.06
- USDJPY: RiskPctPerLot = 0.05
Total: 0.21%

## v5: Single pair control

EURUSD only, RiskPctPerLot = 0.21 (full allocation).
Pair2 = "", Pair3 = "".
Compare combined Sharpe of v1 vs single pair Sharpe of v5.

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| Pair1 | string | EURUSD | First pair |
| Pair2 | string | GBPUSD | Second pair (empty=off) |
| Pair3 | string | USDJPY | Third pair (empty=off) |
| BaseMagic | int | 408500 | Base magic number |
| HarvestPips | double | 5 | Per-position harvest threshold |
| MaxPositionsPerSide | int | 6 | Cap per pair per side |
| BatchCloseMinPositions | int | 4 | Min positions for batch close |
| RiskPctPerLot | double | 0.21 | Total risk %, auto-split by pair count |
| IncrementRatio | double | 1.0 | Lot increment = baseLot * this |
| MaxLotSize | double | 1.0 | Maximum lot per position |
| MaxFloatingLossPct | double | 4.0 | Emergency kill — ALL pairs combined |
| NoTradeStart | string | "23:00" | No harvest window start |
| NoTradeEnd | string | "00:00" | No harvest window end |

## Backtest settings

- Attach to EURUSD M1 chart
- Deposit: 25000 USD
- Leverage: 1:30
- Period: 2022.01.01 - 2026.01.01

IMPORTANT: the EA needs "Allow algorithmic trading" and symbol 
access for all 3 pairs in MT5. In tester, use "All symbols 
from Market Watch" mode if available, or "Every tick based on 
real ticks" model.

## USDJPY pip calculation

USDJPY is 3-digit (e.g. 111.123), not 5-digit like EURUSD.
1 pip USDJPY = 0.01 = 1 point (not 10 points like EURUSD).

The EA must handle this per-pair:
```
double PipValue(string symbol) {
   int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5) 
      return SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   else  // 2 or 4 digit
      return SymbolInfoDouble(symbol, SYMBOL_POINT);
}

double DistanceInPips(string symbol, double price1, double price2) {
   return MathAbs(price1 - price2) / PipValue(symbol);
}
```

Apply this in harvest distance calculation, batch close P&L 
conversion, and any other pip-based logic.

## Notes
- MT5 Strategy Tester has limitations with multi-pair testing
  on M1. "Every tick" model may be needed for accurate fills.
- If tester doesn't support multi-symbol properly, fall back to
  3 separate backtests and combine equity curves manually.
- The shared balance means a drawdown on one pair reduces lot 
  sizes on ALL pairs — this is intentional (self-protecting).
- Max total positions: 3 pairs × 6 cap × 2 sides = 36 positions.
  At peak lot (cap=6, IncrRatio=1.0): ~0.21 lot per position.
  Max total margin: ~36 × $700 = ~$25K. With 1:30 leverage on
  25K balance this is tight. Monitor margin level.