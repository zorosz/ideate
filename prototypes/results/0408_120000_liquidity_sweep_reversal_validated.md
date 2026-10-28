# Validated: liquidity_sweep_reversal — comprehensive OOS

## Phase 4: OOS1 2024.01.01 - 2025.01.01

### v3 optimized (best in-sample, PF 1.42)
| Metric | In-sample 2025 | OOS1 2024 |
|--------|----------------|-----------|
| Profit | +$7.97 | **-$8.75** |
| PF     | 1.42   | 0.58 |
| Sharpe | 23.86  | -5.00 |
| Trades | 71     | 60 |
| Win%   | n/a    | 38.33% |

### v1 default (most robust config)
| Metric | In-sample 2025 | OOS1 2024 |
|--------|----------------|-----------|
| Profit | +$2.43 | **-$11.64** |
| PF     | 1.06   | 0.66 |
| Sharpe | 3.68   | -5.00 |
| Trades | 149    | 109 |
| Win%   | 47.65% | 42.20% |

### v5 optimized (best non-session config)
| Metric | In-sample 2025 | OOS1 2024 |
|--------|----------------|-----------|
| Profit | +$5.84 | **-$13.15** |
| PF     | 1.14   | 0.65 |
| Sharpe | 8.30   | -5.00 |
| Trades | 147    | 108 |
| Win%   | n/a    | 40.74% |

## Verdict: FAILED across all configurations

ALL three best variants lost money in 2024 with PF 0.58-0.66. Win rates
dropped from ~47% (in-sample) to ~38-42% (OOS) — a structural shift, not
noise.

The 2025 in-sample positive results were within statistical noise. The
strategy has NO REAL EDGE on EURUSD M1 outside of the specific 2025
market regime.

## Phase 5: SKIPPED

Phase 4 produced FAILED verdict for all variants. Per spec, Phase 5
(2023 OOS2) is not run.

## Period comparison summary

| Period | v1 PF | v3 opt PF | v5 opt PF |
|--------|-------|-----------|-----------|
| 2025 (IS) | 1.06 | 1.42 | 1.14 |
| 2024 (OOS1) | 0.66 | 0.58 | 0.65 |

PF dropped 38-59% across all variants. This is regime collapse, not
random fluctuation.

## Why the strategy fails

1. **Sweep + close-back-in is not a reliable reversal pattern on M1**:
   the 2025 positive result came from market microstructure (specific
   spread/volatility regime) that doesn't persist.

2. **Win rate is the key metric**: dropped from 47% to ~40% across all
   variants. Both SL and TP distances are similar to noise scale, so
   small WR shifts swing PF dramatically.

3. **Session edge was 2025-specific**: v3 optimized's London window
   (11-18) was a 2025 phenomenon. In 2024, the same window doesn't
   produce edge.

4. **OB confluence (v5) added no robustness**: it improved 2025
   in-sample but failed OOS just like v1.

5. **Spec's predicted profile didn't materialize**: predicted 30-40%
   WR with 2.5-4:1 RR (Order Block-style profile). Actual: 40-47% WR
   with 1.2-1.4 R:R. The strategy isn't catching what it was designed
   for.

## Final verdict

**FAILED** — no edge on EURUSD M1.

The liquidity sweep reversal idea is theoretically sound but doesn't
implement on M1 with the SMC swing detection trigger. The pierce + close-
back-in mechanic is too noisy at this timeframe to distinguish institutional
stop hunts from random spread spikes. May be worth re-testing on M5 or H1
where structural events are more meaningful.
