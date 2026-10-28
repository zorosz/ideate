# Round Number Magnet & Reject

## Thesis

EURUSD reacts at round numbers — primarily .0000 and .5000 levels, with
secondary reactions at .2000 and .8000. This is one of the most
empirically documented patterns in FX microstructure: clustered limit
orders, options strikes (which are quoted at round numbers by convention),
retail target levels, and bank order books all converge at these levels.
The cumulative effect is a real liquidity wall that absorbs price on
first touch.

The trade is mechanical: when price reaches an untested round number from
significant distance, place a fade order in the opposite direction with a
tight stop just past the level. The edge depends on the level being
"untested" recently — once liquidity has been consumed, the level loses
its absorbing power.

This is fundamentally different from the validated WT mean-reversion edge:
WT measures momentum exhaustion, this measures structural liquidity. The
levels are objective and known in advance, requiring no parameter
optimization to identify.

## Evidence

1. **Osler (2003) — "Currency Orders and Exchange Rate Dynamics"**:
   academic paper documenting clustering of stop and take-profit orders
   at round numbers in FX. Foundational evidence that the pattern is
   real, not folklore.

2. **Order Block Rejection Scalp validated profile (#3)**: 23% WR /
   3.7:1 RR. The OBR thesis was that fresh structural levels reject
   price. Round numbers are universal "structural levels" without
   subjective swing detection. Same trade family, more objective trigger.

3. **DECISION 2026-04-03 — Mean reversion at clear levels works**:
   BB+RSI is mean reversion at a calculated level (BB band). This
   strategy is mean reversion at a fixed level (round number). Same
   logic, different level type.

4. **WT crossover validated (#1, PF 1.09)**: oscillator-based mean
   reversion edge confirms EURUSD M1 supports reversion trades. This
   strategy adds level-based reversion as a complementary trigger.

5. **Project context — idle time problem**: round numbers occur every
   10 pips on a 5-digit broker (.X0000, .X1000, .X2000, ...). Major
   round numbers (.X0000) occur every 100 pips. EURUSD trades through
   1-3 major round numbers per day on average. This is an under-served
   trigger source.

6. **Key Learning #2 — Fresh SMC zones matter**: zones < 50 bars old
   reject better. Apply same principle: untested round numbers (no
   touch in last `MaxRetestAge` bars) reject better than recently-tested
   ones.

## Base (v1)

**Timeframe**: M1

**Round number identification** (every M1 bar):
- Compute current bid in 5-decimal format
- For 4-decimal pairs (EURUSD), round numbers are at:
  - Major: every .X0000 (e.g. 1.0800, 1.0900) — 100 pip spacing
  - Minor: every .X5000 (e.g. 1.0850) — 50 pip spacing
- Active levels = nearest major and minor above and below current bid

**Setup**:
- Current bid approaches a round number from at least `MinDistanceFromLevel`
  pips away (clean approach)
- The level has NOT been touched in the last `MaxRetestAge` bars
- High of current bar reaches level (`Bid >= level - 1*point`):
  - SELL signal
- Low of current bar reaches level (`Bid <= level + 1*point`):
  - BUY signal

**Entry**:
- Market entry at signal bar close (after the touch)
- Single position, never both directions

**Exit**:
- TP: opposite direction by `TPPips` (e.g. 8 pips)
- SL: beyond round number by `StopBufferPips` (e.g. 3 pips)
- Time stop: hard close after `MaxBarsInTrade` bars

**Indicators**: None — pure price levels

## v2: Major round numbers only

Same as v1 but only trade at .X0000 levels (100-pip spacing). Skip .X5000
and other minor levels.

**Why this might work**: Major levels have the strongest order
clustering. Options strikes and bank books are heavily weighted at
.0000. Higher conviction per signal.

**Why this might fail**: Reduces signal frequency by ~5x. May not
generate enough trades for statistical significance. With 1-2 major
levels touched per day, you get ~250-500 setups per year max.

## v3: Wick rejection requirement

Same as v1 but also require the touch bar to have a wick > 60% of the
bar's total range, with the body closing back away from the level.

**Why this might work**: Wick rejection is a price-action confirmation
that liquidity ABSORBED the move. Without wick rejection, the level may
break next bar — there is no evidence of absorption yet.

**Why this might fail**: Adds latency (must wait for bar close) and
collapses signal count. M1 wicks are noisy and may not reflect real
absorption.

## v4: Confluence with SMC zone

Same as v1 but additionally require an SMC order block within `ZonePips`
of the round number. Round number + zone = double level.

**Why this might work**: Confluence of two structural levels is the
gold standard for entry quality. The level becomes both psychological
(round) and structural (SMC).

**Why this might fail**: SMC order block detection on M1 is noisy. The
confluence may be coincidence rather than real institutional level.
Also restricts trade frequency dramatically.

## v5: WaveTrend exhaustion confluence

Same as v1 but require WT in matching exhaustion zone on touch bar:
- SELL: `WT > +60`
- BUY: `WT < -60`

**Why this might work**: Combines structural reason (round number) with
momentum exhaustion (WT). Validated edge × validated edge.

**Why this might fail**: WT exhaustion is not always present at round
number reactions. The reaction can come from a neutral WT state because
the trigger is structural, not momentum-based.

## v6: Asian session round numbers

Same as v1 but only trade between 00:30 and 07:00 CET.

**Why this might work**: Asian session has the cleanest round-number
reactions because there's no directional flow forcing breaks. Perfect
liquidity-absorption regime.

**Why this might fail**: Round numbers may not be touched at all in
Asian session due to tight ranges (15-40 pips). Setup frequency may
collapse to near-zero.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: WT triggers on momentum
  exhaustion; this triggers on level proximity. Should be uncorrelated
  most of the time. v5 explicitly combines them.

- **vs Liquidity Sweep Reversal (sister)**: Sweep targets swing extremes
  with a pierce + close-back. This targets round numbers with a touch.
  Round numbers may BE swing extremes during strong moves — overlap
  expected but not 1:1.

- **vs Order Block Rejection Scalp (#3)**: OBR uses SMC zones; this uses
  fixed levels. v4 explicitly merges them.

- **vs Asian Range Scalp (sister 0411_012600)**: Both target Asian session
  in v6. Range scalp uses range edges; round number uses fixed levels.
  May conflict if a round number is at the range edge.

- **vs hedge accumulators**: No conflict. Different magic.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `MinDistanceFromLevel` | 10-50 | 5 | Pips from level for "clean approach" |
| `MaxRetestAge` | 30-200 | 30 | Bars since last touch (freshness) |
| `TPPips` | 5-15 | 2 | Take profit distance |
| `StopBufferPips` | 2-8 | 1 | SL beyond round number |
| `MaxBarsInTrade` | 15-60 | 15 | Time stop |
| `LevelSpacingMode` | Major / Minor / Both | — | Which levels to trade |
| `WT_Threshold` (v5) | 50-70 | 5 | Exhaustion confluence threshold |
| `ZonePips` (v4) | 5-15 | 2 | SMC confluence distance |

## Notes

**Market condition targeted**: All sessions, but especially calm Asian
hours where round numbers are clean liquidity absorbers. Strategy is
event-driven (touches), not session-driven, so frequency varies with
market movement.

**Risk profile**: Mid win rate (target 50-60%), modest R:R (target
1:1 to 1.5:1). Round number reactions are usually small (2-10 pips)
because the level absorbs the move quickly.

**Critical: avoid retest-of-recent-touch**:
- Once a round number has been touched, the liquidity is consumed
- A second touch within `MaxRetestAge` is not a fresh setup
- Track touched levels and skip them until they age out

**Edge cases**:
1. **Trending day**: round numbers BREAK in trending sessions, not
   reject. The strategy bleeds. Consider an ADX or session filter to
   avoid trends.
2. **News at round number**: NewsFreezeGuard handles macro news, but
   intraday data can spike through levels. Don't override the freeze.
3. **Spread spike**: at rollover, spread can be 10+ pips on EURUSD.
   Skip Asian session start (handled by v6 window).
4. **Multiple levels close together**: 1.0800 and 1.0810 are both
   "levels" technically. Use a level-cooldown so only one fires per
   `MaxRetestAge` period.

**Failure modes to watch**:
- WR < 45% → levels are not absorbing, may be in trending regime
- Avg loss > avg win → stops too tight, breaking just past level
- Profitable in 2024 only → range-bound year benefit; check 2023
- Total trades > 800/year → trigger too loose, treating noise as touches

**Open question**: should the level definition include .X2000, .X8000
as "minor majors" (a.k.a. quarter levels)? Some FX literature treats
these as significant. Test with `LevelSpacingMode = Quarters` later.
