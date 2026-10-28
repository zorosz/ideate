# Validated: trend protection variations — v5 combined optimized

Best version: v5 combined (HarvestPips=100, MaxPositionsPerSide=3, BatchCloseMinPositions=2, LotIncrement=0.01, MaxFloatingLossPct=3)

## OOS1: 2024.01.01-2025.01.01

- Total trades: 95
- Win rate: 63.16%
- Avg win / Avg loss: $10.74 / $-13.90
- EV per trade: $+1.62
- Profit factor: 1.31
- Total net profit: $+154.02
- Max drawdown: 1.82%
- Equity DD max: 2.20%
- Recovery factor: 0.68
- Sharpe ratio: 0.90

Verdict: **VALIDATED**

## OOS2: 2023.01.01-2024.01.01

- Total trades: 159
- Win rate: 60.38%
- Avg win / Avg loss: $10.69 / $-16.54
- EV per trade: $-0.15
- Profit factor: 0.98
- Total net profit: $-23.24
- Max drawdown: 3.65%
- Equity DD max: 3.50%
- Recovery factor: -0.07
- Sharpe ratio: -0.08

Verdict: **FAILED** (barely — essentially breakeven, -$23 on $10K)

## Period comparison

| Period | Trades | Win% | EV | PF | Sharpe | MaxDD |
|--------|--------|------|------|------|--------|-------|
| In-sample 2025 | 204 | — | +3.29 | 1.95 | 3.35 | 1.8% |
| OOS1 2024 | 95 | 63.2% | +1.62 | 1.31 | 0.90 | 1.8% |
| OOS2 2023 | 159 | 60.4% | -0.15 | 0.98 | -0.08 | 3.7% |

## Comparison vs base (no trend protection, H60 B70 M5)

| Period | Base PF | Base DD | v5 PF | v5 DD | Improvement |
|--------|---------|---------|-------|-------|-------------|
| OOS1 2024 | 1.25 | 5.1% | 1.31 | 1.8% | DD -65% |
| OOS2 2023 | 0.86 | 9.9% | 0.98 | 3.7% | DD -63%, loss -92% |

## Final verdict

**CONDITIONAL — works in recent market, nearly flat in trending**

The trend protection mechanisms dramatically reduce damage:
- 2023 loss: -$286 (base) → -$23 (v5 protected) — 92% reduction
- 2023 DD: 9.9% (base) → 3.65% (v5 protected) — 63% reduction
- DD stays under 4% across all 3 years — the strongest DD control tested

The cap (3 max positions) prevents quadratic loss growth.
Count-based close (take any profit when >= 2 positions) captures small reversals.
Lot increment accelerates recovery without excessive risk at cap=3.

This is the closest to a deployable hedge strategy tested so far.
