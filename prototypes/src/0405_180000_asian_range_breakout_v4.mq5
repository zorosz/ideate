//+------------------------------------------------------------------+
//|                        0405_180000_asian_range_breakout_v4.mq5   |
//|                Asian range breakout + range size filter           |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>

//--- Strategy inputs
input int    AsianEndHour     = 7;     // Asian session end hour (UTC)
input int    LondonEndHour    = 9;     // London entry window end (UTC)
input double EntryBufferPips  = 3.0;   // Buffer above/below range (pips)
input double MaxSLPips        = 25.0;  // Max SL (pips)
input double TPRatio          = 1.5;   // TP = TPRatio * SL distance
input double MinRangePips     = 15.0;  // Min Asian range (pips)
input double MaxRangePips     = 40.0;  // Max Asian range (pips)
input int    MagicNumber      = 200004; // Magic Number

//--- Globals
double g_asianHigh = 0;
double g_asianLow = DBL_MAX;
bool   g_rangeReady = false;
bool   g_tradedToday = false;
int    g_lastDay = -1;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
void OnTick() {
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

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
      double h = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double l = iLow(_Symbol, PERIOD_CURRENT, 1);
      if(h > g_asianHigh) g_asianHigh = h;
      if(l < g_asianLow)  g_asianLow  = l;
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
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);

   // Range size filter
   double rangePips = (g_asianHigh - g_asianLow) / (10.0 * point);
   if(rangePips < MinRangePips || rangePips > MaxRangePips) return;

   if(close1 > g_asianHigh + buffer) {
      double slPips = MathMin((close1 - g_asianLow) / (10.0 * point), MaxSLPips);
      Proto_Buy(_Symbol, slPips, slPips * TPRatio, MagicNumber, "ARB_v4|B");
      g_tradedToday = true;
   }

   if(close1 < g_asianLow - buffer) {
      double slPips = MathMin((g_asianHigh - close1) / (10.0 * point), MaxSLPips);
      Proto_Sell(_Symbol, slPips, slPips * TPRatio, MagicNumber, "ARB_v4|S");
      g_tradedToday = true;
   }
}
//+------------------------------------------------------------------+
