# Validated: wt_choch_confirmation — FAILED in-sample

## Phase 4: SKIPPED — no viable in-sample variant

All tested in-sample variants are non-viable:

| Variant | In-sample 2025 |
|---------|----------------|
| v1 spec polarity | 0 trades |
| v1 inverted polarity | -$63.77, PF 0.56, 21% WR |
| v2 (M5 CHoCH) | -$1.06, PF 0.83, 27% WR |
| v6 (tight WT) | 0 trades |

There is no positive in-sample result to validate against OOS data.

## Phase 5: SKIPPED — Phase 4 not run

## Final verdict

**FAILED in-sample.**

The strategy concept ("WT cross + CHoCH structural confirmation") does
not work on EURUSD M1. CHoCH events are lagging confirmations that fire
DURING or AFTER the move they identify, while WT crosses fire at the
exhaustion point BEFORE the structural break is confirmed. The two
signal types are chronologically incompatible as a confirming pair.

## Why the spec was wrong

The spec assumed:
> SMC's CHoCH (Change of Character) is a structural shift that fires
> earlier and more frequently than BOS. Pairing WT exhaustion with CHoCH
> provides early confirmation of trend exhaustion.

In practice:
1. CHoCH fires AFTER price has already moved away from the swing extreme
2. WT cross happens AT the swing extreme, not after
3. By the time CHoCH confirms the reversal, the WT cross is stale
4. By the time WT crosses, the most recent CHoCH is in the OPPOSITE
   direction (confirming the move that's now exhausting)

Both polarities of the filter fail:
- "Same direction" → 0 signals (the alignment doesn't exist)
- "Opposite direction" → many signals but they're catching late-stage
  moves with poor follow-through (21-27% win rate)

## Insight for future strategies

SMC structural events (BOS/CHoCH) on M1 are NOT useful as confirming
filters for oscillator-based mean reversion strategies. The temporal
alignment problem is fundamental — they can't be fixed by parameter
tuning, timeframe changes, or polarity flips.

Possible alternative angles (NOT tested in this prototype):
1. Use CHoCH as a STANDALONE trigger (no WT filter)
2. Use CHoCH on H1+ as a regime indicator (not a tactical trigger)
3. Use CHoCH formation to ANTICIPATE WT cross direction, not confirm it
