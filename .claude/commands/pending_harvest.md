---
description: "Convert hedge_dynamic_aggressive to pending order harvest — autonomous dev"
---

# Pending order harvest — hedge_dynamic_aggressive

Convert all harvest market orders to pre-placed pending orders
for zero slippage. Autonomous development: compile, test, verify
logs, fix, repeat until clean.

## Current behavior (market orders)

```
Position opens → monitor profit each tick → when >= HarvestPips:
  Close position (market order — slippage)
  Open BUY (market order — slippage)
  Open SELL (market order — slippage)
  = 3 market orders, 3× slippage
```

## Target behavior (pending orders)

```
BUY opens at price P:
  Set BUY TP = P + HarvestPips
  Place BUY STOP  @ P + HarvestPips  (next BUY ready)
  Place SELL LIMIT @ P + HarvestPips  (next SELL ready)

SELL opens at price P:
  Set SELL TP = P - HarvestPips
  Place BUY LIMIT @ P - HarvestPips  (next BUY ready)
  Place SELL STOP  @ P - HarvestPips  (next SELL ready)

When TP hits (server-side, 0 slippage):
  Position closes at exact TP price
  Pending BUY fills at exact same price
  Pending SELL fills at exact same price
  = 0 market orders, 0 slippage

For the new positions: repeat — set TP + place next pendings.
```

## State tracking

Each position needs to track its associated pending orders:

```cpp
struct HarvestSet {
   ulong positionTicket;     // the position
   ulong nextBuyPending;     // pending for next BUY
   ulong nextSellPending;    // pending for next SELL
   double tpLevel;           // expected TP/fill level
};
```

When a position closes AND its pendings fill, the HarvestSet
is complete. Create new HarvestSets for the newly opened positions.

## Batch close interaction

When batch close fires (market orders — can't avoid):
1. Close all positions on the accumulated side
2. CANCEL all pending orders associated with those positions
3. Open one fresh position on the cleared side
4. Set up HarvestSet for the fresh position

## Implementation order

Work function by function. /compile after EACH function.
After each successful compile, run a SHORT backtest and verify.

### Step 1: Add HarvestSet tracking

Add the struct and a dynamic array to track active sets.
Helper functions:
- CreateHarvestSet(ticket, tpLevel, buyPending, sellPending)
- FindHarvestSet(positionTicket) → returns index or -1
- RemoveHarvestSet(index)
- CancelHarvestPendings(index) — cancel associated pendings

/compile

### Step 2: PlaceHarvestOrders(ticket, entryPrice, isBuy)

Called when a position opens. Places TP + 2 pending orders.

```
PlaceHarvestOrders(ulong ticket, double entry, bool isBuy):
  double pipValue = 10.0 * _Point;  // 5-digit broker
  
  if(isBuy):
    double level = NormalizeDouble(entry + HarvestPips * pipValue, _Digits)
    PositionModify(ticket, 0, level)  // set TP
    BUY STOP @ level   → nextBuyPending
    SELL LIMIT @ level  → nextSellPending
  else:
    double level = NormalizeDouble(entry - HarvestPips * pipValue, _Digits)
    PositionModify(ticket, 0, level)  // set TP
    BUY LIMIT @ level  → nextBuyPending
    SELL STOP @ level   → nextSellPending
  
  CreateHarvestSet(ticket, level, nextBuyPending, nextSellPending)
  
  Print("HARVEST_SETUP: pos=%d entry=%.5f tp=%.5f buyPend=%d sellPend=%d",
        ticket, entry, level, nextBuyPending, nextSellPending);
```

/compile

### Step 3: DetectHarvestFill()

Called every tick. Checks if a position closed (TP hit) and
its pending orders filled.

```
DetectHarvestFill():
  for each HarvestSet:
    if position no longer exists (TP hit):
      // Check if pendings filled
      bool buyFilled = (pending gone AND new BUY position exists)
      bool sellFilled = (pending gone AND new SELL position exists)
      
      if buyFilled AND sellFilled:
        Print("HARVEST_COMPLETE: old=%d level=%.5f newBuy=%d newSell=%d",
              set.positionTicket, set.tpLevel, newBuyTicket, newSellTicket)
        
        // Set up HarvestSets for the new positions
        PlaceHarvestOrders(newBuyTicket, fillPrice, true)
        PlaceHarvestOrders(newSellTicket, fillPrice, false)
        RemoveHarvestSet(index)
      
      else if neither filled:
        // TP hit but pendings didn't fill — ERROR
        Print("HARVEST_ERROR: pos=%d closed but pendings not filled!", 
              set.positionTicket)
        // Fallback: open market orders
```

/compile

### Step 4: Modify batch close to cancel pendings

When batch close fires on accumulated side:
```
BatchClose():
  for each position being closed:
    int idx = FindHarvestSet(ticket)
    if idx >= 0:
      CancelHarvestPendings(idx)
      RemoveHarvestSet(idx)
      Print("BATCH_CANCEL: cancelled pendings for pos=%d", ticket)
  
  // Close positions
  // Open fresh position
  // PlaceHarvestOrders on fresh position
```

/compile

### Step 5: Modify OnInit/startup

On startup (or when integrity check opens first pair):
- Open BUY + SELL
- PlaceHarvestOrders for each

/compile

### Step 6: Remove old harvest logic

Delete the old market-order harvest code:
- Remove CheckHarvest() function that uses PositionClose + Buy/Sell
- All harvest now flows through TP → DetectHarvestFill → PlaceHarvestOrders

/compile

## Verification — after EVERY compile

Run a SHORT backtest: 2025.01.01 to 2025.02.01 (1 month only).
Model: Every tick.

### Log verification checklist

Read the backtest journal. Check ALL of these:

1. **TP matches pending level**: 
   Every HARVEST_SETUP log shows tp=X.XXXXX
   Every HARVEST_COMPLETE log shows level=X.XXXXX
   Verify: tp level == pending fill level (exact match)
   
   ```
   Search for: HARVEST_SETUP and HARVEST_COMPLETE
   Extract: tp values and level values
   Compare: they must be identical to 5 decimal places
   ```

2. **No market orders during harvest**:
   Search for: "market buy" or "market sell" 
   These should ONLY appear during batch close and integrity check.
   If market orders appear during harvest → BUG

3. **Pending order placement**:
   Every HARVEST_SETUP should show non-zero buyPend and sellPend
   If either is 0 → order placement failed → BUG

4. **Harvest distance is exactly HarvestPips**:
   For each HARVEST_COMPLETE:
     distance = |newEntry - oldEntry|
     expected = HarvestPips * 10 * point
     if distance != expected → BUG (pip calculation error)

5. **No orphan pendings**:
   At end of test, count open pending orders.
   Should be exactly 2 per open position (next BUY + next SELL).
   More = orphan pendings not cleaned up → BUG

6. **Batch close cleanup**:
   Every BATCH_CANCEL should appear before batch close completes.
   After batch close: no pendings should remain for closed positions.

### If ANY check fails

1. Print which check failed and the specific log lines
2. Identify the root cause
3. Fix the code
4. /compile
5. Rerun the 1-month backtest
6. Verify all 6 checks again
7. Repeat until ALL checks pass

### When all checks pass

Run full backtest: 2024.01.01 to 2026.01.01 (2 years).
Compare results with the market-order version:

```
| Metric      | Market Orders | Pending Orders | Diff |
|-------------|--------------|----------------|------|
| Net profit  |              |                |      |
| PF          |              |                |      |
| Total trades|              |                |      |
| Max DD %    |              |                |      |
| Avg profit  |              |                | ← should improve (less slippage) |
| Avg loss    |              |                |      |
```

/commit with message: "feat: pending order harvest — zero slippage"

## Important edge cases

1. **Pending rejected (invalid price)**: if the TP level is too 
   close to current price (< SYMBOL_TRADE_STOPS_LEVEL), the pending
   will fail. Fallback: use market order for that harvest only.

2. **Multiple TPs hit same tick**: if BUY and SELL both hit TP on 
   the same tick (shouldn't happen with H=5, but possible with gaps),
   DetectHarvestFill must handle both sets.

3. **Restart/reconnect**: if EA restarts, HarvestSets are lost.
   On startup, scan for existing positions and rebuild HarvestSets
   by checking if pending orders exist at entry ± HarvestPips.

4. **Batch close during pending fill**: if batch close fires on the
   same tick a TP hits, the pending may fill AND get closed immediately.
   DetectHarvestFill should check if the new position still exists
   before setting up new HarvestOrders.