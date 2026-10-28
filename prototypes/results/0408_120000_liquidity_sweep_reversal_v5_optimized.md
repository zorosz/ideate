# Result: liquidity_sweep_reversal — v5 optimized
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1
Optimization: genetic, criterion = Balance + PF max
Total passes: 220

## Best optimized parameters
| Parameter | Default | Optimized |
|-----------|---------|-----------|
| SwingLength | 20 | 20 |
| MaxSwingAge | 30 | 30 |
| MinPierceMult | 1.5 | 2.5 |
| MaxBarsInTrade | 30 | 40 |
| StopBufferPips | 2.0 | 2.0 |
| ZoneProximity | 10.0 | 25.0 |

## Optimized metrics
- Total Net Profit: +$5.84
- Profit Factor: 1.14
- Sharpe Ratio: 8.30
- Total Trades: 147
- Equity DD: 0.064%

## Comparison vs default
| Metric | Default | Optimized | Δ |
|--------|---------|-----------|---|
| Profit | +$3.00 | +$5.84 | +95% |
| PF     | 1.08   | 1.14   | +6% |
| Sharpe | 4.88   | 8.30   | +70% |
| Trades | 141    | 147    | +4% |

## Sensitivity verdict
**ROBUST** — optimization improved EV by ~95% (within Robust threshold).
Top 5 share core: SwingLength=20, MaxSwingAge=30, MinPierceMult=2.0-2.5,
MaxBarsInTrade=40-60, ZoneProximity=5-25 (wide range — not sensitive).

## Notes
- Modest PF improvement (1.08 → 1.14)
- Trade count nearly unchanged (141 → 147)
- Higher pierce multiplier (2.5 vs 1.5) and longer time stop (40 vs 30)
- Wider zone proximity (25 vs 10) — confluence is loose
- ZoneProximity range (5-25) is a wide acceptable range, suggesting
  the OB confluence filter is not parameter-sensitive
- Compared to v3 optimized: lower PF but more trades, higher base profit
  per trade unclear
