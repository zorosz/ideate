# Summary: dynamic_lots — balance-based lot sizing

IMPORTANT: dollar profits are meaningless with dynamic lots — use PERCENTAGE return and DD%.

## All versions — default vs optimized (2024.01-2026.01, $10K start, 1:30 leverage)

| Version | Params | Trades | Return% | PF | Sharpe | MaxDD% | Sensitivity |
|---------|--------|--------|---------|------|--------|--------|-------------|
| v1 Risk0.5,Incr0.5 | Default | 72284 | 3498% | 1.26 | 8.97 | 7.3% | |
| v1 | Opt H4,Cap7,Incr1.0,M3 | 96745 | 31479% | 1.29 | 25.14 | 4.5% | Sensitive |
| v2 Risk0.25 | Default | 60432 | 327% | 1.31 | 6.13 | 7.4% | |
| v2 | Opt H3,Cap8,Incr1.0,M3 | 179373 | 6506% | 1.37 | 25.46 | 3.4% | Sensitive |
| v3 Risk1.0,Incr0.75 | Default | 74474 | 158056% | 1.19 | 10.50 | 8.1% | |
| v3 | Opt H3,Cap7,Incr0.8,M3 | 161995 | 200987% | 1.15 | 24.76 | 8.1% | Robust |
| v4 Incr0.25 | Default | 68948 | 739% | 1.20 | 6.74 | 7.4% | |
| v4 | Opt H3,Cap7,Incr1.0,M3 | 160646 | 147085% | 1.22 | 29.32 | 7.3% | Fragile |
| v5 Cap4 | Default | 34995 | 662% | 1.34 | 5.22 | 4.7% | |
| v5 | Opt H3,Cap7,Incr1.0,M3 | 160646 | 147085% | 1.22 | 29.32 | 7.3% | Fragile |

## Best risk-adjusted: v2 optimized (PF 1.37, DD 3.38%, Recovery 30.78)
## Best default: v5 (PF 1.34, DD 4.71%, Cap=4 inherently limits risk)

## Key findings

1. **Dynamic lots enable compound growth** — v1 default turns $10K into $360K in 2 years (3498% return) with 7.3% max DD.
2. **v3 is exponentially dangerous** — $10K to $15.8M (158,000% return) sounds amazing but PF 1.19 and DD 8% means one bad streak could wipe it out.
3. **v5 (Cap=4) is the safest default** — PF 1.34, only 4.71% DD, still 662% return. The cap of 4 naturally limits compound risk.
4. **All optimizers push IncrementRatio toward 1.0** — larger accumulated positions compound faster on reversal.
5. **MaxFloatingLossPct=3 universally preferred** — tighter kill switch, faster recovery restart.
6. **v4 and v5 converge to identical optimums** — the cap difference disappears when optimizer chooses Cap=7.
7. **Risk compounding is real**: a 7% drawdown at $350K is $24,500, not $733. Emergency kill becomes critical.

Sensitivity:
- Robust: optimization improved return/DD < 50%
- Sensitive: 50-200%
- Fragile: > 200%
