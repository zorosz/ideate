# Prototype workflow: `/ideate` → `/prototype`

A fast way to test whether a trading idea has an edge before investing in a
full EA. Ideas are written as specs, built as throwaway `.mq5` files,
optimized, and checked on two out-of-sample years. Everything stays in this
folder; nothing here is production code.

This is one of two workflows in `Experts/claude/` (see `../CLAUDE.md`). The
other, full EA development (`specs/NN_name/` → `src/` → `results/`), is where
`/selftest` and `/smoketest` live. They are not part of this workflow.

## Loading the commands

The commands are project slash commands in `Experts/claude/.claude/commands/`.
Claude Code only loads `.claude/` from the folder a session starts in and its
parents, so **start the session in `Experts/claude/`**. A session started at
the `MQL5` root will not see `/ideate` or `/prototype`, and the relative paths
in them (`prototypes/specs/`, `docs/IDEAS.md`) only resolve from
`Experts/claude/`.

## The flow

```
/ideate [quick|deep] [N|topic]
   │  writes spec files to prototypes/specs/
   ▼
you pick which specs to test        ← /ideate never starts /prototype
   │  (delete or set aside the rest)
   ▼
/prototype
   │  Phase 1  build + default backtest      (2025)
   │  Phase 2  optimize every version        (2025)
   │  Phase 3  summary + sensitivity
   │  Phase 4  out-of-sample 1               (2024)
   │  Phase 5  out-of-sample 2               (2023, only if OOS1 passed)
   ▼
verdict logged to docs/IDEAS.md
   │
   ▼
next /ideate deep reads IDEAS.md, OBSERVATIONS.md, DECISIONS.md
```

The last arrow is the point of the loop: every result, good or bad, becomes
evidence for the next round of ideas.

## Step 1: `/ideate`

Generates strategy ideas and writes each one as a spec file.

| Call | Ideas | Versions per idea | Content |
|------|-------|-------------------|---------|
| `/ideate quick [N]` | 3 (or N) | 2 | One-sentence thesis, entry/exit rules. No Optimize section. |
| `/ideate [N]` or `/ideate [topic]` | 3 (or N) | 3-4 | Full thesis, versions, Optimize ranges, market-condition notes. |
| `/ideate deep [topic]` | 2 | 5+ | Reads `docs/OBSERVATIONS.md`, `docs/IDEAS.md`, `docs/DECISIONS.md` first. Adds an Evidence section, "why it might work / fail" per version, and how it interacts with existing strategies. |

Rules every idea must follow:

- **A market thesis**: one sentence on *why* price should behave this way.
  "London close unwinding causes reversals at session high/low" is a thesis.
  "RSI + MACD + Stochastic" is not.
- **Few parameters**, to limit overfitting.
- **No martingale or grid**, and no duplicate of an existing strategy.
- Prefer ideas that cover conditions the current strategy misses, reuse
  existing modules, or target a specific time window.

Output: `prototypes/specs/MMDD_HHMMSS_strategy_name.md`. When done, `/ideate`
lists each idea's thesis in one line and stops.

### Spec format

```markdown
# [strategy name]

## Thesis
[why this should work]

## Base (v1)
Timeframe: M1
Entry buy: [condition]
Entry sell: [condition]
Exit: [TP/SL]
Indicators: [what to use]

## v2: [variation]
[change from v1]

## Optimize
[parameters and ranges for Phase 2]

## Notes
[market condition this targets]
```

Every version is a change from **v1**, not from the version before it. That
keeps each variation's effect measurable on its own.

## Step 2: choose

You decide which specs go to `/prototype`. It processes every unprocessed spec
in `specs/` in order, so remove or move any spec you don't want run.

## Step 3: `/prototype`

| Phase | Period | What happens | Output in `results/` |
|-------|--------|--------------|----------------------|
| 1. Build + default | 2025.01.01-2026.01.01 | Each version becomes `src/[spec]_vN.mq5`, compiled, backtested with default inputs | `[spec]_vN_default.md` |
| 2. Optimize | same | Genetic optimizer (`Optimization=2`) on every version, using the spec's Optimize ranges | `[spec]_vN_optimized.md` |
| 3. Summary | — | Default vs optimized table for all versions; best version picked by EV | `[spec]_summary.md` |
| 4. OOS1 | 2024.01.01-2025.01.01 | Best version on data not used in Phases 1-2 | `[spec]_validated_oos1.md` |
| 5. OOS2 | 2023.01.01-2024.01.01 | Only if OOS1 is VALIDATED or WEAK; skipped if 2023 M1 data is missing | `[spec]_validated_oos2.md` |

### Sensitivity (Phase 3)

How much optimization improved EV over defaults:

| Rating | EV gain | Meaning |
|--------|---------|---------|
| Robust | < 50% | Defaults are fine |
| Sensitive | 50-200% | Needs specific parameters |
| Fragile | > 200% | Probably curve-fitted |

A Fragile result often shows up as a large drop in trade count: the optimizer
has found a small pocket of lucky trades. In `wt_crossover`, the optimized
versions went from 400-900 trades to 25-34.

### Verdicts

| Verdict | Rule |
|---------|------|
| VALIDATED | OOS1 EV positive |
| WEAK | OOS1 EV positive, but PF < 1.05 or Sharpe < 0.5 |
| FAILED | OOS1 EV negative (Phase 5 not run) |
| STRONG | Positive in OOS1 and OOS2: edge holds across 3 years |
| CONDITIONAL | OOS1 positive, OOS2 negative: works in the recent market only |

The final verdict and its key insights are appended to `docs/IDEAS.md`.
Anything unexpected found along the way (module bugs, odd behavior, market
insights) goes to `docs/OBSERVATIONS.md` at once.

## Folder layout

```
prototypes/
├── specs/     MMDD_HHMMSS_name.md               one file per idea
├── src/       MMDD_HHMMSS_name_vN.mq5/.ex5      one EA per version
│              *.ini                             backtest / optimization configs
└── results/   MMDD_HHMMSS_name_vN_default.md
               MMDD_HHMMSS_name_vN_optimized.md
               MMDD_HHMMSS_name_summary.md
               MMDD_HHMMSS_name_validated*.md
```

The timestamp prefix ties a spec to its source files and results.

## Shared library: `Include/ND_Proto.mqh`

Every prototype includes it instead of re-implementing filters and order code:

| Function | Purpose |
|----------|---------|
| `Proto_Init(magic)` | Set up the trade object |
| `Proto_CanTrade(symbol)` | Spread check plus no-trade window |
| `Proto_IsNewBar(symbol, tf)` | Run logic once per bar |
| `Proto_CountPositions(magic, symbol)` | Open positions for this prototype |
| `Proto_Buy` / `Proto_Sell(symbol, slPips, tpPips, magic, comment)` | Market order with SL/TP in pips |
| `Proto_CloseAll(magic, symbol)` | Close this prototype's positions |

Shared inputs: `Proto_MaxSpreadPips` (3.0), `Proto_NoTradeStart` /
`Proto_NoTradeEnd` (23:59-01:01 broker time), `Proto_LotSize` (0.01 fixed),
`Proto_Slippage` (10 points). `SMC_Core.mqh` and `WaveTrend.mqh` can be
included as needed.

## After a good verdict

There is no formal promotion step. So far, a STRONG or ROBUST prototype was
copied out to a named EA in `Experts/claude/` and hardened there. For example,
`hedge_multi_pair.mq5` and `hedge_dynamic_aggressive.mq5` were promoted this
way in commit `6c2f1ab`. New production work now goes through the full EA
workflow (`specs/NN_name/`), with `/selftest` and `/smoketest` on every spec.

## Track record

The first 16 ideas (April 2026, all EURUSD M1), from `docs/IDEAS.md`:

| Outcome | Count | Ideas |
|---------|-------|-------|
| STRONG | 2 | Combined hedge, dynamic lot sizing |
| ROBUST / all pairs profitable | 2 | Multi-pair single EA, multi-pair deployment |
| CONDITIONAL | 2 | Accumulating hedge pure distance, trend protection variations |
| WEAK | 4 | WT crossover, OB rejection scalp, SMC trend filter, per-position harvest |
| No improvement | 1 | Session filter + trailing batch close |
| FAILED | 5 | Asian range breakout, impulse fade, WT divergence, liquidity sweep reversal, WT + CHoCH |

A recurring lesson: M1 signals based on impulses, divergence or breakouts
were mostly noise. Several failures note the thesis might hold on H1 or higher.

## Caveats before reusing it

- **The context in `/ideate` is out of date.** It assumes EURUSD M1, a
  WaveTrend mean-reversion core, "idle time between mean reversion signals"
  as the problem to solve, and a 17:00-22:00 CEST session preference. Update
  the "Context you know" section in `.claude/commands/ideate.md` before
  generating ideas for anything else (for example, XAUUSD breakout work).
- **The test periods are fixed** at 2025 in-sample, 2024 OOS1 and 2023 OOS2,
  and the symbol is hard-coded to EURUSD in `/prototype`. Change both for
  another instrument or a later data window.
- **Prototype backtests use `Model=1` (1-minute OHLC), not every tick.** This
  is on purpose, for speed (see `docs/OBSERVATIONS.md`, 2026-10-27). Results
  that depend on intrabar fills, such as trailing stops or tight TP/SL, can
  look better than they would under every tick or real ticks. Recheck with
  `Model=0` or `Model=4` before trusting them.
- **The verdict thresholds are loose.** One positive out-of-sample year
  counts as VALIDATED. Treat VALIDATED and WEAK as "worth a closer look",
  not as a go-live signal.
