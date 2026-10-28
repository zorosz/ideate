//+------------------------------------------------------------------+
//|              0408_120000_liquidity_sweep_reversal_v1.mq5          |
//|        Liquidity Sweep Reversal — base (pure sweep + confirm)     |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <SMC_Core.mqh>

//--- Strategy inputs
input int    SwingLength       = 20;     // SMC swing detection bars
input int    MaxSwingAge       = 30;     // Max age of swing reference (bars)
input double MinPierceMult     = 1.5;    // Pierce >= N * spread
input int    MaxBarsInTrade    = 30;     // Time stop (bars)
input double StopBufferPips    = 2.0;    // SL buffer beyond pierce extreme
input int    MagicNumber       = 411001; // Magic Number

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

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
void OnTick() {
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   // Time stop on existing position
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

   // Load bars
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

   // Update SMC swings (only the most recent bar is evaluated each call)
   SMC_Update(high, low, close, atr, time, SwingLength, 0,
              g_smcState, g_swings, g_swingCount,
              g_blocks, g_blockCount, g_breaks, g_breakCount);

   // Find most recent fresh swing high and swing low (within MaxSwingAge bars)
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

   if(!shFound && !slFound) return;

   // Pip / spread calculations
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipSize = 10.0 * point;
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0;
   double minPiercePips = MinPierceMult * spread;
   if(minPiercePips < 1.0) minPiercePips = 1.0;

   // Bar[2] = potential pierce bar; Bar[1] = confirmation bar
   // Both bars are completed when we evaluate on a new bar
   double bar2High = high[2];
   double bar2Low  = low[2];
   double bar1Close = close[1];

   // Sweep above swing high → SELL setup
   if(shFound && slFound) {
      double piercePips = (bar2High - swingHigh) / pipSize;
      if(piercePips >= minPiercePips && bar1Close < swingHigh) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double slDistance = bar2High - bid;
         double slPips = (slDistance / pipSize) + StopBufferPips;
         if(slPips < 3.0) slPips = 3.0;

         double tpDistance = bid - swingLow;
         double tpPips = tpDistance / pipSize;
         if(tpPips < 5.0) tpPips = slPips * 1.5;

         if(Proto_Sell(_Symbol, slPips, tpPips, MagicNumber, "LSR_v1|S")) {
            g_barsInTrade = 0;
            PrintFormat("LSR SELL: pierce=%.1fp sh=%.5f sl=%.1fp tp=%.1fp",
                        piercePips, swingHigh, slPips, tpPips);
         }
         return;
      }
   }

   // Sweep below swing low → BUY setup
   if(slFound && shFound) {
      double piercePips = (swingLow - bar2Low) / pipSize;
      if(piercePips >= minPiercePips && bar1Close > swingLow) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double slDistance = ask - bar2Low;
         double slPips = (slDistance / pipSize) + StopBufferPips;
         if(slPips < 3.0) slPips = 3.0;

         double tpDistance = swingHigh - ask;
         double tpPips = tpDistance / pipSize;
         if(tpPips < 5.0) tpPips = slPips * 1.5;

         if(Proto_Buy(_Symbol, slPips, tpPips, MagicNumber, "LSR_v1|B")) {
            g_barsInTrade = 0;
            PrintFormat("LSR BUY: pierce=%.1fp sl=%.5f sl=%.1fp tp=%.1fp",
                        piercePips, swingLow, slPips, tpPips);
         }
         return;
      }
   }
}
//+------------------------------------------------------------------+
