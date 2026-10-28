# Accumulating hedge — pure distance, no indicators

## Thesis

Same as the accumulating hedge but without any indicator.
When price moves HarvestPips from the last harvest price,
close the winning side and open two new positions. Batch close
the accumulated side when it reaches net profit. Pure price
action, no WaveTrend, no SMC.

## Base (v1)

Timeframe: M1
Pair: EURUSD
Lot: 0.01 fixed

### Startup
- Open BUY and SELL at current price
- Store lastHarvestPrice = current price
- SL = 0, TP = 0 on all positions

### Harvest logic (every tick)

```
distance = abs(currentPrice - lastHarvestPrice)

if distance >= HarvestPips (100 pips):
  Determine direction: price went UP or DOWN from lastHarvestPrice

  if price UP (currentPrice > lastHarvestPrice + HarvestPips):
    Close the single BUY (the one opened at lastHarvestPrice)
    Open new BUY + new SELL at current price
    lastHarvestPrice = current price

  if price DOWN (currentPrice < lastHarvestPrice - HarvestPips):
    Close the single SELL (the one opened at lastHarvestPrice)
    Open new BUY + new SELL at current price
    lastHarvestPrice = current price
```

### Batch close logic (every tick)

```
Count all BUY positions and total BUY floating P&L
Count all SELL positions and total SELL floating P&L

if BUY count > 1 AND total BUY P&L in pips > BatchClosePips:
  Close ALL BUYs
  Open one new BUY at current price

if SELL count > 1 AND total SELL P&L in pips > BatchClosePips:
  Close ALL SELLs
  Open one new SELL at current price
```

### Integrity check
- If no BUY exists: open one
- If no SELL exists: open one

### No-trade window
- 00:00 - 01:00: no harvest, no batch close

### Emergency kill
- MaxFloatingLossPct: close ALL if floating loss > X% of balance

## v2: Tighter harvest
HarvestPips = 50 (instead of 100).

## v3: Wider harvest
HarvestPips = 150.

## v4: Large batch close threshold
HarvestPips = 100, BatchClosePips = 50 (instead of 10).
Wait for a bigger reversal.

## v5: No batch close
Remove batch close. Only harvest. Emergency kill only safety net.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| HarvestPips | 100 | 30-200 | 10 |
| BatchClosePips | 10 | 5-100 | 10 |
| MaxFloatingLossPct | 10 | 5-20 | 5 |

## Notes
- No indicators, no zones, no signals — pure distance
- Compared to the WT version: if this performs equally, WT adds no value
- If this performs worse, the WT timing helps batch close decisions
- 100 pip harvest is large for M1 — positions may sit for hours/days
- The quadratic floating loss problem remains identical
- Key comparison: this spec vs 0407_2100_accumulating_hedge v3 (same 
  batch close threshold, indicator vs no indicator)
