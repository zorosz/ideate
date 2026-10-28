# Validated: accumulating_hedge_pure_distance — v2 optimized

Best version: v2 (HarvestPips=60, BatchClosePips=90, MaxFloatingLossPct=5)

## OOS1: 2024.01.01-2025.01.01

- Total trades: 258
- Win rate: 77.13%
- Avg win / Avg loss: $5.49 / $-14.70
- EV per trade: $+0.85
- Profit factor: 1.25
- Total net profit: $+218.30
- Max drawdown: 5.12%
- Equity DD max: 3.83%
- Recovery factor: 0.54
- Sharpe ratio: 0.45

Verdict: **VALIDATED**

## OOS2: 2023.01.01-2024.01.01

- Total trades: 412
- Win rate: 76.21%
- Avg win / Avg loss: $5.44 / $-20.21
- EV per trade: $-0.69
- Profit factor: 0.86
- Total net profit: $-286.03
- Max drawdown: 9.87%
- Equity DD max: 8.94%
- Recovery factor: -0.30
- Sharpe ratio: -0.39

Verdict: **FAILED**

## Period comparison

| Period | Trades | Win% | EV | PF | Sharpe | MaxDD |
|--------|--------|------|------|------|--------|-------|
| In-sample 2025 | 469 | — | +2.19 | 1.92 | 1.37 | 4.9% |
| OOS1 2024 | 258 | 77.1% | +0.85 | 1.25 | 0.45 | 5.1% |
| OOS2 2023 | 412 | 76.2% | -0.69 | 0.86 | -0.39 | 9.9% |

## Final verdict

**CONDITIONAL — works in recent market only**

The strategy is profitable in 2024-2025 but loses money in 2023.
The 2023 EURUSD market had larger directional moves that accumulated
more losing positions before batch close could trigger profitably.

Key observation: win rate is consistently high (76-77%) across all
periods, but the avg loss in 2023 ($-20.21) is much larger than in
2024 ($-14.70). The batch close releases in 2023 were deeper losses,
suggesting the emergency kill was frequently triggered in trending
conditions.
