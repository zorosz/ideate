---
description: "Run EA self-tests and verify all pass"
---

# /selftest — Run EA unit tests

Run the EA in self-test mode, read the journal, report results.

## Usage

```
/selftest hedge_dynamic_aggressive
/selftest hedge_multi_pair
```

## Execution

1. Set RunSelfTest=true in the backtest .ini
2. Run a minimal backtest (1 day, any date — tests run in OnInit)
3. Read the journal log file
4. Parse test results:
   - Count PASS and FAIL lines
   - Extract failure details
5. Report results

## Expected journal output

```
=== SELF TEST: 12 PASSED, 0 FAILED ===
```

or

```
FAIL SnapToGrid round up: expected=1.03550 actual=1.03500
FAIL AccLot(2) > AccLot(1)
=== SELF TEST: 10 PASSED, 2 FAILED ===
!!! FIX FAILURES BEFORE RUNNING !!!
```

## After parsing results

### All tests pass
```
✓ Self-test PASSED: [N] tests, 0 failures
EA is ready for backtest/deployment.
```

### Any test fails
```
✗ Self-test FAILED: [N] passed, [M] failed

Failures:
  1. SnapToGrid round up: expected=1.03550 actual=1.03500
  2. AccLot(2) > AccLot(1)

Fix the failures before proceeding. Each FAIL line shows 
what was expected vs what happened.
```

Then: fix the code, /compile, /selftest again. Repeat until clean.

## Adding new tests

When fixing a bug, ALWAYS add a test that catches that bug:

```
// Bug: UpdateAccumulatedTP sets TP = entry on breakeven positions
// Test: verify breakeven positions are skipped
AssertTrue("Skip breakeven SELL", 
  MathAbs(1.03500 - 1.03500) < 2 * _Point, passed, failed);
```

This prevents regressions — if the bug comes back, the test catches it.

## Test categories to maintain

1. **Grid math**: SnapToGrid, grid level calculation, harvestDist
2. **Lot sizing**: CalcBaseLot, CalcAccLot, MaxLotSize cap, increment
3. **TP/SL logic**: entry vs exit comparison, breakeven skip, direction
4. **Pending placement**: level calculation, order type correctness
5. **State management**: position counting, grid step detection
6. **Guards**: no-trade window, spread check, emergency kill threshold

## .ini for self-test

```ini
[Tester]
Expert=[EA path]
Symbol=EURUSD
Period=M1
Model=1
FromDate=2025.01.02
ToDate=2025.01.03
Deposit=10000
Leverage=100
Visual=0
ShutdownTerminal=1

[TesterInputs]
RunSelfTest=true
```

Only 1 day needed — tests run in OnInit, no ticks processed.