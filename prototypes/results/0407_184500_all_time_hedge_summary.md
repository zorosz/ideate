# Summary: all_time_hedge

| Version | Params | Trades | Win% | EV | PF | MaxDD | Sharpe |
|---------|--------|--------|------|-------|------|-------|--------|
| v1 | WT 53, 30 pip | 37 | 91.9% | -0.38 | 0.92 | 1.59% | -2.98 |
| v2 | WT 30, 30 pip | 46 | 91.3% | -0.32 | 0.91 | 1.59% | -3.12 |
| v3 | No WT, 30 pip | 50 | 92.0% | -0.91 | 0.91 | 1.62% | -3.18 |
| v4 | WT 53, 15 pip | 56 | 94.6% | -0.27 | 0.91 | 1.62% | -3.26 |

## Analysis

All versions behave identically: ~92% win rate, PF 0.91, net negative.

The strategy harvests small profits (avg $3-4 per harvest) at 92-95% success rate.
But the losing leg accumulates -$138 to -$140 in floating loss by end of test.
Harvested gross profit ($150-153) barely covers the accumulated loss ($165-168).

**Why it fails**: The permanent losing leg's floating loss grows linearly with
price movement. In a trending year (2025 EURUSD dropped ~1700 pips), the SELL
leg was wrong for most of the year. Each harvest only captures 30 pips of the
winning BUY, but the losing SELL accumulates the full trend move.

**WT filter made no difference**: v1 vs v3 (WT vs no-WT) are nearly identical
because the 30-pip minimum distance is the binding constraint, not the WT signal.

## Verdict

**FAILED** — all versions negative. The continuous hedge thesis doesn't produce
positive EV because the losing leg's cost exceeds the harvested profits in
trending markets. Not proceeding to optimization or validation.
