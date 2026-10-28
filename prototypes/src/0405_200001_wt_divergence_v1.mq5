//+------------------------------------------------------------------+
//|                           0405_200001_wt_divergence_v1.mq5       |
//|                WT classic divergence entry                        |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    WTChannel      = 10;    // WT Channel Length
input int    WTAverage      = 21;    // WT Average Length
input double WTZoneLevel    = 30.0;  // WT must be in this zone for divergence
input int    DivLookback    = 20;    // Max bars between two WT swings
input double SL_Pips        = 15.0;  // Stop Loss (pips)
input double TP_Pips        = 30.0;  // Take Profit (pips)
input int    MagicNumber    = 600001; // Magic Number

//--- Globals
SWaveTrendState g_wt;
bool           g_warmedUp = false;

// Track WT swing extremes and corresponding prices
double g_prevWTLow = 0;        // previous WT trough (for bullish div)
double g_prevPriceLow = 0;     // price low at previous WT trough
double g_currWTLow = 0;        // current WT trough
double g_currPriceLow = 0;     // price low at current WT trough
int    g_barsFromWTLow = 999;  // bars since last WT trough

double g_prevWTHigh = 0;       // previous WT peak (for bearish div)
double g_prevPriceHigh = 0;    // price high at previous WT peak
double g_currWTHigh = 0;       // current WT peak
double g_currPriceHigh = 0;    // price high at current WT peak
int    g_barsFromWTHigh = 999; // bars since last WT peak

// Previous WT values for swing detection
double g_wt1Prev2 = 0;
double g_wt1Prev1 = 0;

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

   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(h1 <= 0 || l1 <= 0 || c1 <= 0) return;

   // Shift previous WT values
   g_wt1Prev2 = g_wt1Prev1;
   g_wt1Prev1 = g_wt.wt1;

   WT_Update(g_wt, h1, l1, c1);

   double wt1Now = g_wt.wt1;

   // Increment bar counters
   g_barsFromWTLow++;
   g_barsFromWTHigh++;

   // Detect WT trough: prev1 < prev2 AND prev1 < now (local minimum)
   if(g_wt1Prev1 < g_wt1Prev2 && g_wt1Prev1 < wt1Now) {
      // New WT trough found — shift current to previous
      g_prevWTLow = g_currWTLow;
      g_prevPriceLow = g_currPriceLow;
      g_currWTLow = g_wt1Prev1;
      g_currPriceLow = iLow(_Symbol, PERIOD_CURRENT, 2); // bar that had the trough
      g_barsFromWTLow = 0;
   }

   // Detect WT peak: prev1 > prev2 AND prev1 > now (local maximum)
   if(g_wt1Prev1 > g_wt1Prev2 && g_wt1Prev1 > wt1Now) {
      g_prevWTHigh = g_currWTHigh;
      g_prevPriceHigh = g_currPriceHigh;
      g_currWTHigh = g_wt1Prev1;
      g_currPriceHigh = iHigh(_Symbol, PERIOD_CURRENT, 2);
      g_barsFromWTHigh = 0;
   }

   if(!Proto_CanTrade(_Symbol)) return;
   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   // Bullish divergence: price lower low + WT higher low, in oversold zone
   if(g_prevWTLow != 0 && g_currWTLow != 0 &&
      g_barsFromWTLow <= DivLookback &&
      g_currWTLow < -WTZoneLevel &&
      g_currPriceLow < g_prevPriceLow &&     // price made lower low
      g_currWTLow > g_prevWTLow) {           // WT made higher low = divergence
      Proto_Buy(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTD_v1|B");
      g_currWTLow = 0; // reset to avoid re-entry
   }

   // Bearish divergence: price higher high + WT lower high, in overbought zone
   if(g_prevWTHigh != 0 && g_currWTHigh != 0 &&
      g_barsFromWTHigh <= DivLookback &&
      g_currWTHigh > WTZoneLevel &&
      g_currPriceHigh > g_prevPriceHigh &&   // price made higher high
      g_currWTHigh < g_prevWTHigh) {          // WT made lower high = divergence
      Proto_Sell(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTD_v1|S");
      g_currWTHigh = 0; // reset
   }
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

   g_wt1Prev2 = 0;
   g_wt1Prev1 = g_wt.wt1;
   g_warmedUp = true;
   g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
}
//+------------------------------------------------------------------+
