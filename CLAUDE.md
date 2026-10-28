# New Dawn — MQL5 Development Project

## Paths

```
MT5_TERMINAL = C:\Program Files\MetaTrader 5\terminal64.exe
MT5_EDITOR   = C:\Program Files\MetaTrader 5\metaeditor64.exe
DATA_DIR     = C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075
INCLUDE_DIR  = %DATA_DIR%\MQL5
REPORTS_DIR  = %DATA_DIR%\MQL5\Files\reports
```

IMPORTANT: Always use backslashes in MT5 /config: paths. Forward slashes break silently.

## Project Structure

```
claude/
├── specs/                          ← strategy specifications
│   ├── 01_grid_hedge/
│   │   ├── 00_workflow.md
│   │   ├── 01_grid_math.md
│   │   ├── ...
│   │   └── variants/
│   │       └── 08_dynamic_exit.md
│   └── 02_next_ea/
│       └── ...
├── src/                            ← versioned EA source files
│   ├── 01_grid_hedge_v1.mq5
│   ├── 01_grid_hedge_v2.mq5
│   └── ...
├── results/                        ← test results, decisions, observations
│   ├── 01_grid_hedge.md
│   └── ...
├── logs/                           ← compiler and tester logs
│   ├── compile_*.log
│   └── tester_*.log
├── prototypes/                     ← rapid prototype testing (separate flow)
│   ├── specs/
│   ├── src/
│   └── results/
├── scripts/                        ← backtest .ini files
├── include/                        ← shared modules
│   ├── SMC_Core.mqh
│   ├── WaveTrend.mqh
│   ├── ND_Proto.mqh
│   └── NewsFreezeGuard.mqh
└── .claude/commands/               ← CC slash commands
    ├── prototype.md
    ├── ideate.md
    ├── profitmax.md
    ├── selftest.md
    ├── smoketest.md
    ├── compile.md
    ├── backtest.md
    ├── review.md
    └── commit.md
```

## Compile

```powershell
& "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"C:\...\claude\src\01_grid_hedge_v1.mq5" /log:"C:\...\claude\logs\compile_grid_hedge.log" /inc:"C:\...\MQL5"
```

Log goes to claude/logs/. Check for "0 error(s)".

## Backtest

```powershell
& "C:\Program Files\MetaTrader 5\terminal64.exe" "/config:C:\...\claude\scripts\backtest.ini"
```

Terminal starts, runs test, saves report, shuts down (ShutdownTerminal=1).

## Smoketest parameters (pinned — do not deviate)

```
Symbol    : EURUSD
Timeframe : M1
Model     : Every tick (Model=1)
Period    : 2025.01.06 → 2025.01.13
Deposit   : 10000 USD
Leverage  : 1:30
```

Reproducibility across versions depends on these staying constant.

## Development Workflows

Two workflows: **prototypes** (rapid testing) and **full EA development**.

### Prototypes (claude/prototypes/)

Quick throwaway tests. Use /ideate to generate specs, /prototype to test.
Files stay in prototypes/. See .claude/commands/prototype.md for details.

### Full EA Development (specs/ → src/ → results/)

For production-quality EAs. Each EA gets:
- A numbered folder in specs/ with markdown spec files
- Versioned .mq5 files in src/
- A results file in results/

#### Creating a new EA

1. Create specs folder: `claude/specs/NN_ea_name/`
2. Write spec files: `00_workflow.md`, `01_first_spec.md`, ...
3. Create results file: `claude/results/NN_ea_name.md`
4. Each spec produces a new version: `claude/src/NN_ea_name_vN.mq5`

#### Per-spec implementation flow

```
1. Copy previous version to new filename (or create for v1)
2. Read the spec completely
3. Implement function by function, /compile after each
4. /selftest — CUMULATIVE: this spec's tests + all previous specs' tests must pass
5. /smoketest — 1 week backtest, analyze logs, fix errors
6. CC self-reviews the code (direction, stale tickets, TP/SL sides, dupes)
7. Log to results/NN_ea_name.md (smoketest, decisions, observations)
8. /commit with spec name and version; message footer reports PF / DD% / trades from smoketest
9. STOP — wait for user code review before next spec
```

#### Variant specs

Variants go in `specs/NN_ea_name/variants/`.
They reference base specs and only describe differences.
Toggled by input parameters. Implemented AFTER all base specs.

## Working Style

- Maximum effort on every task — effort level: MAX always
- One function at a time, /compile after each
- After each function: explain in 2-3 sentences what it does
- If a task needs more than 3 new functions: stop, list them, ask which to start
- NEVER rewrite an entire file — modify function by function
- Never skip /selftest or /smoketest
- Every bug fix gets a corresponding unit test
- Never overwrite src/ files — create new version
- /commit after every successful compile that doesn't break behavior
- When testing changes: record baseline before, make change, compare

## Results Logging

ALL of these go into results/NN_ea_name.md:
- Smoketest summaries
- Optimization results
- Profitmax runs
- Decisions with reasoning
- Observations and bug discoveries
- Version history with PF/DD metrics
- Validated parameter configs

## MQL5 Coding Rules

- `input` variables: always with explicit default value and comment
- Magic number: must be unique per EA instance
- Error handling: check `GetLastError()` after every trade operation
- Logging: use `Print()` and `PrintFormat()` for debug messages
- Position management: always check `PositionSelect()` result before modifying
- Do not use `Sleep()` in `OnTick()`
- `#property strict` at the top of every file
- All prices through `NormalizeDouble(price, _Digits)`
- Unit conventions (STRICT — reads the input parameter suffix):
  - **"Points"** suffix (e.g. `HarvestPoints`, `TPOffsetPoints`,
    `ZoneHedgeOffsetPoints`, `DynExitPushPoints`) → multiply directly by `_Point`.
    Preferred for every distance / interval input — point-level granularity
    lets the optimizer walk 48 / 50 / 53 pts instead of whole pips.
  - **"Pips"** suffix: legacy only; `value * pipSize` where
    `pipSize = (_Digits == 3 || _Digits == 5) ? _Point * 10.0 : _Point`.
    Use only if a spec explicitly requires pip granularity.
- Lot sizing: `NormalizeLots()` clamp to broker `VOLUME_MIN/MAX/STEP`
- Margin check: `OrderCalcMargin()` before every order

## Common Mistakes to Avoid

1. Unchecked `OrderSend()` return value
2. Missing `NormalizeDouble()` in price calculations
3. Forward slashes in MT5 /config: paths (use backslashes)
4. Stop loss/take profit too close (check `SYMBOL_TRADE_STOPS_LEVEL`)
5. Missing lot size validation
6. Stale ticket variables — always verify with `OrderSelect()` before use
7. `PositionModify(ticket, sl, tp)` — don't swap SL and TP parameters
8. Log files: always write to claude/logs/, not project root

## Observations

When you notice something during development or testing (bug,
unexpected market behavior, performance insight), log it to the
EA's results file: results/NN_ea_name.md under Observations section.
Don't ask — just log it.