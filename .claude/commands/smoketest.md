---
description: "Run short backtest, analyze logs for errors, fix and retest"
---

# /smoketest — Quick integration test with log analysis

Run a 1-week backtest, read the journal, find errors, fix them,
repeat until clean.

## Usage

```
/smoketest hedge_dynamic_aggressive
/smoketest hedge_multi_pair
```

## Execution

### Step 1: Run short backtest

- Period: 1 week (2025.01.06 to 2025.01.13)
- Model: Every tick
- Visual: off
- Save journal log

### Step 2: Analyze journal for errors

Search for ALL of these patterns:

**Critical errors (must fix):**
- `failed modify` — TP/SL modification rejected by broker
- `failed buy` / `failed sell` — order placement rejected
- `Invalid stops` — TP or SL on wrong side
- `Invalid price` — pending order at invalid level
- `not enough money` — margin insufficient
- `EMERGENCY KILL` — kill switch triggered (why?)

**Logic errors (check context):**
- Duplicate positions at same price level
- TP == entry price (breakeven exit paying spread)
- Missing TP (position with TP = 0)
- Orphan pending orders (not at expected grid levels)
- Position count > MaxPositionsPerSide on either side

**Warnings (note but may be OK):**
- `spread too wide` — expected during rollover
- `skipping — in no-trade window` — expected behavior

### Step 3: Report findings

```
SMOKETEST: [EA name] — 2025.01.06 to 2025.01.13

Errors found: [N]
  1. [CRITICAL] failed modify #42 sell — Invalid stops (line 1847)
     Context: TP set to 1.03550 but entry is 1.03550
  2. [LOGIC] Duplicate BUY at 1.03600 — tickets #55, #58
     Context: grid oscillation UP-DOWN-UP
  3. [LOGIC] SELL #31 TP=1.03500 but SELL #35 TP=1.03550
     Context: accumulated SELLs have different TPs

Warnings: [N]
  - 12x "spread too wide" during 23:00-01:00
  - 3x "in no-trade window"

Stats:
  - Total trades: 847
  - Grid steps: 192
  - Emergency kills: 0
  - Max positions: 4 BUY + 1 SELL
```

### Step 4: Fix and retest

For each CRITICAL and LOGIC error:
1. Identify root cause in code
2. Fix
3. /compile
4. Rerun /smoketest

Repeat until:
```
SMOKETEST: CLEAN — 0 errors, 0 logic issues
```

Only then proceed to full backtest.

## What to check per EA type

### Grid harvest hedge (hedge_dynamic_aggressive)
- All accumulated positions have SAME TP
- Pending orders at exactly ±HarvestPips from grid
- Only 1 winning-side position per grid level
- No TP == entry price
- Grid steps logged correctly

### Accumulating hedge (hedge_multi_pair)
- Per-pair position isolation (magic numbers)
- Harvest fires only on profitable positions
- Batch close only when count >= threshold AND P&L > 0
- Lot increment correct per accumulated step
- Multi-pair: no cross-pair interference

### Zone-based hedge (new_dawn_hedge)
- 4 orders placed at zone boundaries
- Pending orders cancelled when position closes
- Recovery TP set on remaining position
- No SL ever (always 0)