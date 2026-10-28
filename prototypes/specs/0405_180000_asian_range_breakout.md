# Asian Range Breakout

## Thesis
The Asian session (00:00-07:00 UTC) builds a consolidation range as low-volume
participants set a narrow price band. When London opens (07:00-09:00 UTC),
institutional order flow decisively breaks one side of this range and follows
through. The breakout direction often holds for the first 1-2 hours of London.
This targets a completely different market condition (momentum) than mean
reversion, and fills the pre-CEST-17:00 idle window.

## Base (v1)
Timeframe: M1
Session: 07:00-09:00 UTC only (London open)
Setup: Calculate Asian range high/low from 00:00-06:59 UTC bars
Entry buy: Price closes above Asian high + 3-pip buffer
Entry sell: Price closes below Asian low - 3-pip buffer
Exit: SL at opposite side of Asian range (capped at 25 pips), TP = 1.5x SL distance
Indicators: None (pure price action + time filter)
Max 1 trade per day on this strategy.

## v2: WaveTrend momentum confirmation
Same as v1, but require WaveTrend M1 to agree with direction:
Buy breakout only if wt1 > 0 and rising (wt1 > wt2)
Sell breakout only if wt1 < 0 and falling (wt1 < wt2)
Filters out false breakouts where WT shows exhaustion.

## v3: SMC zone validation
Same as v1, but skip trade if a strong SMC order block sits within
1x ATR of the breakout direction. E.g. don't buy if a supply zone
is just above the Asian high — price likely reverses there.

## v4: Tight range filter
Only trade when Asian range is between 15-40 pips.
Below 15 = holiday/no liquidity (unreliable).
Above 40 = already volatile, breakout less meaningful.

## Optimize
- Asian session end hour: 6, 7, 8
- Entry buffer above/below range: 1-5 pips (step 1)
- SL method: opposite side vs fixed 15/20/25 pips
- TP ratio: 1.0x, 1.5x, 2.0x SL distance
- Min range filter: 10, 15, 20 pips
- Max range filter: 30, 40, 50 pips

## Notes
Targets London-open momentum. Completely different edge from mean reversion.
Only 1 trade/day limits exposure. Should perform best Tue-Thu when London
liquidity is highest. Avoid Mondays (slow open) and Fridays (position squaring).
