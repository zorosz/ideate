# Combined hedge — session filter + trailing batch close

## Thesis

Two independent improvements to the combined hedge:
1. Session filter: only harvest during active sessions when spread
   is tight and volatility provides oscillation
2. Trailing batch close: let profitable accumulated side run further
   instead of closing at first sign of profit

## Base

Validated combined hedge v5 parameters:
H=5, Cap=6, MinPos=4, LotInc=0.025, MaxLoss=4

## v1: London + NY session only

Add session filter to harvest logic:
```
input string SessionStart = "08:00";  // London open (broker time)
input string SessionEnd   = "21:00";  // NY close (broker time)

Harvest only runs between SessionStart and SessionEnd.
Batch close runs 24/7 (don't miss reversal opportunities).
Positions stay open outside session, just no new harvests.
```

Effect: avoids low-volatility Asian session where H=5 harvests
are mostly noise and pay spread for nothing.

## v2: Trailing batch close

Replace immediate batch close (P&L > 0 → close) with trailing:
```
input double TrailActivatePips = 5.0;  // Start trailing at this profit
input double TrailDistancePips = 3.0;  // Close when profit drops by this

When accumulated side total P&L > TrailActivatePips:
  Record peakPL = max P&L seen
  If currentPL < peakPL - TrailDistancePips:
    Batch close (reversal is fading)
  
Reset peakPL when batch close happens.
```

Effect: captures larger reversal moves instead of closing at +0.1 pip.

## v3: Session + trailing combined

Both v1 session filter and v2 trailing batch close together.

## v4: Extended session

SessionStart = "07:00", SessionEnd = "22:00" (wider window).
Catches early London and late NY.

## v5: Aggressive trailing

TrailActivatePips = 3.0, TrailDistancePips = 1.5.
Tighter trailing — captures smaller reversals more frequently.

## Optimize
| Parameter | Default | Range | Step |
|-----------|---------|-------|------|
| SessionStart hour | 8 | 6-10 | 1 |
| SessionEnd hour | 21 | 19-23 | 1 |
| TrailActivatePips | 5 | 2-15 | 1 |
| TrailDistancePips | 3 | 1-10 | 1 |

## Notes
- Session filter reduces trade count significantly — verify
  the remaining trades still produce enough profit
- Trailing batch close holds positions longer — verify DD doesn't
  increase because accumulated positions sit in loss longer
- v3 is the target: if session + trailing both add value
  independently, the combination should be best
- Compare all vs base (no session, immediate batch close)