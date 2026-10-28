---
description: "Generate strategy prototype ideas grounded in market logic"
---

# /ideate — Strategy idea generator

Generate testable strategy ideas and write them as specs to prototypes/specs/.
Each idea must be grounded in a market thesis, not random indicator combinations.

## Context you know

- We trade EURUSD on M1
- Existing edge: mean reversion with WaveTrend (oversold/overbought reversal)
- Available modules: SMC_Core.mqh (S/R zones, BOS/CHoCH), WaveTrend.mqh
- Shared prototype utils: ND_Proto.mqh (filters, trade functions)
- Problem to solve: idle time between mean reversion signals
- Trading session preference: 17:00-22:00 CEST is strongest
- Risk preference: conservative, no martingale, max 2 positions

## Depth levels

- "/ideate quick" — 1 sentence thesis, 2 versions, minimal notes.
  For rapid brainstorming. Skip the Optimize section.
- "/ideate" (default) — detailed thesis, 3-4 versions, notes on
  market conditions. Full spec format.
- "/ideate deep [topic]" — research-level. Use ultrathink. Before generating:
  1. Read docs/OBSERVATIONS.md, docs/IDEAS.md, and docs/DECISIONS.md for patterns
  2. Think about what market microstructure would create the edge
  3. Consider how the idea interacts with existing strategies
  4. Consider what prototype results have already taught us
  5+ versions exploring different angles. Include reasoning for
  why each version might or might not work. Cite specific evidence
  from prior testing where relevant.

## Rules for generating ideas

1. Every idea MUST have a market thesis — one sentence explaining WHY
   this should work based on market behavior

   Good: "During London close (16:00-17:00), institutional position
   unwinding creates predictable reversals at session high/low"

   Bad: "What if we use RSI + MACD + Stochastic together"

2. Prefer ideas that:
   - Fill gaps in the current strategy (different market conditions)
   - Use existing modules (SMC, WaveTrend) in new ways
   - Target specific time windows or market conditions
   - Have clear, simple entry/exit rules

3. Avoid:
   - Random indicator combinations without a thesis
   - Strategies that require many parameters (overfitting risk)
   - Anything resembling martingale or grid
   - Strategies that duplicate what the mean reversion already does

4. Each idea gets versions as specified by depth level

5. Include an "Optimize" section listing which parameters to test
   and their ranges (skip for "quick" depth)

## Output format

Write specs to prototypes/specs/ using the prototype spec format.
Filename: MMDD_HHMMSS_strategy_name.md (use current timestamp).

### Quick format
```markdown
# [strategy name]

## Thesis
[one sentence]

## v1
Entry buy: [condition]
Entry sell: [condition]
Exit: [TP/SL]

## v2: [variation]
[change from v1]
```

### Default format
```markdown
# [strategy name]

## Thesis
[why this should work based on market behavior]

## Base (v1)
Timeframe: M1
Entry buy: [condition]
Entry sell: [condition]
Exit: [TP/SL method and values]
Indicators: [what to use]

## v2: [variation]
[change from v1]

## v3: [variation]
[change from v1]

## Optimize
[parameters and ranges for Phase 2 optimization]

## Notes
[what market condition this targets]
```

### Deep format
```markdown
# [strategy name]

## Thesis
[detailed market microstructure reasoning]

## Evidence
[what prior testing/observations support this]

## Base (v1)
Timeframe: M1
Entry buy: [condition]
Entry sell: [condition]
Exit: [TP/SL method and values]
Indicators: [what to use]

## v2: [variation]
[change from v1]
Why this might work: [reasoning]
Why this might fail: [reasoning]

## v3-v5+: [variations]
[same structure with reasoning]

## Interaction with existing strategies
[how this complements or conflicts with current EA]

## Optimize
[parameters and ranges for Phase 2 optimization]

## Notes
[what market condition this targets, risks, edge cases]
```

## How many ideas

- "/ideate quick" → generate 3 ideas (3 spec files)
- "/ideate quick [number]" → generate that many
- "/ideate" → generate 3 ideas (3 spec files)
- "/ideate [number]" → generate that many
- "/ideate [topic]" → generate 3 ideas around that topic
- "/ideate deep [topic]" → generate 2 deep ideas around that topic

## After generating

List the ideas with their thesis, one line each.
Do NOT run /prototype — I decide which to test.
