# Summary: all_time_hedge (per-position harvest)

## All versions — default vs optimized

| Version | Params | Trades | Win% | EV | PF | Sharpe | MaxDD | Sensitivity |
|---------|--------|--------|------|------|------|--------|-------|-------------|
| v1 H30,B10 | Default | 2533 | 76.0% | -0.12 | 0.94 | -0.19 | 25.5% | |
| v1 | Opt H10,B30,M5 | 50888 | — | +0.27 | 1.49 | 3.45 | 7.4% | Fragile |
| v2 H15,B10 | Default | 15183 | 80.7% | +0.27 | 1.31 | 1.26 | 14.2% | |
| v2 | Opt H10,B20,M5 | 44466 | — | +0.22 | 1.37 | 2.99 | 10.3% | Robust |
| v3 H30,B30 | Default | 3705 | 79.0% | +0.17 | 1.09 | 0.31 | 19.4% | |
| v3 | Opt H10,B30,M5 | 50888 | — | +0.27 | 1.49 | 3.45 | 7.4% | Fragile |
| v4 H30,WT | Default | 3155 | 50.7% | -0.02 | 0.99 | -0.45 | 4.7% | |
| v4 | Opt H45,WT(15,10) | 1109 | — | +0.06 | 1.04 | 4.42 | 0.4% | N/A (near-zero) |
| v5 H30,noBatch | Default | 23636 | 65.8% | -0.10 | 0.95 | -0.95 | 36.9% | |
| v5 | Opt H50,M5 | 4568 | — | +0.40 | 1.15 | 2.08 | 4.3% | Fragile |

## Best: v1/v3 optimized (Profit = $13,840, PF 1.49, Sharpe 3.45)

Parameters: HarvestPips=10, BatchClosePips=30, MaxFloatingLossPct=5

v2 default is notable — already profitable at +$4,095 with PF 1.31 without optimization (Robust).

## Key findings

1. **HarvestPips=10 dominates** — optimizer pushed all batch-close versions to the minimum.
   Even tighter harvest (5 pips?) should be tested.
2. **BatchClosePips=20-30 is optimal** — not too tight (premature close) or too wide (never triggers).
3. **MaxFloatingLossPct=5 preferred** — tight emergency kill protects capital.
4. **v4 (WT batch close) nearly useless** — WT cross signals are too rare to time batch close.
   The fixed pip threshold is superior for batch close timing.
5. **v5 (no batch close) can be profitable** when optimized (H=50, M=5) but much weaker.
6. **v2 default is Robust** — HarvestPips=15 is close to optimal H=10, needs no tuning.
7. **Per-position vs pure distance**: this spec's v2 default (+$4,095) strongly outperforms
   the pure distance spec's v2 default (+$399). Per-position harvest captures more profit.

Sensitivity guide:
- Robust: optimization improved EV < 50%
- Sensitive: optimization improved EV 50-200%
- Fragile: optimization improved EV > 200%
