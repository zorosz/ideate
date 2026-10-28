# Accumulating hedge — trend protection variations

## Thesis

The base accumulating hedge (H60, B70) works in ranging markets but
suffers in strong trends where accumulated positions grow quadratically.
These variations test different approaches to limit trend damage and
improve reversal recovery.

## Base

Use the current accumulating_hedge.mq5 source as starting point.
Parameters: HarvestPips=60, BatchClosePips=70, MaxFloatingLossPct=5

## v1: Max position cap

Add input: MaxPositionsPerSide = 5

When accumulated side count >= MaxPositionsPerSide:
  Stop opening new positions on that side during harvest.
  Harvest still closes the winning side and opens 1 replacement.
  But do NOT open a new position on the accumulated side.

Effect: floating loss becomes linear (5 x distance) instead of
quadratic (1+2+3+4+5+... x harvest distance).

## v2: Increasing harvest distance

Add input: HarvestIncrement = 30

Each consecutive harvest in the same direction increases the
required distance:
  1st harvest: 60 pips
  2nd harvest: 90 pips (60 + 30)
  3rd harvest: 120 pips (60 + 60)
  4th harvest: 150 pips (60 + 90)

Reset the counter when a batch close happens (reversal confirmed).

Effect: slows accumulation in trends. Fewer positions opened,
bigger gaps between them.

Track with: int g_consecutiveHarvests = 0;
currentHarvestPips = HarvestPips + g_consecutiveHarvests * HarvestIncrement

## v3: Position-count batch close

Replace fixed pip threshold with position count logic:
Add input: BatchCloseMinPositions = 3

Close accumulated side when:
  count >= BatchCloseMinPositions AND total P&L > 0

Don't wait for 70 pips of reversal — close as soon as the
accumulated side goes net positive, regardless of how small.

Effect: takes any available profit on reversal. Doesn't wait
for big reversal that may never come.

## v4: Increasing lot size on accumulated side

Add input: LotIncrement = 0.01

Each new position on the accumulated side opens with a larger lot:
  1st position: 0.01
  2nd position: 0.02
  3rd position: 0.03
  4th position: 0.04
  5th position: 0.05

The winning side always stays at FixedLotSize (0.01).

Effect: when reversal comes, the larger lots profit more,
covering the smaller lots' losses faster. Batch close triggers
sooner because the newest (largest) position moves to profit first.

WARNING: this is martingale-like. If no reversal comes, the larger
lots amplify the loss. MaxFloatingLossPct is critical.

Calculate lot: FixedLotSize + (accumulatedCount * LotIncrement)

## v5: Combined — cap + count-based close + increasing lots

Combine v1 + v3 + v4:
  MaxPositionsPerSide = 5
  BatchCloseMinPositions = 3, close when total P&L > 0
  LotIncrement = 0.01

The safest aggressive approach: capped exposure, early exit on
any profit, larger lots to accelerate recovery.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| HarvestPips | 60 | 40-100 | 10 |
| MaxPositionsPerSide | 5 | 3-10 | 1 |
| HarvestIncrement | 30 | 10-50 | 10 |
| BatchCloseMinPositions | 3 | 2-6 | 1 |
| LotIncrement | 0.01 | 0.005-0.03 | 0.005 |
| MaxFloatingLossPct | 5 | 3-10 | 1 |

## Notes
- v1 and v3 are conservative — limit damage
- v4 is aggressive — amplify recovery but also amplify risk
- v5 combines both: limit + amplify
- Compare all against the base (H60, B70, fixed lot)
- If v5 beats the base, the combination is the path forward
- If v1 alone beats the base, simplicity wins
- The key metric: max drawdown % relative to profit
  (Sharpe ratio captures this best)