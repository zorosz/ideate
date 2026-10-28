//+------------------------------------------------------------------+
//|                              0405_143022_wt_crossover_v2.mq5     |
//|                WT crossover + M10 WaveTrend confirmation          |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    WTChannel      = 10;    // WT Channel Length
input int    WTAverage      = 21;    // WT Average Length
input double WTOBLevel      = 53.0;  // WT M1 Overbought Level
input double WTOSLevel      = -53.0; // WT M1 Oversold Level
input double WTM10OBLevel   = 30.0;  // WT M10 Overbought Level
input double WTM10OSLevel   = -30.0; // WT M10 Oversold Level
input double SL_Pips        = 15.0;  // Stop Loss (pips)
input double TP_Pips        = 30.0;  // Take Profit (pips)
input int    MagicNumber    = 100002; // Magic Number

//--- Globals
SWaveTrendState g_wt;
SWaveTrendState g_wtM10;
bool            g_warmedUp = false;
datetime        g_m10BucketTime = 0;
double          g_m10High = 0, g_m10Low = DBL_MAX, g_m10Close = 0;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   WT_Init(g_wt, WTChannel, WTAverage);
   WT_Init(g_wtM10, WTChannel, WTAverage);
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

   // Feed completed Bar[1] to M1 WT and M10 aggregator
   double h = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c = iClose(_Symbol, PERIOD_CURRENT, 1);
   datetime t = iTime(_Symbol, PERIOD_CURRENT, 1);
   if(h <= 0 || l <= 0 || c <= 0) return;

   WT_Update(g_wt, h, l, c);

   int m10Sec = PeriodSeconds(PERIOD_M10);
   datetime m10Time = t - (t % m10Sec);
   if(m10Time != g_m10BucketTime) {
      if(g_m10BucketTime > 0 && g_m10High > 0)
         WT_Update(g_wtM10, g_m10High, g_m10Low, g_m10Close);
      g_m10BucketTime = m10Time;
      g_m10High = h;
      g_m10Low  = l;
   } else {
      if(h > g_m10High) g_m10High = h;
      if(l < g_m10Low)  g_m10Low  = l;
   }
   g_m10Close = c;

   if(!Proto_CanTrade(_Symbol)) return;
   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   // M1 trigger + M10 confirmation
   bool m1Buy  = WT_IsOversold(g_wt, WTOSLevel) && WT_BullCross(g_wt);
   bool m1Sell = WT_IsOverbought(g_wt, WTOBLevel) && WT_BearCross(g_wt);
   bool m10Buy  = WT_IsOversold(g_wtM10, WTM10OSLevel);
   bool m10Sell = WT_IsOverbought(g_wtM10, WTM10OBLevel);

   if(m1Buy && m10Buy)
      Proto_Buy(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTx_v2|B");

   if(m1Sell && m10Sell)
      Proto_Sell(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTx_v2|S");
}

//+------------------------------------------------------------------+
void WarmUp() {
   int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
   if(bars < 50) return;

   double high[], low[], close[];
   datetime time[];
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, high)   <= 0) return;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, low)     <= 0) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, close) <= 0) return;
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, bars, time)   <= 0) return;

   WT_Init(g_wt, WTChannel, WTAverage);
   WT_Init(g_wtM10, WTChannel, WTAverage);
   g_m10BucketTime = 0;
   g_m10High = 0;
   g_m10Low = DBL_MAX;
   g_m10Close = 0;

   int m10Sec = PeriodSeconds(PERIOD_M10);
   for(int i = 0; i < bars - 1; i++) {
      WT_Update(g_wt, high[i], low[i], close[i]);
      datetime m10Time = time[i] - (time[i] % m10Sec);
      if(m10Time != g_m10BucketTime) {
         if(g_m10BucketTime > 0 && g_m10High > 0)
            WT_Update(g_wtM10, g_m10High, g_m10Low, g_m10Close);
         g_m10BucketTime = m10Time;
         g_m10High = high[i];
         g_m10Low  = low[i];
      } else {
         if(high[i] > g_m10High) g_m10High = high[i];
         if(low[i] < g_m10Low)   g_m10Low  = low[i];
      }
      g_m10Close = close[i];
   }

   g_warmedUp = true;
   g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   PrintFormat("WTx v2 warmed up: %d bars", bars - 1);
}
//+------------------------------------------------------------------+
