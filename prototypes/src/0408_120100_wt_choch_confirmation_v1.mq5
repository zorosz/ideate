//+------------------------------------------------------------------+
//|              0408_120100_wt_choch_confirmation_v1.mq5             |
//|     WaveTrend + CHoCH Confirmation — base (M1 cross + M1 CHoCH)   |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <SMC_Core.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    SwingLength    = 30;       // SMC swing length (bars)
input int    MaxChochAge    = 20;       // Max bars since CHoCH
input int    WTChannel      = 10;       // WT channel length
input int    WTAverage      = 21;       // WT average length
input double WT_OB          = 53.0;     // Overbought level (validated baseline)
input double WT_OS          = -53.0;    // Oversold level
input int    ATR_Period     = 14;
input double SL_ATR         = 1.5;
input double TP_ATR         = 2.5;
input double TrailTrigger   = 1.0;
input int    MagicNumber    = 412001;

//--- State
int             g_atrHandle = INVALID_HANDLE;
SSMCState       g_smcState;
SSwingPoint     g_swings[];
int             g_swingCount = 0;
SOrderBlock     g_blocks[];
int             g_blockCount = 0;
SStructureBreak g_breaks[];
int             g_breakCount = 0;

SWaveTrendState g_wt;
bool            g_warmedUp = false;
bool            g_breakEvenSet = false;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   SMC_Init(g_smcState);
   WT_Init(g_wt, WTChannel, WTAverage);
   g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
   if(g_atrHandle == INVALID_HANDLE) return INIT_FAILED;
   g_warmedUp = false;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if(g_atrHandle != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
void WarmUp() {
   int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
   if(bars < 100) return;

   double high[], low[], close[];
   if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, high)   <= 0) return;
   if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, low)     <= 0) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, close) <= 0) return;

   WT_Init(g_wt, WTChannel, WTAverage);
   for(int i = bars - 1; i >= 1; i--)
      WT_Update(g_wt, high[i], low[i], close[i]);

   g_warmedUp = true;
   g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   PrintFormat("WTCH v1 warmed up: %d bars, wt1=%.2f wt2=%.2f", bars - 1, g_wt.wt1, g_wt.wt2);
}

//+------------------------------------------------------------------+
void ManageBreakeven() {
   if(g_breakEvenSet) return;

   double atrBuf[1];
   if(CopyBuffer(g_atrHandle, 0, 1, 1, atrBuf) <= 0) return;
   double trailDist = atrBuf[0] * TrailTrigger;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;

      double openPrice = g_proto_position.PriceOpen();
      double currentSL = g_proto_position.StopLoss();
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double tp  = g_proto_position.TakeProfit();

      if(g_proto_position.PositionType() == POSITION_TYPE_BUY) {
         if(bid - openPrice >= trailDist && currentSL < openPrice) {
            g_proto_trade.PositionModify(g_proto_position.Ticket(), openPrice, tp);
            g_breakEvenSet = true;
         }
      } else {
         if(openPrice - ask >= trailDist && (currentSL > openPrice || currentSL == 0)) {
            g_proto_trade.PositionModify(g_proto_position.Ticket(), openPrice, tp);
            g_breakEvenSet = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
void OnTick() {
   if(!g_warmedUp) {
      WarmUp();
      return;
   }

   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) {
      ManageBreakeven();
   }

   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   if(Proto_CountPositions(MagicNumber, _Symbol) > 0) return;
   g_breakEvenSet = false;

   // Feed completed Bar[1] to WT
   double h = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(h <= 0 || l <= 0 || c <= 0) return;
   WT_Update(g_wt, h, l, c);

   if(!Proto_CanTrade(_Symbol)) return;

   // Load bars for SMC
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

   SMC_Update(high, low, close, atr, time, SwingLength, 0,
              g_smcState, g_swings, g_swingCount,
              g_blocks, g_blockCount, g_breaks, g_breakCount);

   // Validated WT signal
   bool bullSignal = WT_IsOversold(g_wt, WT_OS) && WT_BullCross(g_wt);
   bool bearSignal = WT_IsOverbought(g_wt, WT_OB) && WT_BearCross(g_wt);

   if(!bullSignal && !bearSignal) return;

   // Find most recent CHoCH within MaxChochAge bars
   // POLARITY NOTE: empirically on M1, the most recent CHoCH at WT
   // extreme is OPPOSITE direction (CHoCH confirms the move that just
   // exhausted, not the new direction). So:
   //   BUY (WT oversold cross) requires BEARISH CHoCH (down-move exhausted)
   //   SELL (WT overbought cross) requires BULLISH CHoCH (up-move exhausted)
   bool chochFound = false;
   bool chochBullish = false;
   datetime now = time[0];
   int periodSec = PeriodSeconds(PERIOD_CURRENT);
   if(periodSec <= 0) periodSec = 60;

   for(int i = g_breakCount - 1; i >= 0; i--) {
      if(!g_breaks[i].isChoch) continue;
      int ageBars = (int)((now - g_breaks[i].breakTime) / periodSec);
      if(ageBars > MaxChochAge) break;
      chochFound = true;
      chochBullish = g_breaks[i].isBullish;
      break;
   }

   if(!chochFound) return;

   // Inverted polarity check (see note above)
   if(bullSignal && chochBullish) return;     // BUY needs BEARISH CHoCH
   if(bearSignal && !chochBullish) return;    // SELL needs BULLISH CHoCH

   // Calculate SL/TP from ATR
   double atrValue = atr[1];
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipSize = 10.0 * point;
   double slPips = (atrValue * SL_ATR) / pipSize;
   double tpPips = (atrValue * TP_ATR) / pipSize;
   if(slPips < 5.0) slPips = 5.0;
   if(tpPips < 5.0) tpPips = 5.0;

   if(bullSignal) {
      Proto_Buy(_Symbol, slPips, tpPips, MagicNumber, "WTCH_v1|B");
   } else {
      Proto_Sell(_Symbol, slPips, tpPips, MagicNumber, "WTCH_v1|S");
   }
}
//+------------------------------------------------------------------+
