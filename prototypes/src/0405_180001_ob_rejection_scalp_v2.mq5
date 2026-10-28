//+------------------------------------------------------------------+
//|                        0405_180001_ob_rejection_scalp_v2.mq5     |
//|                OB rejection + WaveTrend exhaustion confirmation    |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <SMC_Core.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    SwingLength       = 50;    // SMC swing lookback
input double PenetrationPct    = 50.0;  // Min % wick into zone
input double SLBufferPips      = 2.0;   // SL beyond zone edge (pips)
input double FallbackTPRatio   = 1.5;   // Fallback TP = ratio * SL
input int    MaxZoneAgeBars    = 200;   // Max zone age (bars)
input int    ATRPeriod         = 14;    // ATR period
input int    WTChannel         = 10;    // WT Channel Length
input int    WTAverage         = 21;    // WT Average Length
input double WTConfirmLevel    = 30.0;  // WT exhaustion threshold
input int    MagicNumber       = 300002; // Magic Number

//--- Globals
int            g_atrHandle = INVALID_HANDLE;
SSMCState      g_smcState;
SSwingPoint    g_swings[];
int            g_swingCount = 0;
SOrderBlock    g_blocks[];
int            g_blockCount = 0;
SStructureBreak g_breaks[];
int            g_breakCount = 0;
SWaveTrendState g_wt;
bool           g_wtWarmedUp = false;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   SMC_Init(g_smcState);
   WT_Init(g_wt, WTChannel, WTAverage);
   g_wtWarmedUp = false;
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
   if(!g_wtWarmedUp) {
      int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
      if(bars < 50) return;
      double h[], l[], c[];
      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, h)   <= 0) return;
      if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, l)    <= 0) return;
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, c)  <= 0) return;
      WT_Init(g_wt, WTChannel, WTAverage);
      for(int i = 0; i < bars - 1; i++) WT_Update(g_wt, h[i], l[i], c[i]);
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

   if(!Proto_CanTrade(_Symbol)) return;

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

   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;

   double bar1High  = high[1];
   double bar1Low   = low[1];
   double bar1Close = close[1];
   double point     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipSize   = 10.0 * point;

   for(int i = 0; i < g_blockCount; i++) {
      if(!g_blocks[i].valid) continue;
      int age = (int)((TimeCurrent() - g_blocks[i].startTime) / PeriodSeconds(PERIOD_CURRENT));
      if(age > MaxZoneAgeBars) continue;
      double zoneHeight = g_blocks[i].top - g_blocks[i].bottom;
      if(zoneHeight <= 0) continue;

      if(g_blocks[i].type == 1) {
         double pctIn = ((g_blocks[i].top - bar1Low) / zoneHeight) * 100.0;
         if(pctIn < PenetrationPct) continue;
         if(bar1Close <= g_blocks[i].top) continue;

         // WT must be oversold
         if(g_wt.wt1 > -WTConfirmLevel) continue;

         double slPips = (bar1Close - g_blocks[i].bottom) / pipSize + SLBufferPips;
         SOrderBlock nearZone;
         double tpPips;
         bool found = SMC_FindNearestZone(g_blocks, g_blockCount, bar1Close, false, nearZone);
         if(found && nearZone.type == -1) {
            tpPips = (nearZone.bottom - bar1Close) / pipSize;
            if(tpPips < slPips * 0.5) tpPips = slPips * FallbackTPRatio;
         } else {
            tpPips = slPips * FallbackTPRatio;
         }
         Proto_Buy(_Symbol, slPips, tpPips, MagicNumber, "OBR_v2|B");
         return;
      }

      if(g_blocks[i].type == -1) {
         double pctIn = ((bar1High - g_blocks[i].bottom) / zoneHeight) * 100.0;
         if(pctIn < PenetrationPct) continue;
         if(bar1Close >= g_blocks[i].bottom) continue;

         // WT must be overbought
         if(g_wt.wt1 < WTConfirmLevel) continue;

         double slPips = (g_blocks[i].top - bar1Close) / pipSize + SLBufferPips;
         SOrderBlock nearZone;
         double tpPips;
         bool found = SMC_FindNearestZone(g_blocks, g_blockCount, bar1Close, true, nearZone);
         if(found && nearZone.type == 1) {
            tpPips = (bar1Close - nearZone.top) / pipSize;
            if(tpPips < slPips * 0.5) tpPips = slPips * FallbackTPRatio;
         } else {
            tpPips = slPips * FallbackTPRatio;
         }
         Proto_Sell(_Symbol, slPips, tpPips, MagicNumber, "OBR_v2|S");
         return;
      }
   }
}
//+------------------------------------------------------------------+
