# Friday Afternoon Mean Reversion

## Thesis

On Friday afternoons (15:00-20:00 CET), traders systematically unwind
positions ahead of weekend gap risk. Hedge funds reduce leverage. Prop
desks neutralize directional bets. Retail closes positions to avoid
weekend uncertainty. The aggregated effect is one of the most
predictable behavioral patterns in FX: trend strength weakens, mean
reversion strengthens, and the closing prints often retrace toward the
week's volume-weighted center.

This is a SESSION-RESTRICTED amplification of the validated WaveTrend
mean reversion edge. The hypothesis: WT signals on Friday afternoons
have a HIGHER win rate than the same signals on other days, because the
underlying flow regime favors reversal. Same trigger, better filter
(day-of-week + time-of-day combined).

The strategy fills a specific behavioral gap: Friday afternoon is the
most reliably mean-reverting time of the trading week. Even if Monday-
Thursday WT signals work, Friday signals should work BETTER.

## Evidence

1. **WT crossover with M10 confirmation validated (#1, PF 1.09)**: the
   baseline edge to amplify. The strategy doesn't invent a new signal;
   it filters the existing validated signal by day/time.

2. **DECISION 2026-04-03 — Mean reversion at clear levels works**:
   BB+RSI is the production stack. Friday afternoon is when the
   "mean reversion regime" is structurally strongest.

3. **Project context — 17:00-22:00 CEST is strongest session**:
   Friday afternoon overlaps the start of this window (17:00 CET on
   Friday = NY proper). Aligns with project preference.

4. **Combined hedge weakest in 2024 ranging year, strongest in 2023
   trending year (#10)**: hedges profit from trends. Mean reversion
   profits from anti-trends. Friday afternoons are anti-trend by
   default. This strategy targets the opposite regime to the hedge.

5. **Weekend gap risk literature**: documented in FX academic
   literature (Berument and Kiymaz 2001 — "The day of the week effect
   on the volatility of FX returns"). Friday closes show measurably
   different statistical properties than other day closes.

6. **Project context — idle time problem**: WT mean reversion is
   active throughout the week but especially strong on Fridays.
   Concentrating trades into a high-conviction window improves capital
   efficiency.

## Base (v1)

**Timeframe**: M1

**Setup**:
- Day must be Friday (DayOfWeek == 5 in MqlDateTime)
- Time must be `[WindowStartHour, WindowEndHour)` CET — default
  [15:00, 20:00)
- Compute WaveTrend cross on M1
- Confirm WT exhaustion direction:
  - BUY: M1 cross from oversold (`wt1Prev <= wt2Prev` and now
    `wt1 > wt2`, with prior wt1 < `WT_OS`)
  - SELL: M1 cross from overbought (analogous, prior wt1 > `WT_OB`)

**Confirmation**:
- M10 WT in matching exhaustion zone (the validated #1 filter)

**Entry**:
- Market entry on M1 cross bar close
- Single position, never both directions

**Exit**:
- TP: ATR(14) × `TP_ATR` (default 2.0)
- SL: ATR(14) × `SL_ATR` (default 1.5)
- Trail to break-even after price moves ATR × `TrailTrigger` in profit
- HARD time stop at 21:30 CET (avoid weekend gap exposure)

**Indicators**: WaveTrend (M1, M10), ATR(14)

## v2: Tighter WT thresholds (more sensitive)

Same as v1 but WT thresholds are loosened:
- `WT_OB` = 50 (instead of 60)
- `WT_OS` = -50 (instead of -60)

**Why this might work**: Friday afternoons have weaker momentum, so
oscillator extremes are rarer. Loosening thresholds captures more
setups while the day-of-week filter maintains quality.

**Why this might fail**: Looser thresholds = more noise. The WT cross
near zero is statistically meaningless.

## v3: Counter-week-trend bias

Same as v1 but additionally require the trade to be AGAINST the week's
overall direction:
- WeekTrend = sign(close at Friday 15:00 - close at Monday 09:00)
- BUY only if WeekTrend < 0 (week was bearish, now reverting up)
- SELL only if WeekTrend > 0 (week was bullish, now reverting down)

**Why this might work**: The "Friday unwind" thesis is specifically
about UNWINDING the week's positioning. Reversing weekly direction is
the precise expression of that thesis.

**Why this might fail**: Weekly trend filter cuts trade count in half.
Some Friday reversions follow the week's trend (continuation patterns).

## v4: Last-hour scalp (19:00-20:00 CET)

Same as v1 but window is the last hour only — 19:00-20:00 CET.

**Why this might work**: The last hour is when unwinding is most
intense. Liquidity drops, volatility flattens. Mean reversion is at
its theoretical peak.

**Why this might fail**: Sample size is tiny (1 hour × 52 Fridays = 52
hours of trading per year). Total trades may be < 50/year.

## v5: All weekdays comparison baseline

Run the same logic on all weekdays (Mon-Fri) at the same hour. This is
NOT a new strategy — it's the comparison set to verify Friday is
actually better than other days.

**Why this might work** (as comparison): if Friday WR is significantly
higher than Mon-Thu, the day-of-week filter is real edge. If WR is
similar, the strategy is just a session filter and doesn't need the
Friday restriction.

**Why this might fail** (as comparison): may show no day-of-week
effect, in which case the entire strategy collapses to "WT signals at
NY hours" (which is already covered by other ideas).

## v6: Lot scaling on Fridays

Same as v1 but increase lot size by `FridayMultiplier` (default 1.5x)
because the conviction is higher.

**Why this might work**: If Friday signals are validated as better
than other days, sizing UP is the optimal Kelly approach.

**Why this might fail**: Larger position on a regime-dependent edge
concentrates risk. If the edge fades (e.g. central banks change Friday
behavior), losses are amplified.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: This IS the baseline +
  day/time filter. Should be a strict subset of baseline trades.
  **Critical**: must show measurable WR improvement vs Mon-Thu signals
  taken at the same hours. Otherwise, the day filter is noise.

- **vs WT + CHoCH (sister 0408_120100)**: Both filter WT signals. Could
  combine in a future version (Friday + CHoCH alignment).

- **vs WT MTF Score (sister 0411_013100)**: Both filter WT signals.
  Could combine: Friday + MTF score >= 2. Likely the strongest
  filtered version possible.

- **vs London Close Mean Reversion (sister 0411_012500)**: Both target
  late-day reversion. London Close is calendar-anchored to specific
  hours; this is day-of-week-anchored. Some overlap but different
  triggers.

- **vs hedge accumulators**: No conflict. Hedge runs all week, all
  hours. This is a focused subset.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `WindowStartHour` | 14-17 | 1 | Friday window start (CET) |
| `WindowEndHour` | 18-21 | 1 | Friday window end (CET) |
| `WT_OB` | 40-70 | 5 | Overbought threshold |
| `WT_OS` | -70 to -40 | 5 | Oversold threshold |
| `TP_ATR` | 1.5-3.0 | 0.5 | TP ATR multiplier |
| `SL_ATR` | 1.0-2.5 | 0.5 | SL ATR multiplier |
| `TrailTrigger` | 0.5-2.0 | 0.5 | Trail trigger ATR multiplier |
| `FridayMultiplier` (v6) | 1.0-2.0 | 0.25 | Lot scaling factor |

## Notes

**Market condition targeted**: Friday afternoon weekend-unwind regime.
Strategy active ~5 hours/week (one Friday session). All other times
silent.

**Risk profile**: Mid-high win rate (target 60-65%, +5-10% vs baseline),
modest R:R (target 1.2-1.7:1). The improvement should come from WR
boost, not bigger winners.

**Critical: hard time stop at 21:30 CET**:
- Markets close at 22:00 CET on Fridays
- Weekend gap risk is real — Sunday open can be 50+ pips away
- NEVER hold a position past 21:30 Friday
- Even if TP is close, exit at time stop to eliminate gap risk

**Edge cases**:
1. **NFP Friday (first Friday of month)**: NFP at 14:30 CET creates
   extreme volatility. NewsFreezeGuard handles entry blocking.
   Post-NFP is the perfect setup for this strategy IF the news fade
   sister strategy isn't also running.
2. **Holiday Fridays** (Good Friday, day after Thanksgiving):
   reduced volume, weird flows. Consider skip via calendar.
3. **End of month + Friday**: month-end rebalancing intensifies
   unwinding. Should be the best setup days. Worth tracking
   separately.
4. **Quarter end + Friday**: even stronger effect than month end.
   Tag these days in backtest reports.

**Failure modes to watch**:
- Friday WR ≤ Mon-Thu WR → no day-of-week effect, strategy invalid
- Total trades < 50/year → window too narrow
- Profitable only in specific months → seasonal effect, not
  day-of-week
- Lot scaling (v6) erratic equity curve → confidence sizing is noise
  amplification

**Open question**: should the strategy also trade THURSDAY late
afternoons (some traders unwind early)? Test as v7. The hypothesis
weakens but the filter relaxes.
