# WaveTrend crossover

## Base (v1)
Timeframe: M1
Entry buy: WaveTrend wt1 crosses above wt2 while wt1 < -53
Entry sell: WaveTrend wt1 crosses below wt2 while wt1 > 53
Exit: SL 15 pips, TP 30 pips
Indicators: WaveTrend (channel=10, average=21). Import WaveTrend.mqh.

## v2: M10 WaveTrend confirmation
Add M10 WaveTrend filter: only enter if M10 wt1 is also in the same zone
(M10 wt1 < -30 for buy, M10 wt1 > 30 for sell)

## v3: stronger oversold/overbought levels
Change entry levels to the stronger thresholds:
Entry buy: wt1 < -60 (instead of -53)
Entry sell: wt1 > 60 (instead of 53)

## v4: WaveTrend + RSI double confirmation
Add RSI(14) filter on top of v1:
Buy only if RSI < 35
Sell only if RSI > 65

## Notes
Testing which combination of filters gives the best edge.
v1 is the raw signal, v2-v4 each add one filter to see individual impact.