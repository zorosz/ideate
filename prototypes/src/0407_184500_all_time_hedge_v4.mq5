//+------------------------------------------------------------------+
//|                     0407_184500_all_time_hedge_v4.mq5             |
//|         Continuous hedge + WT profit harvesting (30 pip + WT)     |
//+------------------------------------------------------------------+
#property copyright "New Dawn Proto"
#property version   "1.00"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

input int    WTChannel       = 10;    // WT Channel Length
input int    WTAverage        = 21;    // WT Average Length
input double WTOBLevel        = 53.0;  // WT Overbought Level
input double WTOSLevel        = -53.0; // WT Oversold Level
input double MinHarvestPips   = 15.0;  // Min profit pips to harvest
input int    MagicNumber      = 700004; // Magic Number

SWaveTrendState g_wt;
bool           g_warmedUp = false;
ulong          g_buyTicket = 0;
ulong          g_sellTicket = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   WT_Init(g_wt, WTChannel, WTAverage);
   g_warmedUp = false;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {}

void OnTick() {
   if(!g_warmedUp) {
      int bars = MathMin(Bars(_Symbol, PERIOD_CURRENT), 500);
      if(bars < 50) return;
      double h[], l[], c[];
      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, bars, h) <= 0) return;
      if(CopyLow(_Symbol, PERIOD_CURRENT, 0, bars, l) <= 0) return;
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, c) <= 0) return;
      WT_Init(g_wt, WTChannel, WTAverage);
      for(int i = 0; i < bars - 1; i++) WT_Update(g_wt, h[i], l[i], c[i]);
      g_warmedUp = true;
      g_proto_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      return;
   }

   if(!Proto_IsNewBar(_Symbol, PERIOD_CURRENT)) return;

   // Feed WT
   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double c1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   if(h1 > 0 && l1 > 0 && c1 > 0) WT_Update(g_wt, h1, l1, c1);

   // Ensure both legs exist
   EnsureLegs();

   // No-trade window: don't harvest
   if(Proto_IsInNoTradeWindow()) return;

   // Harvest logic
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipSize = 10.0 * point;
   double minDist = MinHarvestPips * pipSize;

   // Check BUY leg
   if(g_buyTicket > 0 && PositionSelectByTicket(g_buyTicket)) {
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double profit = bid - entry;
      if(profit >= minDist && WT_IsOverbought(g_wt, WTOBLevel) && WT_BearCross(g_wt)) {
         g_proto_trade.PositionClose(g_buyTicket);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(g_proto_trade.Buy(Proto_LotSize, _Symbol, ask, 0, 0, "ATH|B")) {
            g_buyTicket = FindTicket(POSITION_TYPE_BUY);
            PrintFormat("HARVEST BUY: closed +%.1f pips, reopened", profit / pipSize);
         }
      }
   }

   // Check SELL leg
   if(g_sellTicket > 0 && PositionSelectByTicket(g_sellTicket)) {
      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double profit = entry - ask;
      if(profit >= minDist && WT_IsOversold(g_wt, WTOSLevel) && WT_BullCross(g_wt)) {
         g_proto_trade.PositionClose(g_sellTicket);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(g_proto_trade.Sell(Proto_LotSize, _Symbol, bid, 0, 0, "ATH|S")) {
            g_sellTicket = FindTicket(POSITION_TYPE_SELL);
            PrintFormat("HARVEST SELL: closed +%.1f pips, reopened", profit / pipSize);
         }
      }
   }
}

void EnsureLegs() {
   // Check BUY exists
   if(g_buyTicket > 0 && !PositionSelectByTicket(g_buyTicket)) g_buyTicket = 0;
   if(g_buyTicket == 0) {
      g_buyTicket = FindTicket(POSITION_TYPE_BUY);
      if(g_buyTicket == 0) {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(g_proto_trade.Buy(Proto_LotSize, _Symbol, ask, 0, 0, "ATH|B"))
            g_buyTicket = FindTicket(POSITION_TYPE_BUY);
      }
   }
   // Check SELL exists
   if(g_sellTicket > 0 && !PositionSelectByTicket(g_sellTicket)) g_sellTicket = 0;
   if(g_sellTicket == 0) {
      g_sellTicket = FindTicket(POSITION_TYPE_SELL);
      if(g_sellTicket == 0) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(g_proto_trade.Sell(Proto_LotSize, _Symbol, bid, 0, 0, "ATH|S"))
            g_sellTicket = FindTicket(POSITION_TYPE_SELL);
      }
   }
}

ulong FindTicket(ENUM_POSITION_TYPE type) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == type)
         return g_proto_position.Ticket();
   }
   return 0;
}
//+------------------------------------------------------------------+
