//+------------------------------------------------------------------+
//|                        0405_180000_asian_range_breakout_v2.mq5   |
//|                Asian range breakout + WaveTrend confirmation      |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    AsianEndHour     = 7;     // Asian session end hour (UTC)
input int    LondonEndHour    = 9;     // London entry window end (UTC)
input double EntryBufferPips  = 3.0;   // Buffer above/below range (pips)
input double MaxSLPips        = 25.0;  // Max SL (pips)
input double TPRatio          = 1.5;   // TP = TPRatio * SL distance
input int    WTChannel        = 10;    // WT Channel Length
input int    WTAverage        = 21;    // WT Average Length
input int    MagicNumber      = 200002; // Magic Number

//--- Globals
double g_asianHigh = 0;
double g_asianLow = DBL_MAX;
bool   g_rangeReady = false;
bool   g_tradedToday = false;
int    g_lastDay = -1;
SWaveTrendState g_wt;
bool   g_wtWarmedUp = false;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   WT_Init(g_wt, WTChannel, WTAverage);
   g_wtWarmedUp = false;
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
void OnTick() {
   if(!g_wtWarmedUp) {
      int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
      if(bars < 50) return;
      double high[], low[], close[];
      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, high)   <= 0) return;
      if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, low)     <= 0) return;
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, close) <= 0) return;
      WT_Init(g_wt, WTChannel, WTAverage);
      for(int i = 0; i < bars - 1; i++)
         WT_Update(g_wt, high[i], low[i], close[i]);
      g_wtWarmedUp = true;
      g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      return;
   }

   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   // Feed WT
   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(h1 > 0 && l1 > 0 && c1 > 0)
      WT_Update(g_wt, h1, l1, c1);

   MqlDateTime now;
   TimeCurrent(now);
   int hour = now.hour;
   int day  = now.day;

   if(day != g_lastDay) {
      g_lastDay = day;
      g_asianHigh = 0;
      g_asianLow = DBL_MAX;
      g_rangeReady = false;
      g_tradedToday = false;
   }

   if(hour < AsianEndHour) {
      if(h1 > g_asianHigh) g_asianHigh = h1;
      if(l1 < g_asianLow)  g_asianLow  = l1;
      return;
   }

   if(!g_rangeReady && hour >= AsianEndHour) {
      if(g_asianHigh > 0 && g_asianLow < DBL_MAX && g_asianHigh > g_asianLow)
         g_rangeReady = true;
      else
         return;
   }

   if(hour >= LondonEndHour) return;
   if(g_tradedToday) return;
   if(!g_rangeReady) return;
   if(!Proto_CanTrade(_Symbol)) return;
   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double buffer = EntryBufferPips * 10 * point;

   // WT confirmation: buy if wt1 > 0 and rising, sell if wt1 < 0 and falling
   bool wtBuyOK  = (g_wt.wt1 > 0 && g_wt.wt1 > g_wt.wt2);
   bool wtSellOK = (g_wt.wt1 < 0 && g_wt.wt1 < g_wt.wt2);

   if(c1 > g_asianHigh + buffer && wtBuyOK) {
      double slPips = MathMin((c1 - g_asianLow) / (10.0 * point), MaxSLPips);
      Proto_Buy(_Symbol, slPips, slPips * TPRatio, MagicNumber, "ARB_v2|B");
      g_tradedToday = true;
   }

   if(c1 < g_asianLow - buffer && wtSellOK) {
      double slPips = MathMin((g_asianHigh - c1) / (10.0 * point), MaxSLPips);
      Proto_Sell(_Symbol, slPips, slPips * TPRatio, MagicNumber, "ARB_v2|S");
      g_tradedToday = true;
   }
}
//+------------------------------------------------------------------+
