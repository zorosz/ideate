//+------------------------------------------------------------------+
//|              0408_120000_liquidity_sweep_reversal_v6.mq5          |
//|     Liquidity Sweep Reversal — v6 (pierce-magnitude tier system)  |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <SMC_Core.mqh>

//--- Strategy inputs
input int    SwingLength       = 20;     // SMC swing detection bars
input int    MaxSwingAge       = 30;     // Max age of swing reference (bars)
input int    MaxBarsInTrade    = 30;     // Time stop (bars)
input double StopBufferPips    = 2.0;    // SL buffer beyond pierce extreme
input double SmallPierceMaxPips  = 2.0;  // Below this = SKIP (noise)
input double MediumPierceMaxPips = 8.0;  // Up to this = standard tier
// Above MediumPierceMaxPips = "violent sweep" tier (still standard size)
input int    MagicNumber       = 411006; // Magic Number

//--- SMC state
int             g_atrHandle = INVALID_HANDLE;
SSMCState       g_smcState;
SSwingPoint     g_swings[];
int             g_swingCount = 0;
SOrderBlock     g_blocks[];
int             g_blockCount = 0;
SStructureBreak g_breaks[];
int             g_breakCount = 0;

//--- Position state
int             g_barsInTrade = 0;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   SMC_Init(g_smcState);
   g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(g_atrHandle == INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
void OnTick() {
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) {
      g_barsInTrade++;
      if(g_barsInTrade >= MaxBarsInTrade) {
         Proto_CloseAll(MagicNumber, _Symbol);
         g_barsInTrade = 0;
      }
      return;
   } else {
      g_barsInTrade = 0;
   }

   if(!Proto_CanTrade(_Symbol)) return;

   int needBars = SwingLength * 3 + 60;
   double high[], low[], close[], atr[];
   datetime time[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(atr, true);

   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, needBars, high)   <= 0) return;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, needBars, low)     <= 0) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, needBars, close) <= 0) return;
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, needBars, time)   <= 0) return;
   if(CopyBuffer(g_atrHandle, 0, 0, needBars, atr)           <= 0) return;

   SMC_Update(high, low, close, atr, time, SwingLength, 0,
              g_smcState, g_swings, g_swingCount,
              g_blocks, g_blockCount, g_breaks, g_breakCount);

   double swingHigh = 0, swingLow = 0;
   bool shFound = false, slFound = false;
   datetime now = time[0];
   int periodSec = PeriodSeconds(PERIOD_CURRENT);
   if(periodSec <= 0) periodSec = 60;

   for(int i = g_swingCount - 1; i >= 0 && (!shFound || !slFound); i--) {
      int ageBars = (int)((now - g_swings[i].time) / periodSec);
      if(ageBars > MaxSwingAge) break;
      if(g_swings[i].isHigh && !shFound) {
         swingHigh = g_swings[i].price;
         shFound = true;
      }
      if(!g_swings[i].isHigh && !slFound) {
         swingLow = g_swings[i].price;
         slFound = true;
      }
   }

   if(!shFound || !slFound) return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipSize = 10.0 * point;

   double bar2High = high[2];
   double bar2Low  = low[2];
   double bar1Close = close[1];

   // Sweep above swing high → SELL setup
   double piercePipsHigh = (bar2High - swingHigh) / pipSize;
   if(piercePipsHigh > SmallPierceMaxPips && bar1Close < swingHigh) {
      string tier = (piercePipsHigh <= MediumPierceMaxPips) ? "M" : "L";
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slPips = ((bar2High - bid) / pipSize) + StopBufferPips;
      if(slPips < 3.0) slPips = 3.0;
      double tpPips = (bid - swingLow) / pipSize;
      if(tpPips < 5.0) tpPips = slPips * 1.5;

      string cmt = "LSR_v6|S|" + tier;
      if(Proto_Sell(_Symbol, slPips, tpPips, MagicNumber, cmt)) {
         g_barsInTrade = 0;
      }
      return;
   }

   // Sweep below swing low → BUY setup
   double piercePipsLow = (swingLow - bar2Low) / pipSize;
   if(piercePipsLow > SmallPierceMaxPips && bar1Close > swingLow) {
      string tier = (piercePipsLow <= MediumPierceMaxPips) ? "M" : "L";
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slPips = ((ask - bar2Low) / pipSize) + StopBufferPips;
      if(slPips < 3.0) slPips = 3.0;
      double tpPips = (swingHigh - ask) / pipSize;
      if(tpPips < 5.0) tpPips = slPips * 1.5;

      string cmt = "LSR_v6|B|" + tier;
      if(Proto_Buy(_Symbol, slPips, tpPips, MagicNumber, cmt)) {
         g_barsInTrade = 0;
      }
      return;
   }
}
//+------------------------------------------------------------------+
