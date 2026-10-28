# Summary: multi_pair — combined hedge across multiple pairs

| Pair | Trades | Win% | PF | Sharpe | MaxDD% | Net Profit | RecFact |
|------|--------|------|------|--------|--------|------------|---------|
| EURUSD | 36405 | 60.86% | 1.50 | 9.97 | 5.19% | $7,551 | 9.02 |
| GBPUSD | 41225 | 60.27% | 1.42 | 9.06 | 3.62% | $7,406 | 11.44 |
| USDJPY | 80222 | 60.58% | 1.46 | 12.17 | 4.89% | $11,118 | 19.49 |
| **Combined** | **157852** | **~60.5%** | **~1.46** | — | **~5% est** | **$26,075** | — |

## Key findings
1. **Strategy generalizes across pairs** — all 3 profitable with PF > 1.4
2. **USDJPY is the strongest** — highest profit ($11.1K), Sharpe (12.17), recovery (19.49). 80K trades suggests more harvesting opportunities due to JPY volatility.
3. **GBPUSD has the lowest DD** (3.62%) despite wider spreads
4. **Win rate is consistent at ~60%** across all pairs — same as EURUSD single-pair tests
5. **Combined portfolio profit: ~$26K** from $10K — higher than any single pair
6. **No optimization needed** — default params work across all 3 pairs
7. **Portfolio diversification reduces regime risk** — when one pair trends, others may range

## Deployment recommendation
Run on all 3 pairs simultaneously with 1/3 risk each (RiskPctPerLot=0.17 per pair with dynamic lots, or Proto_LotSize=0.01/3 each with fixed lots).
