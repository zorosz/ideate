# Summary: all_time_hedge v2 (signal-based reset)

| Version | Params | Trades | PF | Net | Equity DD | Avg W | Avg L |
|---------|--------|--------|------|------|-----------|-------|-------|
| v1 | WT 53, 30 pip | 499 | 0.96 | -$47 | 0.48% | $4.32 | $6.04 |
| v2 | WT 30, 30 pip | 840 | 0.96 | -$72 | 0.72% | $3.58 | $4.59 |
| v3 | No WT, profit | 50 | 0.91 | -$15 | 0.16% | $3.34 | $41.76 |
| v4 | WT 53, 15 pip | 1017 | 0.95 | -$85 | 0.85% | $2.54 | $4.20 |
| v5 | WT 60, 30 pip | 251 | 0.97 | -$29 | 0.30% | $5.70 | $7.62 |

## Analysis

Signal-based reset (v2 spec) vs profit-based (v1 spec):
- v2 signal approach: PF 0.96-0.97, many trades, small losses — spread eats the edge
- v1 profit approach: PF 0.91-0.92, few trades, massive end-of-test losses

The signal approach is structurally better — no catastrophic single losses. The
losing leg gets reset at a loss occasionally, preventing the massive accumulation.
But spread + swap costs still eat the edge.

**v5 (strongest WT 60) is best**: PF 0.97, fewest trades (251), best avg win ($5.70).
The stronger the reversal signal, the better the timing. But even the best timing
can't overcome transaction costs on M1 with $0.30 spread per round-trip.

**v3 (no WT) is worst WT-using version**: confirms WT signal adds value — without it,
the strategy reverts to the profit-harvesting approach from spec v1.

## Key insight

The continuous hedge thesis produces PF 0.95-0.97 consistently. The ~3-5% shortfall
is almost exactly the spread cost on 250-1000 round-trips at $0.30 each. On a
zero-spread account this might be breakeven or slightly positive.

## Verdict

**FAILED** — all versions negative. Spread costs dominate.
Not proceeding to optimization (the edge gap is structural, not parameter-dependent).
