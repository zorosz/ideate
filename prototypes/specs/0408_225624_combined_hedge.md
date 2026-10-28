# Accumulating hedge — per-position harvest + trend protection

## Thesis

Combine the two strongest findings:
1. Per-position harvest at H=15 (10x better than distance-based)
2. Trend protection v5 (cap=3, count-based close, lot increment)

The per-position harvest captures oscillation profit efficiently.
The trend protection limits damage when market trends strongly.

## Base (v1) — combined defaults

Timeframe: M1
Pair: EURUSD

### Harvest (per-position, not distance-based)
- For each individual position: if floating profit >= HarvestPips (15):
  close it, open 1 new BUY + 1 new SELL at current price
- Close ALL positions on the winning side (not just one)
- Winning side always resets to exactly 1 position

### Accumulation protection
- MaxPositionsPerSide = 3 (cap — prevents quadratic loss)
- When accumulated side count >= cap: harvest still closes winner
  but do NOT open new position on accumulated side

### Batch close (count-based, not fixed pip)
- BatchCloseMinPositions = 2
- Close accumulated side when: count >= 2 AND total P&L > 0
- Take any profit, don't wait for big reversal

### Lot increment on accumulated side
- LotIncrement = 0.01
- 1st accumulated position: 0.01
- 2nd: 0.02
- 3rd: 0.03 (capped at MaxPositionsPerSide)
- Winning side always 0.01

### Emergency
- MaxFloatingLossPct = 5

### No-trade window
- 00:00 - 01:00

## v2: Tighter harvest
HarvestPips = 10 (instead of 15).
More harvests, thinner per-trade edge, higher volume.

## v3: No lot increment
Same as v1 but LotIncrement = 0 (all positions 0.01).
Tests whether lot increment adds value or just risk.

## v4: Higher cap
MaxPositionsPerSide = 5 (instead of 3).
More accumulation allowed, potentially bigger batch close profits
but higher drawdown risk.

## v5: Aggressive recovery
LotIncrement = 0.02 (double the base increment).
Cap = 3: positions at 0.01, 0.03, 0.05.
Faster recovery on reversal, higher risk if no reversal.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| HarvestPips | 15 | 5-30 | 5 |
| MaxPositionsPerSide | 3 | 2-6 | 1 |
| BatchCloseMinPositions | 2 | 2-5 | 1 |
| LotIncrement | 0.01 | 0-0.03 | 0.005 |
| MaxFloatingLossPct | 5 | 3-10 | 1 |

## Notes
- v1 combines the two best findings from previous tests
- v3 is the key comparison: if no lot increment performs equally,
  remove the martingale risk entirely
- v4 tests if more accumulation helps — if DD stays under 5%
  with cap=5, the extra positions add profit
- Target: PF > 1.3, DD < 5%, validated across 2023-2025
- This is the strongest candidate for a deployable hedge EA