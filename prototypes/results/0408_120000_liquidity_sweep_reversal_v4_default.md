# Result: liquidity_sweep_reversal — v4 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 20
- MaxSwingAge = 30
- MinPierceMult = 1.5
- MaxBarsInTrade = 30
- StopBufferPips = 2.0
- ConfirmWindow = 3 (multi-bar close-back-in)

## Metrics
- Total Net Profit: -$1.24
- Profit Factor: 0.98
- Sharpe Ratio: -1.39
- Total trades: 194 (vs 149 in v1)
- Win rate: 44.33% (86/194)
- Avg win: $0.64
- Avg loss: $0.47
- R:R: 1.36:1
- EV per trade: -$0.006
- Largest win: $2.57
- Largest loss: $1.27
- Equity DD: 0.12% ($11.94)

## Notes
- Wider confirmation window adds 30% more trades (149 → 194) but DROPS PF
  from 1.06 to 0.98 — turns marginally profitable into marginally losing
- Win rate drops from 47.65% to 44.33% — wider window catches noisier setups
- Confirms spec's "why this might fail": dilution from extending the window
- The IMMEDIATE-next-bar requirement (v1) is the cleaner signal
