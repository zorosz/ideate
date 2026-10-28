# Summary: accumulating_hedge_pure_distance — trend protection variations

## All versions — default vs optimized

| Version | Params | Trades | Win% | EV | PF | Sharpe | MaxDD | Sensitivity |
|---------|--------|--------|------|------|------|--------|-------|-------------|
| v1 Cap | Default | 417 | 59.7% | +0.26 | 1.09 | 0.54 | 1.8% | |
| v1 | Opt H80,B30,Cap5,M6 | 309 | — | +1.00 | 1.38 | 2.21 | 1.3% | Fragile |
| v2 Increment | Default | 84 | 51.2% | -2.90 | 0.66 | -0.84 | 4.9% | |
| v2 | Opt H40,Inc10,B40,M3 | 396 | — | +0.82 | 1.36 | 1.44 | 1.4% | Fragile |
| v3 CountClose | Default | 426 | 59.6% | +0.27 | 1.09 | 0.51 | 2.0% | |
| v3 | Opt H100,MinPos2,M4 | 210 | — | +1.59 | 1.56 | 2.98 | 1.0% | Fragile |
| v4 LotIncr | Default | 428 | 59.4% | +0.88 | 1.17 | 0.57 | 7.2% | |
| v4 | Opt H80,B30,Lot0.02,M4 | 309 | — | +4.13 | 1.83 | 2.44 | 4.6% | Fragile |
| v5 Combined | Default | 417 | 59.7% | +0.83 | 1.16 | 0.57 | 5.8% | |
| v5 | Opt H100,Cap3,MinPos2,Lot0.01,M3 | 204 | — | +3.29 | 1.95 | 3.35 | 1.8% | Fragile |

## Best: v5 optimized (EV=$3.29, Sharpe=3.35, PF=1.95, DD=1.76%)

Parameters: HarvestPips=100, MaxPositionsPerSide=3, BatchCloseMinPositions=2, LotIncrement=0.01, MaxFloatingLossPct=3

## Key findings

1. **Position cap (v1) reduces DD dramatically** — from base ~5% to 1.77% default, 1.32% optimized.
   Linear loss instead of quadratic.
2. **Increasing harvest distance (v2) is counterproductive** — only 84 trades default, negative.
   Slowing accumulation also slows profit capture.
3. **Count-based batch close (v3) equals fixed pip threshold** on defaults (PF 1.09 both).
   Optimized, it shines: MinPos=2 with any profit gives Sharpe 2.98.
4. **Lot increment (v4) amplifies everything** — highest profit ($1,276) but also highest DD (4.63%).
   The 0.02 lot increment is aggressive.
5. **Combined v5 is the best risk-adjusted** — cap limits exposure, early batch close takes profit,
   lot increment accelerates recovery. Sharpe 3.35, PF 1.95, DD 1.76%.
6. **All versions are Fragile** — all defaults had low EV, optimization changed behavior dramatically.
7. **Wider harvest (80-100) works better here** than in the base spec (60-70) because the
   protection mechanisms handle the accumulated risk better.

Sensitivity guide:
- Robust: optimization improved EV < 50%
- Sensitive: optimization improved EV 50-200%
- Fragile: optimization improved EV > 200%
