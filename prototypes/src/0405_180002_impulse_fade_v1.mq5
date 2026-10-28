//+------------------------------------------------------------------+
//|                           0405_180002_impulse_fade_v1.mq5        |
//|                Fade sharp impulses after exhaustion               |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>

//--- Strategy inputs
input int    ATRPeriod         = 14;    // ATR period
input double ImpulseATRMult    = 2.0;   // Impulse threshold (ATR multiple)
input int    PauseBars         = 3;     // Bars to wait after impulse
input double RetracePct        = 38.2;  // TP at this % retracement
input double SLBufferPips      = 2.0;   // SL beyond impulse extreme + buffer
input int    CooldownBars      = 20;    // Min bars between trades
input int    MagicNumber       = 400001; // Magic Number

//--- Globals
int    g_atrHandle = INVALID_HANDLE;
bool   g_impulseActive = false;
bool   g_isBearImpulse = false;
double g_impulseHigh = 0;
double g_impulseLow = 0;
int    g_impulseBarsAgo = 0;
int    g_cooldownLeft = 0;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
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
   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(g_atrHandle, 0, 0, 3, atr) <= 0) return;

   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double o1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   if(h1 <= 0 || l1 <= 0 || c1 <= 0 || o1 <= 0) return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipSize = 10.0 * point;

   // Decrement cooldown
   if(g_cooldownLeft > 0) g_cooldownLeft--;

   // Track bars since impulse
   if(g_impulseActive) g_impulseBarsAgo++;

   // Detect new impulse on Bar[1]
   double barSize = MathAbs(c1 - o1);
   if(barSize > ImpulseATRMult * atr[1] && !g_impulseActive) {
      g_impulseActive = true;
      g_impulseBarsAgo = 0;
      g_impulseHigh = h1;
      g_impulseLow  = l1;
      g_isBearImpulse = (c1 < o1);
      return;
   }

   // Update impulse extremes during pause
   if(g_impulseActive && g_impulseBarsAgo <= PauseBars) {
      if(h1 > g_impulseHigh) g_impulseHigh = h1;
      if(l1 < g_impulseLow)  g_impulseLow  = l1;

      // Check if exhaustion failed (continued making new extremes past pause)
      if(g_impulseBarsAgo == PauseBars) {
         // Check exhaustion: no new extreme in last PauseBars
         bool exhausted;
         if(g_isBearImpulse)
            exhausted = (l1 >= g_impulseLow); // not making new lows
         else
            exhausted = (h1 <= g_impulseHigh); // not making new highs

         if(!exhausted) {
            g_impulseActive = false;
            return;
         }
      }
      return;
   }

   // Entry after pause
   if(g_impulseActive && g_impulseBarsAgo == PauseBars + 1) {
      g_impulseActive = false;

      if(g_cooldownLeft > 0) return;
      if(!Proto_CanTrade(_Symbol)) return;
      if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

      double impulseRange = g_impulseHigh - g_impulseLow;
      double retraceTarget = impulseRange * RetracePct / 100.0;

      if(g_isBearImpulse) {
         // Fade bearish impulse: buy
         double slPips = (c1 - g_impulseLow) / pipSize + SLBufferPips;
         double tpPips = retraceTarget / pipSize;
         if(tpPips < 1.0) return;
         Proto_Buy(_Symbol, slPips, tpPips, MagicNumber, "IF_v1|B");
      } else {
         // Fade bullish impulse: sell
         double slPips = (g_impulseHigh - c1) / pipSize + SLBufferPips;
         double tpPips = retraceTarget / pipSize;
         if(tpPips < 1.0) return;
         Proto_Sell(_Symbol, slPips, tpPips, MagicNumber, "IF_v1|S");
      }
      g_cooldownLeft = CooldownBars;
   }

   // Expire stale impulses
   if(g_impulseActive && g_impulseBarsAgo > PauseBars + 5) {
      g_impulseActive = false;
   }
}
//+------------------------------------------------------------------+
