# Result: liquidity_sweep_reversal — v3 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 20
- MaxSwingAge = 30
- MinPierceMult = 1.5
- MaxBarsInTrade = 30
- StopBufferPips = 2.0
- SessionStartHour = 15 (broker time)
- SessionEndHour = 20

## Metrics
- Total Net Profit: -$0.02 (flat)
- Profit Factor: 1.00
- Sharpe Ratio: -0.08
- Total trades: 56 (vs 149 in v1)
- Win rate: 48.21% (27/56)
- Avg win: $0.67
- Avg loss: $0.57
- R:R: 1.18:1
- EV per trade: $0.00
- Equity DD: 0.04% ($4.41)

## Notes
- Session filter cuts trade count by 62% (149 → 56)
- PF drops from 1.06 to 1.00 — session filter REMOVES the small edge
- Win rate basically unchanged (47.65% → 48.21%) → session is not the
  discriminator; setups are equally good across all sessions
- Confirms spec's "why this might fail": removing other sessions removes
  setups without improving quality
- The strategy does NOT have a session-of-day edge
