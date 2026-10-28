# Accumulating hedge — profit harvest with position stacking

## Thesis

Two opposing positions start simultaneously. When the winning side
hits a profit target, it closes and TWO new positions open (both
directions) at current price. This accumulates positions on the
counter-trend side. When price reverses enough that the accumulated
side is net profitable, close them all. Realized profits from
harvesting + accumulated batch close = total profit.

## Warning

Floating loss grows quadratically while harvest profit grows linearly.
In a strong trend, 3 harvests at 30 pips = +90 realized but -180 
floating. This strategy REQUIRES a reversal to work. Without it,
the emergency kill triggers.

## Base (v1)

Timeframe: M1
Pair: EURUSD
Lot: 0.01 fixed, all positions identical

### Startup
- Open BUY and SELL simultaneously at current price
- Both SL = 0, TP = 0 (EA manages everything)

### Harvest logic (every tick)

```
For each position:
  if position profit in pips >= HarvestPips (30):
    Close the winning position (realize profit)
    Open new BUY at current price (lot = FixedLotSize)
    Open new SELL at current price (lot = FixedLotSize)
    → winning side is replaced, losing side accumulates
```

### Batch close logic (every tick)

```
Count all BUY positions and their total floating P&L
Count all SELL positions and their total floating P&L

If BUY count > 1 AND total BUY P&L > BatchClosePips (10 pips):
  Close ALL BUY positions
  → accumulated BUYs were counter-trend, now reversed to profit
  Open one new BUY at current price (restart with 1 BUY)

If SELL count > 1 AND total SELL P&L > BatchClosePips (10 pips):
  Close ALL SELL positions
  Open one new SELL at current price
```

### Integrity check (every tick)

```
If no BUY positions exist: open one at current price
If no SELL positions exist: open one at current price
(ensures both sides always have at least 1 position)
```

### No-trade window
- 00:00 - 01:00: no harvesting, no batch closing
- Positions stay open

### Emergency kill
- MaxFloatingLossPct: if total floating loss > X% of balance, close ALL

## v2: Tighter harvest
HarvestPips = 15 (instead of 30).
More frequent harvesting, faster accumulation.

## v3: Larger batch close threshold
BatchClosePips = 30 (instead of 10).
Wait for bigger reversal before closing accumulated side.

## v4: WaveTrend batch close
Instead of fixed pip threshold for batch close:
Close accumulated BUYs when WT oversold + bullish cross
(means BUYs were counter-trend during downtrend, now reversing up)
Close accumulated SELLs when WT overbought + bearish cross

## v5: No batch close — pure accumulation
Remove batch close entirely. Only harvest winning side.
Let accumulated side run indefinitely (only emergency kill protects).
This tests whether the strategy works without timing the reversal.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| HarvestPips | 30 | 10-60 | 5 |
| BatchClosePips | 10 | 5-50 | 5 |
| MaxFloatingLossPct | 10 | 5-20 | 5 |

## Notes
- Worst case: strong trend with no reversal. 10 harvests at 30 pip = 
  +300 realized, but accumulated floating = -(30+60+90+...+300) = -1650 pips.
  Emergency kill essential.
- Best case: oscillating market. Harvest on each swing, batch close 
  on reversal. Double profit from both sides.
- This is NOT symmetric hedge (that was proven to lose from spreads).
  This has real directional exposure via position count imbalance.
- The batch close timing is everything. v4 (WT-based) vs v3 (fixed pip)
  will show if signal timing matters.
- Max position count could grow large — consider adding a MaxPositions
  input parameter (e.g. max 10 per side).