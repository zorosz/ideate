# Result: liquidity_sweep_reversal — v5 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 20
- MaxSwingAge = 30
- MinPierceMult = 1.5
- MaxBarsInTrade = 30
- StopBufferPips = 2.0
- ZoneProximity = 10.0 (OB confluence on TP target)

## Metrics
- Total Net Profit: +$3.00
- Profit Factor: 1.08
- Sharpe Ratio: 4.88
- Recovery Factor: 0.44
- Total trades: 141 (vs 149 in v1)
- Win rate: 47.52% (67/141)
- Avg win: $0.62
- Avg loss: $0.46
- R:R: 1.35:1
- EV per trade: +$0.021
- Largest win: $1.56
- Largest loss: $1.27
- Equity DD: 0.07% ($6.86)

## Notes
- BEST version so far — PF 1.08 (vs v1: 1.06, v3: 1.00, v4: 0.98)
- Highest Sharpe ratio so far (4.88)
- OB confluence filter removes only 8 trades (149 → 141) but improves quality
- The TP target landing inside an existing OB IS a meaningful filter
- Trade count remains healthy (141/year)
- This validates the confluence hypothesis: structural target + structural
  trigger work together
- Candidate for best version after optimization
