//+------------------------------------------------------------------+
//|                              0405_143022_wt_crossover_v3.mq5     |
//|                WT crossover with stronger OB/OS levels            |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    WTChannel     = 10;    // WT Channel Length
input int    WTAverage     = 21;    // WT Average Length
input double WTOBLevel     = 60.0;  // WT Overbought Level (stronger)
input double WTOSLevel     = -60.0; // WT Oversold Level (stronger)
input double SL_Pips       = 15.0;  // Stop Loss (pips)
input double TP_Pips       = 30.0;  // Take Profit (pips)
input int    MagicNumber   = 100003; // Magic Number

//--- Globals
SWaveTrendState g_wt;
bool            g_warmedUp = false;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   WT_Init(g_wt, WTChannel, WTAverage);
   g_warmedUp = false;
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
void OnTick() {
   if(!g_warmedUp) {
      WarmUp();
      return;
   }
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   double h = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(h <= 0 || l <= 0 || c <= 0) return;
   WT_Update(g_wt, h, l, c);

   if(!Proto_CanTrade(_Symbol)) return;
   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   if(WT_IsOversold(g_wt, WTOSLevel) && WT_BullCross(g_wt))
      Proto_Buy(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTx_v3|B");

   if(WT_IsOverbought(g_wt, WTOBLevel) && WT_BearCross(g_wt))
      Proto_Sell(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTx_v3|S");
}

//+------------------------------------------------------------------+
void WarmUp() {
   int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
   if(bars < 50) return;

   double high[], low[], close[];
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, high)   <= 0) return;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, low)     <= 0) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, close) <= 0) return;

   WT_Init(g_wt, WTChannel, WTAverage);
   for(int i = 0; i < bars - 1; i++)
      WT_Update(g_wt, high[i], low[i], close[i]);

   g_warmedUp = true;
   g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   PrintFormat("WTx v3 warmed up: %d bars", bars - 1);
}
//+------------------------------------------------------------------+
