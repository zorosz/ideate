# Order Block Rejection Scalp

## Thesis
When price returns to an untested SMC order block, resting institutional orders
cause a visible rejection — a wick into the zone followed by a close back outside.
These rejections are high-probability reversal points because they represent real
unfilled liquidity, not just a drawn line. The current EA uses SMC zones for TP
targets; this strategy uses them as ENTRY triggers. Fills time between WT signals
by catching zone reactions the mean reversion misses.

## Base (v1)
Timeframe: M1
Entry buy: Price wicks into a demand zone (type=+1) bottom and closes above
zone top. The wick must penetrate at least 50% into the zone.
Entry sell: Price wicks into a supply zone (type=-1) top and closes below
zone bottom. The wick must penetrate at least 50% into the zone.
Exit: SL = 2 pips beyond far side of zone. TP = next opposing zone (from
SMC_FindNearestZone), or 1.5x SL distance if no zone found.
Indicators: SMC_Core.mqh (already built). No new indicators.
Filter: Zone must be "fresh" (not previously tested — first touch only).

## v2: WaveTrend exhaustion confirmation
Same as v1, but require WaveTrend to be in the matching extreme zone:
Buy at demand block only if wt1 < -30 (showing oversold, aligns with zone)
Sell at supply block only if wt1 > 30 (showing overbought, aligns with zone)
Double confirmation: structural (SMC) + momentum (WT).

## v3: ATR-relative zone size filter
Same as v1, but only trade zones where zone height (top - bottom) is between
0.3x and 1.5x ATR(14). Too thin = noise. Too thick = unclear level.

## Optimize
- Zone penetration threshold: 30%, 50%, 70%
- SL buffer beyond zone: 1, 2, 3 pips
- TP method: next zone vs 1.5x/2.0x SL ratio
- WT confirmation level: -20, -30, -40 (for v2)
- Min zone age: 5, 10, 20 bars since zone formed
- Max zone age: 100, 200, 500 bars (stale zones lose power)

## Notes
Uses SMC_Core.mqh in a fundamentally different way — zones as entries, not exits.
The "fresh zone" filter is critical: a zone tested twice loses its institutional
backing. Expect fewer trades than WT crossover but higher win rate per trade.
Works in ranging AND trending markets (order blocks form in both).
