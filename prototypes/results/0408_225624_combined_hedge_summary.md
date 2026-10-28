# Summary: combined_hedge — per-position harvest + trend protection

## All versions — default vs optimized

| Version | Params | Trades | Win% | EV | PF | Sharpe | MaxDD | Sensitivity |
|---------|--------|--------|------|------|------|--------|-------|-------------|
| v1 H15,Cap3,LotInc.01 | Default | 1347 | 66.5% | +0.44 | 1.37 | 1.41 | 4.4% | |
| v1 | Opt H5,Cap6,LotInc.01,M3 | 37829 | — | +0.22 | 1.55 | 11.60 | 3.0% | Robust* |
| v2 H10 | Default | 1668 | 68.2% | +0.19 | 1.19 | 0.69 | 4.6% | |
| v2 | Opt H5,Cap6,LotInc.01,M7 | 36373 | — | +0.21 | 1.49 | 9.93 | 6.8% | Sensitive |
| v3 LotInc=0 | Default | 551 | 69.0% | -0.13 | 0.90 | -0.37 | 2.8% | |
| v3 | Opt H5,Cap6,LotInc.025,M6 | 40308 | — | +0.49 | 1.80 | 9.13 | 6.1% | Fragile |
| v4 Cap5 | Default | 4146 | 61.3% | +0.38 | 1.32 | 2.21 | 7.1% | |
| v4 | Opt H5,Cap6,LotInc.03,M3 | 41496 | — | +0.46 | 1.70 | 14.85 | 3.2% | Robust |
| v5 LotInc.02 | Default | 1244 | 67.6% | +0.58 | 1.36 | 1.06 | 5.9% | |
| v5 | Opt H5,Cap6,LotInc.025,M4 | 40994 | — | +0.50 | 1.83 | 10.31 | 3.0% | Robust |

*v1 Robust: default EV ($0.44) is actually HIGHER than optimized EV ($0.22) — optimization traded volume for per-trade quality

## Best optimized: v5 (EV=$0.50, PF=1.83, DD=3.0%)

## Best default: v1 (EV=$0.44, PF=1.37, Sharpe=1.41, DD=4.4%)

## Key findings

1. **v1 default is the strongest unoptimized result ever tested** — PF 1.37, Sharpe 1.41 with zero tuning. The combined per-position harvest + cap + count-close + lot increment works out of the box.
2. **Lot increment is essential** — v3 (LotInc=0) is the only losing version. All optimizers push LotInc to 0.01-0.03.
3. **All optimizers converge to H=5, Cap=6** — tightest harvest + deepest stacking. This produces 37K-41K trades/year, essentially a high-frequency scalper profile.
4. **Sharpe 10-14 in optimization is unrealistic** — likely overfitting to 2025 tick data. OOS validation will be the real test.
5. **v3 proves the thesis** — without lot increment, the strategy loses money. The increasing lots ARE the recovery mechanism.
6. **Cap=5 (v4) generates 3x more trades than Cap=3 (v1)** — more accumulation cycles = more batch close opportunities, but higher DD (7.1% vs 4.4%).

Sensitivity guide:
- Robust: optimization improved EV < 50%
- Sensitive: optimization improved EV 50-200%
- Fragile: optimization improved EV > 200%
