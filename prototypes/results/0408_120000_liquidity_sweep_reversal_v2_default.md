# Result: liquidity_sweep_reversal — v2 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 20
- MaxSwingAge = 30
- MinPierceMult = 1.5
- MaxBarsInTrade = 30
- StopBufferPips = 2.0
- WT_Threshold = 60.0 (added)

## Metrics
- Total Net Profit: -$0.44
- Profit Factor: 0.00
- Sharpe Ratio: -1.89
- Total trades: 1
- Win rate: 0% (0 winners / 1 loser)
- Avg loss: $0.41
- EV per trade: -$0.44
- Equity DD: 0.00% ($0.44)

## Notes
- COLLAPSED: WT exhaustion filter at +/-60 produced only 1 signal in 12 months
- This validates the spec's "why this might fail" prediction:
  "Sweep signals occur from neutral WT states. Filter collapses signal frequency."
- The combination of sweep + close-back-in + WT exhaustion is too restrictive
- v2 effectively non-functional — abandon as a primary candidate
