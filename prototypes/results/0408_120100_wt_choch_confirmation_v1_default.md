# Result: wt_choch_confirmation — v1 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1

## Parameters
- SwingLength = 30
- MaxChochAge = 20 bars
- WT_OB = 53, WT_OS = -53
- ATR_Period = 14, SL_ATR = 1.5, TP_ATR = 2.5
- TrailTrigger = 1.0

## Spec polarity (BUY needs BULLISH CHoCH)
- Total trades: 0
- The spec's polarity assumption produces zero signals on M1
- Reason: At WT oversold extremes, the most recent CHoCH is BEARISH (price
  was falling and broke last swing low). A bullish CHoCH at the same moment
  would require a very specific double-bottom pattern that's extremely rare
  on M1.

## Inverted polarity (BUY needs BEARISH CHoCH)
- Total Net Profit: -$63.77
- Profit Factor: 0.56
- Sharpe Ratio: -5.00
- Total trades: 654
- Win rate: 21.41% (140/654)
- Avg win: $0.59
- Avg loss: $0.25
- R:R: 2.36:1
- Equity DD: 0.67% ($66.88)

## Notes
- v1 fails in BOTH polarities
- The 21% WR with 2.36:1 R:R is profile of "catching late moves" — by
  the time CHoCH fires, the reversal is already happening and entering
  on WT cross is too late
- The spec's hypothesis "WT cross + CHoCH agreement" is fundamentally
  broken on M1: CHoCH events do not temporally align with WT extremes
  in a useful way
- The validated WT crossover edge alone (PF 1.09) cannot be improved
  by SMC CHoCH structural confirmation at this timeframe
- Result file uses inverted polarity numbers since the spec polarity
  has 0 trades (cannot compute meaningful metrics)
