---
description: "Run backtest month by month and aggregate results"
---

# /monthly — Monthly backtest breakdown

Run the EA separately for each month, each starting with the same
initial deposit. Eliminates the "small balance in January" bias.

## What it does

1. For each month in the given range (e.g. 2024.01 - 2026.04):
   - Generate a backtest .ini with FromDate=YYYY.MM.01 ToDate=YYYY.MM+1.01
   - Run the backtest with the SAME deposit each time (e.g. 10000)
   - Read the report and extract: profit, PF, trades, max DD%, largest loss
   
2. After all months complete, write a summary table:

```
# Monthly Breakdown: [EA name]
Deposit: $10,000 per month | Leverage: 1:30

| Month    | Profit  | PF   | Trades | MaxDD% | Largest Loss |
|----------|---------|------|--------|--------|--------------|
| 2024.01  | +$142   | 1.35 | 847    | 2.1%   | -$38         |
| 2024.02  | +$89    | 1.18 | 762    | 3.4%   | -$52         |
| 2024.03  | -$23    | 0.94 | 901    | 4.8%   | -$71         |
| ...      |         |      |        |        |              |
| 2026.03  | +$201   | 1.42 | 814    | 1.9%   | -$29         |

## Summary
- Total months: 27
- Profitable months: 22 (81%)
- Avg monthly profit: +$98
- Avg monthly PF: 1.28
- Worst month: 2024.03 (-$23, PF 0.94)
- Best month: 2026.03 (+$201, PF 1.42)
- Max DD in any month: 4.8%
- Months with DD > 3%: 4
```

3. Save results to prototypes/results/[name]_monthly.md

## Usage

```
/monthly hedge_multi_pair 2024.01 2026.04
/monthly accumulating_hedge 2024.01 2025.12
```

Arguments:
- EA name (without .mq5)
- Start month (YYYY.MM)
- End month (YYYY.MM)

## Settings

Use the SAME parameters as the EA's current input defaults.
Deposit: 10000 USD (same for every month — this is the point).
Leverage: 1:30.
Symbol: EURUSD (or all pairs if multi-pair EA).

## Execution

Generate all .ini files first, then run them sequentially.
Each backtest is independent — no carry-over between months.
ShutdownTerminal=1 on each so they chain automatically.

After all runs complete, read all reports and build the summary.

## Why this matters

A standard 2-year backtest compounds profits — month 24 trades
with 10x the balance of month 1. The monthly breakdown shows
TRUE per-month performance with equal capital, revealing:
- Which months are consistently profitable
- Seasonal patterns (summer doldrums, year-end volatility)
- Whether the strategy works in ALL months or just a few good ones
- Real max drawdown risk per month (not diluted by prior profits)