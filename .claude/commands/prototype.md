---
description: "Rapid strategy prototype — multi-version, optimize all, validate"
---

# /prototype — Strategy prototype pipeline

Read specs from prototypes/specs/. Build, optimize all versions, validate best.

## Directory structure

```
prototypes/
├── specs/
│   └── 0405_143022_wt_crossover.md
├── src/
│   ├── 0405_143022_wt_crossover_v1.mq5
│   ├── 0405_143022_wt_crossover_v2.mq5
│   └── ...
└── results/
    ├── 0405_143022_wt_crossover_v1_default.md
    ├── 0405_143022_wt_crossover_v1_optimized.md
    ├── 0405_143022_wt_crossover_v2_default.md
    ├── 0405_143022_wt_crossover_v2_optimized.md
    ├── 0405_143022_wt_crossover_summary.md
    └── 0405_143022_wt_crossover_validated.md
```

## Shared library

All prototypes import ND_Proto.mqh from Include/.
Do NOT reimplement filters — call Proto_CanTrade(), Proto_Buy(), etc.

## Spec file format

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

## v3: [variation]
[change from v1]

## Optimize
[parameters and ranges for optimization]
```

Each version builds on v1, not on the previous version.

## Execution — four phases

### Phase 1: build and default test (2025.01-2026.01)

1. Read next unprocessed spec from prototypes/specs/
2. For each version:
   a. Create .mq5 in prototypes/src/ importing ND_Proto.mqh
   b. /compile — fix errors if any
   c. /backtest EURUSD, 2025.01.01-2026.01.01
   d. Write result to results/[name]_v[N]_default.md

### Phase 2: optimize ALL versions (2025.01-2026.01)

3. For each version:
   a. Generate optimization .ini with parameter ranges from spec
   b. Run MT5 optimizer (Optimization=2, genetic algorithm)
   c. This is CPU work — let it run, it costs no tokens
4. After all optimizations finish, read all optimization reports
5. Write results to results/[name]_v[N]_optimized.md for each

### Phase 3: comparison summary

6. Write summary table to results/[name]_summary.md showing:
   - All versions, default AND optimized side by side
   - Sensitivity per version (how much optimization improved it)
7. Identify best version (highest optimized EV)

### Phase 4: out-of-sample validation 1 (2024.01-2025.01)

8. Take best version (optimized or default, whichever performed better)
9. /backtest EURUSD, 2024.01.01-2025.01.01 (out-of-sample, NOT used in Phase 1-2)
10. Write result to results/[name]_validated_oos1.md
11. Verdict:
    - EV positive: "VALIDATED"
    - EV positive but weak metrics (PF < 1.05, Sharpe < 0.5): "WEAK"
    - EV negative: "FAILED"

### Phase 5: out-of-sample validation 2 (2023.01-2024.01)

Only run if Phase 4 result is VALIDATED or WEAK.

12. Before running: verify M1 data for 2023 is available in terminal.
    Run a quick check (e.g. Bars count for 2023). If data is missing,
    log "Phase 5 skipped: no M1 data for 2023" and skip.
13. /backtest EURUSD, 2023.01.01-2024.01.01
14. Write result to results/[name]_validated_oos2.md
15. Final verdict combining Phase 4 + Phase 5:
    - Both positive: "STRONG — edge confirmed across 3 years"
    - Phase 4 positive, Phase 5 negative: "CONDITIONAL — works in recent market only"
    - Phase 4 negative: already FAILED in Phase 4, Phase 5 not run

16. Log final verdict to docs/IDEAS.md

## Result formats

### Default/optimized result
```markdown
# Result: [name] — v[N] [default/optimized]
Date: YYYY-MM-DD HH:MM
Period: 2025.01-2026.01

## Parameters (if optimized)
| Parameter | Default | Optimized | Range |
|-----------|---------|-----------|-------|
| SL_Pips   | 15      | 22        | 10-50 |

## Metrics
- Total trades: X
- Win rate: X%
- Avg win / Avg loss: $X.XX / $X.XX
- R:R ratio: X:1
- EV per trade: $X.XX
- Profit factor: X.XX
- Max drawdown: X%
```

### Summary
```markdown
# Summary: [name]

| Version | Params    | Trades | Win% | EV    | PF   | MaxDD | Sensitivity |
|---------|-----------|--------|------|-------|------|-------|-------------|
| v1      | Default   | 245    | 38%  | +0.12 | 1.31 | 4.2%  |             |
| v1      | Optimized | 210    | 42%  | +0.18 | 1.45 | 3.8%  | Robust      |
| v2      | Default   | 89     | 52%  | +0.34 | 1.85 | 2.1%  |             |
| v2      | Optimized | 95     | 55%  | +0.41 | 2.02 | 1.9%  | Robust      |

Best: v2 optimized (EV = +$0.41)

Sensitivity guide:
- Robust: optimization improved EV < 50% → defaults are good
- Sensitive: optimization improved EV 50-200% → needs specific params
- Fragile: optimization improved EV > 200% → likely overfitting
```

### Validation (OOS1 and OOS2)
```markdown
# Validated: [name] — v[N]
## OOS1: 2024.01.01-2025.01.01
[metrics block]
Verdict: VALIDATED / WEAK / FAILED

## OOS2: 2023.01.01-2024.01.01 (if OOS1 passed)
[metrics block]
Verdict: VALIDATED / WEAK / FAILED / SKIPPED (no data)

## Period comparison
| Period | Trades | Win% | EV    | PF   |
|--------|--------|------|-------|------|
| In-sample 2025 | 210 | 42% | +0.18 | 1.45 |
| OOS1 2024      | 82  | 51% | +0.31 | 1.78 |
| OOS2 2023      | 75  | 48% | +0.22 | 1.55 |

## Final verdict
STRONG / VALIDATED / WEAK / CONDITIONAL / FAILED
```

## Observations

If you notice anything during build/test (module bugs, unexpected 
behavior, market insights), log to docs/OBSERVATIONS.md immediately.

## Batch mode

Process all unprocessed specs in order.

## MT5 launch commands

CRITICAL: Always use PowerShell with backslash paths for MT5 terminal. Bash forward slashes break /config: paths.

Backtest:
```bat
powershell -Command "Start-Process -FilePath 'C:\Program Files\MetaTrader 5\terminal64.exe' -ArgumentList '/config:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\claude\prototypes\src\INIFILE.ini' -Wait"
```

Compile:
```bat
powershell -Command "Start-Process -FilePath 'C:\Program Files\MetaTrader 5\metaeditor64.exe' -ArgumentList '/compile:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\claude\prototypes\src\SOURCEFILE.mq5','/log:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\claude\prototypes\src\compile.log','/inc:C:\Users\tesa2\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5' -Wait"
```

INI Expert= path must include .ex5 extension for prototypes in subfolders.

## Can reuse modules

SMC_Core.mqh, WaveTrend.mqh, ND_Proto.mqh — import as needed.