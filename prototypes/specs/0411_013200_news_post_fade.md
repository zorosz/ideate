# News Volatility Fade

## Thesis

After scheduled high-impact news (NFP, CPI, FOMC, ECB, central bank
rate decisions), the initial 1-15 minute spike is typically overshoot.
Algorithmic order routers, panic positioning, and stop cascades drive
price 2-5x further than the underlying information would justify. Then
within 30-90 minutes, market makers absorb the imbalance and price
retraces 50-70% of the initial move.

The trade is straightforward: WAIT for the news spike to complete (let
NewsFreezeGuard hold), then fade the move when volatility starts to
normalize. The challenge is timing — too early and you fade an
ongoing move; too late and the retracement is over. The window is
approximately 30-90 minutes after release.

This is the project's first event-driven strategy. All existing
strategies are time- or indicator-based. News-driven trading captures
a different alpha source: the quantifiable overshoot of algorithmic
reaction to scheduled information.

## Evidence

1. **NewsFreezeGuard exists in `Include/NewsFreezeGuard.mqh`**:
   infrastructure to detect news events is already built. We know
   exactly WHEN news happens. Building a fade trigger on top requires
   no new event detection.

2. **Impulse Fade (#4) FAILED**: ALL prototypes were negative on random
   M1 impulses. Optimized version showed PF 1.18 with 4×ATR + 60%
   retracement — barely profitable. The lesson: random impulses on M1
   are noise. **News-driven impulses are NOT random** — they have a
   known cause and a documented overshoot pattern. This strategy
   isolates the cases where Impulse Fade should have worked.

3. **WT crossover validated (#1, PF 1.09)**: post-news, WT eventually
   crosses as the move reverses. This strategy can use WT cross as the
   actual entry trigger after the news window opens.

4. **Engle and Patton 2001 — "What good is a volatility model?"**:
   foundational academic work documenting that scheduled news creates
   measurable overshoots followed by mean reversion to fair value
   within 30-120 minutes.

5. **Lyons 2001 — "The Microstructure Approach to Exchange Rates"**:
   FX-specific evidence that information arrives in spikes and is
   absorbed gradually by market makers. Algorithmic execution amplifies
   the initial move.

6. **Project context — 17:00-22:00 CEST is strongest session**: most
   high-impact USD news happens at 14:30-16:00 CET (NFP, CPI, retail
   sales). The post-news fade window aligns with the project's
   preferred trading hours.

## Base (v1)

**Timeframe**: M1

**News detection**:
- Use NewsFreezeGuard to track scheduled high-impact USD/EUR events
- Record event start time and event end time (when freeze ends)
- Mark "post-news window" = [eventEnd + `WaitMinutes`, eventEnd +
  `WindowMinutes`] (e.g. 30-90 min after freeze ends)

**Setup detection** (during post-news window only):
- Compute spike magnitude:
  - SpikeMove = (max(High) - min(Low)) within ±15 min of event time
  - SpikeDirection = sign(close at eventEnd - close 15 min before event)
- Spike must exceed `MinSpikePips` (default 30 pips)
- Setup:
  - SELL if SpikeDirection > 0 (fade the up-spike)
  - BUY if SpikeDirection < 0 (fade the down-spike)

**Confirmation**:
- Wait for first WT cross AGAINST spike direction during the window
- WT cross is the validated reversal trigger (#1)

**Entry**:
- Market entry on confirming WT cross bar
- Single position, never both directions

**Exit**:
- TP: 50% retracement of SpikeMove (the documented academic target)
- SL: full SpikeMove × `SL_Multiplier` (default 1.2) past entry
- Time stop: hard close at eventEnd + `WindowMinutes` (close of window)

**Indicators**: WaveTrend, NewsFreezeGuard

## v2: Time-window expansion (15-90 min)

Same as v1 but the post-news window starts at eventEnd + 15 min (not 30).
Earlier entries possible.

**Why this might work**: Some news moves complete their overshoot in
under 30 min. Earlier window catches the fastest reversals.

**Why this might fail**: 15 min is often still inside the move itself.
Volatility hasn't normalized. Entry quality suffers — buying into a
still-falling knife.

## v3: ATR-relative spike threshold

Same as v1 but `MinSpikePips` is replaced with `MinSpikeATR` (default
3.0): spike must exceed 3 × current ATR(14) on M5.

**Why this might work**: Adapts to volatility regime. In quiet weeks
(holiday seasons), 30 pips is huge; in volatile weeks, it's noise.
ATR-relative threshold is more honest.

**Why this might fail**: ATR is itself spiked by the news event. The
threshold becomes self-referential. May filter out the cleanest setups.

## v4: USD high-impact only

Same as v1 but only fade USD news events (NFP, CPI, FOMC, retail sales,
PPI, jobless claims). Skip EUR events.

**Why this might work**: USD news has the most algorithmic reaction
because USD is half of all FX pairs. Highest overshoot = cleanest fade.

**Why this might fail**: ECB and EUR-zone CPI also produce overshoots.
Filtering them out reduces sample size unnecessarily.

## v5: NewsFreezeGuard release as direct trigger

Same as v1 but use the moment NewsFreezeGuard releases (eventEnd +
freezeMinutes) as the trigger directly — no WT cross required, just
fade in opposite direction of spike.

**Why this might work**: NewsFreezeGuard knows when the freeze is over.
That moment is by definition "volatility normalized." Direct fade is
the simplest possible implementation.

**Why this might fail**: Without WT confirmation, you may enter at the
wrong moment. Some news spikes are NOT overshoots — they're real
information. Fading those loses money.

## v6: Multi-news weighting

Same as v1 but weight position size by news impact rating:
- High impact (NFP, FOMC, CPI): full lot
- Medium impact: half lot
- Low impact: skip

**Why this might work**: Higher-impact news has bigger overshoots →
bigger fades = larger position justified.

**Why this might fail**: NewsFreezeGuard impact ratings may be
inconsistent. Bigger position on rare events concentrates risk. Same
issue as v3 of WT MTF Score.

## Interaction with existing strategies

- **vs WT mean reversion baseline (#1)**: This strategy USES WT cross
  as its entry confirmation. Should not duplicate signals — the WT
  cross during the post-news window is hijacked by this strategy.
  Implementation: WT baseline must SKIP signals during active news
  windows to avoid double-entering.

- **vs all hedge accumulators**: Hedges are blocked by NewsFreezeGuard
  (no entries during freeze). Once freeze releases, hedges resume
  normal accumulation. This strategy is single-shot per event. No
  position conflict expected.

- **vs Liquidity Sweep Reversal (sister)**: Sweep can fire
  independently of news. During post-news windows, both may signal
  the same direction (news spike creates a swing extreme; the
  retracement looks like a sweep + close-back). Verify they don't
  double-enter.

- **vs NY Open Continuation (sister)**: NY open at 15:30 CET is often
  AFTER an NFP release at 14:30 CET. NY continuation says trade WITH
  the move; this says fade it. Direct conflict during NFP days.
  Resolve by separating their "valid days" — NY open skips news days
  (v4 of that spec) while news fade uses them.

## Optimize

| Parameter | Range | Step | Notes |
|-----------|-------|------|-------|
| `WaitMinutes` | 15-60 | 15 | Min after freeze before window opens |
| `WindowMinutes` | 60-180 | 30 | Total window duration |
| `MinSpikePips` | 20-60 | 10 | Min spike to qualify |
| `MinSpikeATR` (v3) | 2.0-4.0 | 0.5 | ATR-relative spike threshold |
| `SL_Multiplier` | 0.8-1.5 | 0.1 | SL relative to spike size |
| `RetracementTP` | 0.4-0.7 | 0.1 | TP as fraction of spike |

## Notes

**Market condition targeted**: Post-scheduled-news fade. Strategy fires
2-10 times per week (depending on news calendar density). Silent on
quiet news weeks.

**Risk profile**: Low-mid win rate (target 50-60%), modest R:R (target
1:1 to 1.5:1). Half-spike target with full-spike stop is roughly 1:2.4
risk-reward ratio in the WORST case. WR makes the difference.

**Critical: NewsFreezeGuard integration**:
- Must NOT trade during freeze (already enforced by guard)
- Must know exactly when freeze RELEASES — this is the start of the
  post-news window
- Must know spike size — record price min/max during freeze

**Edge cases**:
1. **Multi-news days**: when 2 events happen close together (e.g. NFP
   at 14:30 + Powell speech at 15:00), windows overlap. Use the FIRST
   event's window only.
2. **Surprise news (unscheduled)**: not in calendar, no freeze. This
   strategy doesn't fire. Acceptable.
3. **Weekend gap (Friday news)**: NFP is Friday. Window may extend
   into weekend close. Add hard cutoff at Friday 22:00 CET.
4. **Holiday news**: may have lower volume but same overshoot mechanism.
   Should work.

**Failure modes to watch**:
- WR < 40% → news spikes are not overshoots, they're real moves
- Avg loss > avg win × 1.5 → 50% retracement target not reached often
- Profitable in 2024 only → news regime varies by year (CPI was extreme
  in 2022, normalized after)
- Total trades < 30/year → window too tight or spike threshold too high

**Calendar dependency**: requires NewsFreezeGuard to have an up-to-date
news calendar. In backtests, the calendar must be a static file with
historical events. Verify calendar coverage matches backtest period
before trusting results.
