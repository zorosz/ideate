# Validated: all_time_hedge (per-position harvest) — v1 optimized

Best version: v1 (HarvestPips=10, BatchClosePips=30, MaxFloatingLossPct=5)

## OOS1: 2024.01.01-2025.01.01

- Total trades: 23679
- Win rate: 80.67%
- Avg win / Avg loss: $0.97 / $-3.69
- EV per trade: $+0.04
- Profit factor: 1.05
- Total net profit: $+924.30
- Max drawdown: 20.09%
- Recovery factor: 0.40
- Sharpe ratio: 0.42

Verdict: **WEAK** (PF barely > 1.05, Sharpe < 0.5)

## OOS2: 2023.01.01-2024.01.01

- Total trades: 37941
- Win rate: 80.41%
- Avg win / Avg loss: $1.01 / $-3.62
- EV per trade: $+0.08
- Profit factor: 1.10
- Total net profit: $+2,915.51
- Max drawdown: 19.19%
- Recovery factor: 1.06
- Sharpe ratio: 1.04

Verdict: **VALIDATED**

## Period comparison

| Period | Trades | Win% | EV | PF | Sharpe | MaxDD |
|--------|--------|------|------|------|--------|-------|
| In-sample 2025 | 50888 | — | +0.27 | 1.49 | 3.45 | 7.4% |
| OOS1 2024 | 23679 | 80.7% | +0.04 | 1.05 | 0.42 | 20.1% |
| OOS2 2023 | 37941 | 80.4% | +0.08 | 1.10 | 1.04 | 19.2% |

## Final verdict

**WEAK — edge exists across 3 years but fragile**

Both OOS periods are profitable, confirming a real edge. However:
- In-sample to OOS degradation is severe: Sharpe drops from 3.45 to 0.42-1.04
- MaxDD triples from 7.4% to ~20% out-of-sample
- EV drops 86-97% from in-sample ($0.27) to OOS ($0.04-0.08)
- This level of degradation indicates overfitting to 2025 conditions

The per-position harvest at H=10 generates enormous trade volume (24K-51K/year)
which masks the thin per-trade edge. The strategy survives OOS but barely.

Key comparison vs pure distance version:
- Per-position harvest v2 default: +$4,095 (no optimization needed)
- Pure distance v2 default: +$399
- Per-position captures ~10x more profit with defaults
- Per-position harvest is the stronger mechanism
