# Liquidity Sweep Reversal

## Thesis

Recent swing highs and lows act as magnets for resting stop orders — protective
stops of trend traders, breakout buy-stops/sell-stops, and pending orders from
price-action traders. Institutions know this and routinely "sweep" these levels
to acquire liquidity before reversing the actual order flow. The signature is
unmistakable: a sharp pierce beyond the swing extreme, immediately followed by
a close back inside the prior range. The breakout traders who entered on the
pierce are now trapped, the resting stops have been cleared, and the path of
least resistance is the opposite direction.

This is fundamentally a **fade strategy with a specific structural trigger**,
NOT generic mean reversion. The edge is the trapped-trader liquidity event,
not statistical reversion to a moving average.

## Evidence

1. **Failed Asian Range Breakout (#2 in IDEAS.md)**: M1 breakouts of recent
   swing levels are dominated by noise and manipulation, not genuine momentum.
   Asian Range Breakout failed because the breakouts were FAKES — which is
   exactly the setup we want to FADE. The same data that killed breakout
   strategies validates the inverse.

2. **Order Block Rejection Scalp (#3)**: 23% win rate, 3.7:1 R:R, marginally
   profitable on EV. Confirms that price reactions at structural zones are
   real but rare — this profile (low WR, big RR) is exactly what a liquidity
   sweep should produce. We're targeting the same statistical shape.

3. **Fresh SMC zones matter (Key Learning #4 in IDEAS.md)**: A sweep CREATES
   the freshest possible structural reference — the swing extreme that just
   got pierced is now the most relevant level on the chart. The pierce bar
   itself is also a tight, objective stop reference.

4. **17:00-22:00 CEST stop hunts (project context)**: London-NY overlap is
   when institutional liquidity provision is most active and stop hunts are
   most common. Aligns with the project's strongest session preference.

5. **WT crossover validated (#1)**: PF 1.09 with M10 confirmation — proves
   there is a tradeable mean-reversion edge on EURUSD M1, but it's a TIMING
   strategy. Liquidity sweep is a STRUCTURAL strategy with a different
   signal source, so should fill idle time without correlation to WT
   signals — directly addressing the "idle time between mean reversion
   signals" problem stated in project context.

6. **DECISION 2026-04-05: Zone age filter validated for entries**: Recent
   zones work, stale zones don't. A liquidity sweep targets the freshest
   possible swing — by definition, the level is "now" not "yesterday".

## Base (v1)

**Timeframe**: M1

**Setup detection** (every new M1 bar):
- Use `SMC_DetectSwing(bars=20)` to find the most recent swing high (SH) and
  most recent swing low (SL)
- Both must be within `MaxSwingAge` bars
- A sweep occurs when:
  - HIGH of current bar > SH (pierces above swing high), OR
  - LOW of current bar < SL (pierces below swing low)
- Pierce magnitude must exceed minimum:
  `pierce_pips >= MinPierceMultiplier * current_spread_pips`

**Confirmation** (close-back-inside on next bar):
- After the pierce bar, the immediately following bar must close back inside
  the prior range:
  - For sweep above SH: next bar close < SH
  - For sweep below SL: next bar close > SL

**Entry**:
- Sweep above SH → SELL at market on close of confirmation bar
- Sweep below SL → BUY at market on close of confirmation bar

**Exit**:
- SL: pierce extreme + `StopBufferPips`
  - For SELL: highest high of pierce bar + buffer
  - For BUY: lowest low of pierce bar + buffer
- TP: opposite swing extreme
  - For SELL after SH sweep: target SL (the swing low)
  - For BUY after SL sweep: target SH (the swing high)
- Time stop: close after `MaxBarsInTrade` bars regardless of P&L

**Indicators**: SMC_Core (swings only), ND_Proto for utility functions

## v2: WaveTrend exhaustion confirmation

Same as v1 but require WaveTrend to be at exhaustion in the sweep direction
on the pierce bar:
- Sweep above SH → require `WT > +WT_Threshold` (overbought) on pierce bar
- Sweep below SL → require `WT < -WT_Threshold` (oversold) on pierce bar

**Why this might work**: Combines structural trigger with momentum exhaustion.
Adds conviction at the cost of some signals. Brings WT's validated edge into
a structural context.

**Why this might fail**: Filters out the BEST sweep setups (silent reversals
when WT is mid-range). Stop hunts are surgical events that often happen
without prior momentum buildup. WT exhaustion may be redundant with the
sweep itself — both indicate "extreme reached".

## v3: Session filter (17:00-22:00 CEST only)

Same as v1 but only enter during 17:00-22:00 CEST.

**Why this might work**: NY session liquidity overlap maximizes stop-hunt
behavior — institutional desks rebalance, retail orders cluster at round
numbers and prior-day H/L, and the volume to absorb them is highest. Aligns
with the project's strongest session.

**Why this might fail**: Reduces sample size dramatically. London open
(09:00-11:00 CEST) also produces clean liquidity sweeps that would be
filtered out. May leave an exploitable edge on the table.

## v4: Multi-bar close-back-in window

Same as v1 but allow the close-back-inside to happen within `ConfirmWindow`
bars (1-3) of the pierce, not just the immediately following bar.

**Why this might work**: Some sweeps take time to reverse. The pierce bar
may close above SH, but the next 1-3 bars are the actual confirmation. M1
is noisy enough that strict "next bar" might miss valid setups.

**Why this might fail**: Wider confirmation window dilutes the edge. The
clearest signal is when the reversal is immediate — a 3-bar lag means the
trapped traders have already exited or doubled down, removing the
liquidity asymmetry that creates the move.

## v5: Order Block confluence target

Same as v1 but require an SMC order block within `ZoneProximity` pips of the
opposite swing (i.e., the TP target). The TP becomes the order block edge,
not the raw swing level.

**Why this might work**: Confluence of liquidity sweep + zone target = high
probability move with a structurally meaningful exit. The order block is
where opposing flow lives, so the move should pause there naturally.

**Why this might fail**: Adds complexity and reduces signal frequency. SMC
order block detection on M1 is noisy enough that confluence may be
coincidence, not edge. Also moves the TP closer than the opposite swing,
reducing R:R.

## v6: Pierce-magnitude tier system

Same as v1 but with three tiers based on pierce size:
- Small sweep (pierce < 2 pips beyond swing): SKIP — likely noise
- Medium sweep (2-8 pips): standard entry
- Large sweep (> 8 pips): "violent sweep" — standard entry, log separately

Track each tier in entry comments to learn which produces cleanest edge in
post-test analysis.

**Why this might work**: Pierce magnitude correlates with the amount of
liquidity being grabbed. Bigger sweeps mean more trapped traders and a
stronger mechanical reversal force.

**Why this might fail**: Bigger pierces can also indicate genuine breakouts
(news, regime change, structural break). There is no a priori reason to
believe pierce size correlates linearly with reversal probability — could
be U-shaped or worse.

## Interaction with existing strategies

- **vs WT mean reversion baseline**: Different trigger family (structural
  vs oscillator). Should be UNCORRELATED in time — sweeps happen at swing
  extremes regardless of WT state. This means liquidity sweep can fire
  when WT is silent, **directly filling the idle gap explicitly named in
  the project context**.

- **vs failed Asian Range Breakout (#2)**: This IS the inverse trade. ARB
  fails because M1 breakouts are fakes. Liquidity sweep wins because M1
  breakouts are fakes. Same observation, opposite trade.

- **vs Order Block Rejection Scalp (#3)**: Adjacent strategy — both target
  rare, high-RR setups at structural zones. Liquidity sweep is more
  specific (requires the pierce + close-back) and should have a higher
  win rate at the cost of fewer signals.

- **vs hedge accumulators (multi-pair, dynamic lots, all_time_hedge)**:
  Hedge accumulators are price-grid strategies that don't care about
  structure. Liquidity sweep is selective and structural. No conflict —
  could run on the same chart with different magic numbers.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `SwingLookback` | 10-30 | 5 | SMC swing detection bars |
| `MaxSwingAge` | 10-50 | 10 | Recency filter on swing reference |
| `MinPierceMultiplier` | 1.0-3.0 | 0.5 | Pierce >= N * spread |
| `MaxBarsInTrade` | 10-60 | 10 | Time stop |
| `StopBufferPips` | 1-5 | 1 | Stop placement above/below pierce |
| `WT_Threshold` (v2) | 50-70 | 5 | WT exhaustion threshold |
| `ConfirmWindow` (v4) | 1-3 | 1 | Bars allowed for close-back-in |
| `ZoneProximity` (v5) | 5-20 | 5 | OB confluence pip distance |

## Notes

**Market condition targeted**: Range-bound and corrective M1 action,
especially during NY session. Performance should DEGRADE in strong trending
sessions where sweeps are continuations, not reversals. This degradation is
expected — accept it and rely on the time stop to limit damage.

**Risk profile**: Low win rate (target 30-40%), big R:R (target 2.5-4:1).
Mirrors Order Block Rejection Scalp profile. EV positive but psychologically
painful — many small losses, occasional clean wins.

**Edge cases**:
1. **Two sweeps in a row** (sweep then sweep again on the same side) — the
   second sweep usually fails because the first already cleared the
   liquidity. Skip if there was a sweep on the same side in the prior 5 bars.
2. **News-driven sweeps** — NewsFreezeGuard handles macro news, but
   micro-news (data revisions, intraday speeches) can cause violent moves.
   Consider widening the stop or skipping during high-impact windows.
3. **Range expansion** — sometimes a sweep IS the start of a new range. The
   time stop limits damage but does not eliminate the loss. Accept it as
   the cost of the strategy.
4. **Spread spike during NY open** — confirmation bar close may be measured
   against an artificially wide spread. Use mid-price for the close-back-in
   check, not bid/ask raw.

**Failure modes to watch**:
- WR < 25% → close-back-inside criterion isn't catching the right setups
- Avg loss > 1.5× stop distance → spreads/slippage eating the edge
- Profitable in 2025 only, fails in 2024/2023 → regime overfit
- All winning trades are very large pierces → only v6 large tier works,
  consider promoting that tier as the primary version

**Open questions for prototype phase**:
- Is the immediately-next-bar rule (v1) or the 1-3 bar window (v4) better?
- Does WT exhaustion (v2) help or hurt? Default is "hurt" — sweeps are
  structurally complete on their own.
- Should we measure the swing reference at every bar or only on swing
  point confirmation? (SMC's `SMC_DetectSwing` already handles this.)
