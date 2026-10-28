---
description: "Backtest report analysis and evaluation"
---

# /review — Report Analysis

Analyze the latest backtest report and provide an evaluation.

## Steps

1. Find the most recent report in the `MQL5\Files\reports\` folder
2. Read the .htm file
3. Evaluate the following metrics:

## Critical Metrics (must pass to proceed)

| Metric | Minimum | Ideal |
|--------|---------|-------|
| Profit Factor | > 1.2 | > 1.5 |
| Max Drawdown % | < 30% | < 15% |
| Total Trades | > 50 | > 200 |
| Recovery Factor | > 1.0 | > 3.0 |

## Warning Signs

- Fewer than 50 trades → not enough data to judge
- Profit Factor > 5.0 → likely overfitting
- Max DD > 30% → too risky
- Sharpe Ratio < 0.5 → poor risk-adjusted return
- Win rate > 90% → suspicious, likely very tight SL/TP ratio

## Output

Provide a short summary:
1. **Verdict**: PASS / FAIL / NEEDS WORK
2. **Strengths**: what's working well
3. **Weaknesses**: what's the problem
4. **Next step**: what to change and why

## Comparison

If a previous report exists, compare key metrics with the previous one.
Flag if anything got worse since the last change.
