# Continuous hedge with WaveTrend reset

## Thesis

Two opposing positions are always open (BUY + SELL, same lot size).
When WaveTrend signals a reversal, the corresponding leg is closed
and immediately reopened at the current price. Overbought resets the
BUY (locking in profit from the rise). Oversold resets the SELL
(locking in profit from the drop). The signal direction determines
which leg resets, not the P&L.

## Base (v1)

Timeframe: M1
Pair: EURUSD
Lot: 0.01 fixed, both legs identical

### Startup
- Open BUY and SELL simultaneously at current price
- Both with SL = 0, TP = 0 (EA manages everything)

### Reset logic (every new M1 bar)

```
Check BUY leg:
  distance = current price - BUY open price (in pips)
  if abs(distance) >= MinResetPips (30):
    if WT overbought (wt1 > OB level) AND WT bearish cross:
      → Close BUY
      → Open new BUY at current price
      (price is high → BUY likely profited → lock it in)

Check SELL leg:
  distance = SELL open price - current price (in pips)
  if abs(distance) >= MinResetPips (30):
    if WT oversold (wt1 < OS level) AND WT bullish cross:
      → Close SELL
      → Open new SELL at current price
      (price is low → SELL likely profited → lock it in)
```

### Key difference from previous version
- No "is in profit" check — the WT signal determines which side resets
- If BUY is in loss but WT says overbought: still close and reopen
  (accept the loss, reset at better level)
- This means occasional resets at a loss, but the WT timing should
  make these rare (overbought usually means BUY profited)

### WaveTrend parameters
- Channel: 10, Average: 21
- OB level: 53, OS level: -53
- Import WaveTrend.mqh

### Rules
- Always exactly 2 positions open (1 BUY + 1 SELL)
- Both same lot size, always
- Never close both at the same time
- SL = 0, TP = 0 on all positions
- If only 1 position exists: immediately open the missing side
- The 30 pip minimum prevents resetting on noise

### No-trade window
- 00:00 - 01:00 broker time: don't reset
- Positions stay open during this window

## v2: Relaxed WT threshold
OB/OS levels from 53 to 30.
More frequent resets, catches smaller swings.

## v3: No WT, pure distance
Remove WaveTrend. Reset whichever leg has >= 30 pips profit.
Only profit-based, no signal. Control test to measure WT value.

## v4: Tighter distance
MinResetPips from 30 to 15.
With WT filter (same as v1 but 15 pip minimum).

## v5: Stronger WT only
OB/OS levels at 60/-60.
Fewer resets but stronger reversal signals.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| MinResetPips | 30 | 10-60 | 5 |
| WTOBLevel | 53 | 30-80 | 10 |
| WTOSLevel | -53 | -80--30 | 10 |
| WTChannelLen | 10 | 5-20 | 5 |
| WTAverageLen | 21 | 10-30 | 5 |

## Notes
- Net exposure always near zero — low margin risk
- Swap cost on both legs is the main ongoing cost
- Overbought → close BUY: usually locks profit (price rose)
- Oversold → close SELL: usually locks profit (price dropped)
- Rare case: WT signals reset on a losing leg — accepts small loss
  but repositions at a better level for the next move
- In strong trends: the trending leg resets frequently (profit),
  the counter-trend leg accumulates floating loss but never resets
  (no opposing WT signal in a trend)
- v3 is the key comparison: if pure distance works as well as WT,
  the timing signal adds no value