# Continuous hedge with WaveTrend profit harvesting

## Thesis

Two opposing positions are always open (BUY + SELL, same lot size).
Net exposure is near zero. Profit is harvested by closing the winning
leg when WaveTrend signals a reversal, then immediately reopening it
at the current price. Over time, each harvest locks in realized profit
while the losing leg's floating loss stays constant relative to the
new winning leg's entry.

## Base (v1)

Timeframe: M1
Pair: EURUSD
Lot: 0.01 fixed, both legs identical

### Startup
- Open BUY and SELL simultaneously at current price
- Both with SL = 0, TP = 0 (managed manually by the EA)

### Harvest logic (every new M1 bar)
```
For each open position:
  Calculate pip distance from open price to current price
  If distance >= 30 pips AND position is in profit:
    Check WaveTrend for reversal signal:
      BUY in profit + WT bearish cross (wt1 crosses below wt2) in OB zone:
        → Close BUY (lock profit)
        → Open new BUY at current price
      SELL in profit + WT bullish cross (wt1 crosses above wt2) in OS zone:
        → Close SELL (lock profit)  
        → Open new SELL at current price
```

### WaveTrend parameters
- Channel: 10, Average: 21
- OB level: 53, OS level: -53
- Import WaveTrend.mqh

### Rules
- Always exactly 2 positions open (1 BUY + 1 SELL)
- Both same lot size, always
- Never close both at the same time
- Never close the losing leg
- SL = 0, TP = 0 on all positions (EA manages exits)
- If somehow only 1 position exists (broker restart, error): 
  immediately open the missing side

### No-trade window
- 00:00 - 01:00 broker time: don't harvest (don't close/reopen)
- Positions stay open during this window

## v2: Relaxed WT threshold
Change OB/OS levels from 53 to 30.
More frequent harvesting, smaller profits per harvest.

## v3: Distance only, no WT
Remove WaveTrend requirement entirely.
Harvest whenever distance >= 30 pips, regardless of WT signal.
Pure distance-based profit taking.

## v4: Tighter distance
Change min distance from 30 to 15 pips.
With WT filter (same as v1 but 15 pip minimum).

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| MinHarvestPips | 30 | 10-60 | 5 |
| WTOBLevel | 53 | 30-80 | 10 |
| WTOSLevel | -53 | -80--30 | 10 |
| WTChannelLen | 10 | 5-20 | 5 |
| WTAverageLen | 21 | 10-30 | 5 |

## Notes
- Net exposure is always near zero — low margin risk
- Swap cost on both legs is the main ongoing cost
- Works best in oscillating markets (range)
- In strong trends: winning leg harvests frequently, losing leg 
  accumulates floating loss — but each harvest resets the winner 
  closer to the loser, so the gap stays bounded
- The 30 pip minimum prevents over-trading on noise
- This is fundamentally different from the zone-based EA — no SMC, 
  no pending orders, no S/R zones. Pure WT timing on a permanent hedge.