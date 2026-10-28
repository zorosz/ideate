//+------------------------------------------------------------------+
//|                           0405_200001_wt_divergence_v2.mq5       |
//|                Divergence flag → WT cross confirms entry          |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    WTChannel      = 10;    // WT Channel Length
input int    WTAverage      = 21;    // WT Average Length
input double WTOBLevel      = 53.0;  // WT Overbought for cross
input double WTOSLevel      = -53.0; // WT Oversold for cross
input double WTZoneLevel    = 30.0;  // WT zone for divergence detection
input int    DivLookback    = 20;    // Max bars between WT swings
input int    DivExpiry      = 10;    // Bars until divergence flag expires
input double SL_Pips        = 15.0;  // Stop Loss (pips)
input double TP_Pips        = 30.0;  // Take Profit (pips)
input int    MagicNumber    = 600002; // Magic Number

//--- Globals
SWaveTrendState g_wt;
bool           g_warmedUp = false;

// WT swing tracking (same as v1)
double g_prevWTLow = 0, g_prevPriceLow = 0;
double g_currWTLow = 0, g_currPriceLow = 0;
int    g_barsFromWTLow = 999;

double g_prevWTHigh = 0, g_prevPriceHigh = 0;
double g_currWTHigh = 0, g_currPriceHigh = 0;
int    g_barsFromWTHigh = 999;

double g_wt1Prev2 = 0, g_wt1Prev1 = 0;

// Divergence flags
bool   g_bullDivFlag = false;
int    g_bullDivAge = 0;
bool   g_bearDivFlag = false;
int    g_bearDivAge = 0;

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
      int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
      if(bars < 50) return;
      double h[], l[], c[];
      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, h)   <= 0) return;
      if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, l)    <= 0) return;
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, c)  <= 0) return;
      WT_Init(g_wt, WTChannel, WTAverage);
      for(int i = 0; i < bars - 1; i++) WT_Update(g_wt, h[i], l[i], c[i]);
      g_wt1Prev1 = g_wt.wt1;
      g_warmedUp = true;
      g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      return;
   }
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(h1 <= 0 || l1 <= 0 || c1 <= 0) return;

   g_wt1Prev2 = g_wt1Prev1;
   g_wt1Prev1 = g_wt.wt1;
   WT_Update(g_wt, h1, l1, c1);
   double wt1Now = g_wt.wt1;

   g_barsFromWTLow++;
   g_barsFromWTHigh++;

   // Age divergence flags
   if(g_bullDivFlag) { g_bullDivAge++; if(g_bullDivAge > DivExpiry) g_bullDivFlag = false; }
   if(g_bearDivFlag) { g_bearDivAge++; if(g_bearDivAge > DivExpiry) g_bearDivFlag = false; }

   // Detect WT trough
   if(g_wt1Prev1 < g_wt1Prev2 && g_wt1Prev1 < wt1Now) {
      g_prevWTLow = g_currWTLow;
      g_prevPriceLow = g_currPriceLow;
      g_currWTLow = g_wt1Prev1;
      g_currPriceLow = iLow(_Symbol, PERIOD_CURRENT, 2);
      g_barsFromWTLow = 0;

      // Check for bullish divergence
      if(g_prevWTLow != 0 && g_barsFromWTLow <= DivLookback &&
         g_currWTLow < -WTZoneLevel &&
         g_currPriceLow < g_prevPriceLow &&
         g_currWTLow > g_prevWTLow) {
         g_bullDivFlag = true;
         g_bullDivAge = 0;
      }
   }

   // Detect WT peak
   if(g_wt1Prev1 > g_wt1Prev2 && g_wt1Prev1 > wt1Now) {
      g_prevWTHigh = g_currWTHigh;
      g_prevPriceHigh = g_currPriceHigh;
      g_currWTHigh = g_wt1Prev1;
      g_currPriceHigh = iHigh(_Symbol, PERIOD_CURRENT, 2);
      g_barsFromWTHigh = 0;

      // Check for bearish divergence
      if(g_prevWTHigh != 0 && g_barsFromWTHigh <= DivLookback &&
         g_currWTHigh > WTZoneLevel &&
         g_currPriceHigh > g_prevPriceHigh &&
         g_currWTHigh < g_prevWTHigh) {
         g_bearDivFlag = true;
         g_bearDivAge = 0;
      }
   }

   if(!Proto_CanTrade(_Symbol)) return;
   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   // v2: Enter on WT cross ONLY if divergence flag is active
   if(g_bullDivFlag && WT_IsOversold(g_wt, WTOSLevel) && WT_BullCross(g_wt)) {
      Proto_Buy(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTD_v2|B");
      g_bullDivFlag = false;
   }

   if(g_bearDivFlag && WT_IsOverbought(g_wt, WTOBLevel) && WT_BearCross(g_wt)) {
      Proto_Sell(_Symbol, SL_Pips, TP_Pips, MagicNumber, "WTD_v2|S");
      g_bearDivFlag = false;
   }
}
//+------------------------------------------------------------------+
