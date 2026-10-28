# Result: liquidity_sweep_reversal — v1 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 20
- MaxSwingAge = 30
- MinPierceMult = 1.5
- MaxBarsInTrade = 30
- StopBufferPips = 2.0

## Metrics
- Total Net Profit: +$2.43
- Profit Factor: 1.06
- Sharpe Ratio: 3.68
- Recovery Factor: 0.29
- Total trades: 149
- Win rate: 47.65% (71 winners / 78 losers)
- Avg win: $0.62
- Avg loss: $0.48
- R:R ratio: 1.29:1
- EV per trade: +$0.016
- Largest win: $1.56
- Largest loss: $1.27
- Max equity DD: 0.08% ($8.36)
- Avg position holding time: 0:17:57 (out of 30 bar max)
- Long trades: 82 (45.12% WR)
- Short trades: 67 (50.75% WR)

## Notes
- Marginal positive edge — PF just above breakeven (1.06)
- Profile diverged from spec prediction: predicted 30-40% WR / 2.5-4:1 RR;
  actual is 47% WR / 1.29:1 RR. The "balanced" profile suggests many trades
  exiting via time stop rather than SL/TP extremes.
- Sharpe 3.68 is high relative to PF — small but consistent gains
- Equity DD trivial (0.08%) → very low risk per trade
- 149 trades / year = healthy frequency for this trigger family
- Long bias underperforms short bias by ~5%
