# Result: wt_choch_confirmation — v2 default
Date: 2026-04-11
Period: 2025.01.01 - 2026.01.01
Symbol: EURUSD M1 (entries) + M5 (CHoCH detection)

## Parameters
- SwingLength = 30 (on M5)
- MaxChochAgeM5 = 12 M5 bars (= 60 M1 bars)
- WT_OB = 53, WT_OS = -53
- ATR_Period = 14, SL_ATR = 1.5, TP_ATR = 2.5

## Metrics (spec polarity: BUY needs BULLISH M5 CHoCH)
- Total Net Profit: -$1.06
- Profit Factor: 0.83
- Sharpe Ratio: -5.00
- Total trades: 33
- Win rate: 27.27% (9/33)
- Avg win: $0.58
- Avg loss: $0.22
- R:R: 2.64:1
- Equity DD: 0.02%

## Notes
- Cross-TF version using M5 for CHoCH detection
- 33 trades over a year (very few signals)
- 27% WR with 2.64 R:R = EV slightly negative (-$0.02 per trade)
- Same structural problem as v1: WT extremes and CHoCH events on EURUSD
  don't temporally align well, regardless of which timeframe CHoCH is
  detected on
- v2 produces fewer trades than v1 (33 vs 0/654) — M5 CHoCH is more
  meaningful but still doesn't catch the right reversals
