# Daily Pivot S1/R1 Reversal

## Thesis

Standard daily pivot points — calculated from prior day's High, Low, and
Close — are watched by the largest cross-section of intraday traders in
FX. Retail systems use them as default targets. Many institutional desks
calibrate around them. Bloomberg and TradingView display them by default.
The result: pivot levels (P, S1, R1, S2, R2) act as self-fulfilling
intraday turning points.

The most reliable pivot reaction is at S1 and R1 — the first standard
deviation levels. Price reaching S1 from above tends to reverse back
toward the central pivot P. Same for R1 from below. The levels are
calculated once per day from yesterday's data and remain fixed, removing
parameter ambiguity.

This strategy fills the European session gap (08:00-15:00 CET) where
WaveTrend mean reversion fires sporadically. It uses fixed price levels
as the trigger, not oscillator extremes — different signal source,
likely uncorrelated with WT timing.

## Evidence

1. **WT crossover validated (#1, PF 1.09)**: oscillator mean reversion
   edge confirmed on EURUSD M1. This strategy applies the same edge
   family with a different trigger (level proximity instead of
   oscillator state).

2. **DECISION 2026-04-03 — Mean reversion at clear levels works**:
   BB+RSI mean reversion is the production decision. Pivots are an
   alternative "clear level" type — calculated from objective price
   data, no parameters.

3. **Order Block Rejection Scalp (#3) validated**: rare but real
   reactions at structural levels. Pivots are universal structural
   levels watched by everyone — should produce reactions of similar
   character.

4. **Project context — 17:00-22:00 CEST is strongest, but 08:00-15:00
   CET is currently uncovered**: Existing WT strategies are silent for
   most of the European morning. Pivot reactions fire during this gap.

5. **DeBondt & Thaler 1985** (academic): widely-watched price levels
   create self-fulfilling reversal points because expectations cluster.
   Daily pivots are exactly such a level.

6. **Key Learning #4 — Session-based strategies need higher TFs**: this
   strategy uses daily levels (the highest possible TF), not session
   ranges. The level itself is a higher-TF construct.

## Base (v1)

**Timeframe**: M1

**Pivot calculation** (once per day, at 00:00 server time):
- PriorDayHigh = max(High) over yesterday's bars
- PriorDayLow  = min(Low)  over yesterday's bars
- PriorDayClose = close of yesterday's last bar
- P  = (PriorDayHigh + PriorDayLow + PriorDayClose) / 3
- R1 = 2*P - PriorDayLow
- S1 = 2*P - PriorDayHigh
- R2 = P + (PriorDayHigh - PriorDayLow)
- S2 = P - (PriorDayHigh - PriorDayLow)

**Setup**:
- Track current bid relative to fixed daily levels
- BUY if `Bid <= S1 + ProximityPips` (price reached S1 from above)
- SELL if `Bid >= R1 - ProximityPips` (price reached R1 from below)
- Approach must be "clean" — price came from `MinDistanceFromLevel` away

**Entry**:
- Market entry on signal bar close
- Single position, never both directions
- Maximum one trade per pivot level per day (cooldown)

**Exit**:
- TP: central pivot P
- SL: S2 (for BUY) or R2 (for SELL) — second standard deviation
- Time stop: hard close at 22:00 CET (end of NY session)

**Indicators**: None — pivot calculation is custom

## v2: Multi-level (S1, S2, R1, R2)

Same as v1 but trade reactions at all four levels (S1, S2, R1, R2),
not just S1 and R1. Each level targets the next-inner pivot:
- S2 → S1
- S1 → P
- R1 → P
- R2 → R1

**Why this might work**: Adds more setup opportunities. S2/R2 reactions
are stronger (deeper reversals) but rarer. Overall trade frequency
increases ~2x.

**Why this might fail**: S2/R2 are reached only on highly directional
days. By that point, the trend is real and reversion fails. Adds
losing trades from regime mismatch.

## v3: WaveTrend confirmation

Same as v1 but require WT in matching exhaustion (`< -60` for BUY,
`> +60` for SELL) on entry bar.

**Why this might work**: Combines two validated mean-reversion principles
— level proximity and momentum exhaustion. Higher conviction.

**Why this might fail**: WT exhaustion is rare during European morning.
Filter may collapse signal frequency to near-zero. Pivot reactions
often happen from neutral WT state (the level itself is the trigger).

## v4: European session only (08:00-15:00 CET)

Same as v1 but restrict trading window to 08:00-15:00 CET (London
session before NY arrives).

**Why this might work**: Pivot reactions are strongest during European
hours when the LARGEST number of intraday traders is active. NY session
has different conventions (intraday VWAP, opening range).

**Why this might fail**: Removes the highest-volatility session (NY).
Sample size drops. May not have enough trades for statistical edge.

## v5: Distance filter

Same as v1 but require price to have approached the level from at least
`MinDistanceFromLevel` pips away within the last `LookbackBars` bars.

**Why this might work**: Pivot reactions only matter if price ACTUALLY
TRAVELS to the level. If price has been hovering near a pivot all day,
it's already absorbed; touching it isn't a fresh trigger.

**Why this might fail**: Adds a parameter that may overfit. The
"clean approach" is hard to define objectively in M1 noise.

## v6: Camarilla pivots

Same as v1 but use Camarilla formulas instead of standard pivots:
- H3 = C + (H - L) * 1.1/4
- L3 = C - (H - L) * 1.1/4
- H4 = C + (H - L) * 1.1/2
- L4 = C - (H - L) * 1.1/2
- (etc., for H5/L5)

Trade reversals at H3/L3 (first standard Camarilla level).

**Why this might work**: Camarilla pivots are tighter than standard
pivots and produce more frequent setups. The methodology is also
widely used by intraday scalpers.

**Why this might fail**: More frequent = lower quality. Tighter levels
may be inside daily noise and produce false signals. Less universally
watched than standard pivots.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: Different trigger (level vs
  oscillator). Should be largely uncorrelated except when both fire on
  same bar (rare).

- **vs Round Number Magnet (sister 0411_012800)**: Both use fixed price
  levels. Pivots are calculated daily, round numbers are universal. They
  may align occasionally — not a conflict, just confluence.

- **vs Liquidity Sweep Reversal (sister)**: Sweep is a structural pierce;
  pivot is a calculated level. Different signal sources but both are
  fade trades. Can coexist.

- **vs London Close Mean Reversion (sister 0411_012500)**: Different
  windows. Pivot strategy is morning/midday; LCMR is afternoon. Sequential
  by session.

- **vs hedge accumulators**: No conflict. Different magic.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `ProximityPips` | 2-15 | 2 | Distance from pivot to trigger |
| `MinDistanceFromLevel` | 10-30 | 5 | Clean-approach distance |
| `LookbackBars` (v5) | 20-100 | 20 | Bars for clean approach check |
| `WT_Threshold` (v3) | 50-70 | 5 | WT exhaustion confluence |
| `WindowStartHour` (v4) | 7-9 | 1 | European session start (CET) |
| `WindowEndHour` (v4) | 13-15 | 1 | European session end (CET) |
| `PivotType` | Standard / Camarilla | — | Calculation method |

## Notes

**Market condition targeted**: European morning/midday, ranging or
mean-reverting market. Performance should DEGRADE on strongly trending
days (pivots break instead of reject).

**Risk profile**: Mid win rate (target 55-65%), modest R:R (target
1.2-1.8:1). TP at central pivot is variable distance — usually 15-40
pips depending on prior day's range.

**Pivot calculation timing**:
- Calculate at 00:00 SERVER time (not GMT or local)
- Use bars from prior day (00:00-23:59 server time)
- Recalculate once per day, NEVER intraday
- Display on chart for visual verification during testing

**Edge cases**:
1. **Monday morning**: prior day = Friday. Weekend gap may make pivots
   stale. Consider using last 3 trading days average for Monday.
2. **Holiday Mondays**: prior day was a holiday with thin volume. Pivots
   based on bad data. Skip via calendar.
3. **Pivot inside current bar's range from open**: if today opens
   already at a pivot level, the "clean approach" filter prevents the
   trade. Correct behavior.
4. **Multiple pivots clustered**: when prior day was very narrow,
   S1/R1 are close together. Treat as a single zone.

**Failure modes to watch**:
- WR < 50% → pivots breaking instead of rejecting; trending regime
- Avg loss > avg win → SL at S2/R2 is too far, consider tighter
- All winners on small moves → TP at P is achievable, R:R is fine
- Total trades < 80/year → proximity filter too tight

**Open question**: Daily pivot vs Weekly pivot — does weekly pivot
produce stronger but rarer reactions? Could be a v7 variant.
