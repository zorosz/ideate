//+------------------------------------------------------------------+
//|                        0405_200000_smc_trend_filter_v2.mq5       |
//|                WT crossover + BOS filter + CHoCH pause            |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>
#include <SMC_Core.mqh>

//--- Strategy inputs
input int    WTChannel      = 10;    // WT Channel Length
input int    WTAverage      = 21;    // WT Average Length
input double WTOBLevel      = 53.0;  // WT Overbought Level
input double WTOSLevel      = -53.0; // WT Oversold Level
input double WTM10OBLevel   = 30.0;  // WT M10 Overbought Level
input double WTM10OSLevel   = -30.0; // WT M10 Oversold Level
input int    SwingLength     = 50;   // SMC swing lookback
input int    ATRPeriod       = 14;   // ATR period
input int    ChochPauseBars  = 20;   // Bars to pause after CHoCH
input double SL_Pips        = 15.0;  // Fixed SL (pips)
input double TP_Pips        = 30.0;  // Fixed TP (pips)
input int    MagicNumber    = 500002; // Magic Number

//--- Globals
SWaveTrendState g_wt;
SWaveTrendState g_wtM10;
bool           g_warmedUp = false;
datetime       g_m10BucketTime = 0;
double         g_m10High = 0, g_m10Low = DBL_MAX, g_m10Close = 0;

int            g_atrHandle = INVALID_HANDLE;
SSMCState      g_smcState;
SSwingPoint    g_swings[];
int            g_swingCount = 0;
SOrderBlock    g_blocks[];
int            g_blockCount = 0;
SStructureBreak g_breaks[];
int            g_breakCount = 0;

int            g_prevBreakCount = 0;
int            g_chochCooldown = 0;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   WT_Init(g_wt, WTChannel, WTAverage);
   WT_Init(g_wtM10, WTChannel, WTAverage);
   SMC_Init(g_smcState);
   g_warmedUp = false;
   g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   if(g_atrHandle == INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
void OnTick() {
   if(!g_warmedUp) {
      WarmUp();
      return;
   }
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   datetime t1 = iTime(_Symbol, PERIOD_CURRENT, 1);
   if(h1 <= 0 || l1 <= 0 || c1 <= 0) return;

   WT_Update(g_wt, h1, l1, c1);
   FeedM10(h1, l1, c1, t1);

   int smcBars = SwingLength * 2 + 50;
   double high[], low[], close[], atrBuf[];
   datetime time[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(atrBuf, true);
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, smcBars, high)     <= 0) return;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, smcBars, low)       <= 0) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, smcBars, close)   <= 0) return;
   if(CopyTime(_Symbol, PERIOD_CURRENT, 0, smcBars, time)     <= 0) return;
   if(CopyBuffer(g_atrHandle, 0, 0, smcBars, atrBuf)          <= 0) return;

   SMC_Update(high, low, close, atrBuf, time, SwingLength, 0,
              g_smcState, g_swings, g_swingCount, g_blocks, g_blockCount, g_breaks, g_breakCount);

   // Detect new CHoCH and start cooldown
   if(g_breakCount > g_prevBreakCount) {
      for(int i = g_prevBreakCount; i < g_breakCount; i++) {
         if(g_breaks[i].isChoch)
            g_chochCooldown = ChochPauseBars;
      }
      g_prevBreakCount = g_breakCount;
   }

   // Decrement cooldown
   if(g_chochCooldown > 0) g_chochCooldown--;

   if(!Proto_CanTrade(_Symbol)) return;
   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   // CHoCH pause active — no entries
   if(g_chochCooldown > 0) return;

   bool m1Buy  = WT_IsOversold(g_wt, WTOSLevel) && WT_BullCross(g_wt);
   bool m1Sell = WT_IsOverbought(g_wt, WTOBLevel) && WT_BearCross(g_wt);
   bool m10Buy  = WT_IsOversold(g_wtM10, WTM10OSLevel);
   bool m10Sell = WT_IsOverbought(g_wtM10, WTM10OBLevel);

   if(m1Buy && m10Buy && g_smcState.trend == 1)
      Proto_Buy(_Symbol, SL_Pips, TP_Pips, MagicNumber, "STF_v2|B");

   if(m1Sell && m10Sell && g_smcState.trend == -1)
      Proto_Sell(_Symbol, SL_Pips, TP_Pips, MagicNumber, "STF_v2|S");
}

//+------------------------------------------------------------------+
void FeedM10(double h, double l, double c, datetime t) {
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
   g_m10BucketTime = 0; g_m10High = 0; g_m10Low = DBL_MAX; g_m10Close = 0;

   int m10Sec = PeriodSeconds(PERIOD_M10);
   for(int i = 0; i < bars - 1; i++) {
      WT_Update(g_wt, high[i], low[i], close[i]);
      datetime m10Time = time[i] - (time[i] % m10Sec);
      if(m10Time != g_m10BucketTime) {
         if(g_m10BucketTime > 0 && g_m10High > 0)
            WT_Update(g_wtM10, g_m10High, g_m10Low, g_m10Close);
         g_m10BucketTime = m10Time;
         g_m10High = high[i]; g_m10Low = low[i];
      } else {
         if(high[i] > g_m10High) g_m10High = high[i];
         if(low[i] < g_m10Low)   g_m10Low  = low[i];
      }
      g_m10Close = close[i];
   }

   g_warmedUp = true;
   g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   g_prevBreakCount = g_breakCount;
}
//+------------------------------------------------------------------+
