//+------------------------------------------------------------------+
//| 0408_080500_all_time_hedge_v4.mq5                                |
//| Accumulating hedge — per-position harvest                         |
//| v4: WaveTrend-based batch close                                  |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>
#include <WaveTrend.mqh>

//--- Strategy inputs
input int    HarvestPips        = 30;    // Per-position harvest (pips)
input int    WTChannel          = 10;    // WT channel length
input int    WTAverage          = 21;    // WT average length
input double WTOBLevel          = 53.0;  // WT overbought level
input double WTOSLevel          = -53.0; // WT oversold level
input double MaxFloatingLossPct = 10.0;  // Emergency kill (% of balance)
input int    MagicNumber        = 408304; // Magic number

//--- Globals
double g_pipSize = 0;
SWaveTrendState g_wt;
datetime g_lastBarTime = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;
   WT_Init(g_wt, WTChannel, WTAverage);

   // Seed WT with historical bars
   double h[], l[], c[];
   int bars = MathMin(200, Bars(_Symbol, PERIOD_M1));
   if(CopyHigh(_Symbol, PERIOD_M1, 1, bars, h) > 0 &&
      CopyLow(_Symbol, PERIOD_M1, 1, bars, l) > 0 &&
      CopyClose(_Symbol, PERIOD_M1, 1, bars, c) > 0) {
      for(int i = 0; i < bars; i++)
         WT_Update(g_wt, h[i], l[i], c[i]);
   }
   g_lastBarTime = iTime(_Symbol, PERIOD_M1, 0);

   if(CountByType(POSITION_TYPE_BUY) == 0 && CountByType(POSITION_TYPE_SELL) == 0) {
      OpenBuy(); OpenSell();
   }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason) {}

void OnTick() {
   // Update WT on new bar
   datetime barTime = iTime(_Symbol, PERIOD_M1, 0);
   if(barTime != g_lastBarTime) {
      g_lastBarTime = barTime;
      double h[1], l[1], c[1];
      if(CopyHigh(_Symbol, PERIOD_M1, 1, 1, h) > 0 &&
         CopyLow(_Symbol, PERIOD_M1, 1, 1, l) > 0 &&
         CopyClose(_Symbol, PERIOD_M1, 1, 1, c) > 0)
         WT_Update(g_wt, h[0], l[0], c[0]);
   }

   if(CheckEmergencyKill()) return;
   if(Proto_IsInNoTradeWindow()) return;
   EnsureHedge();
   CheckHarvest();
   CheckBatchCloseWT();
}

bool OpenBuy() {
   if(g_proto_trade.Buy(Proto_LotSize, _Symbol, 0, 0, 0, "ATH3")) return true;
   Print("BUY failed: ", g_proto_trade.ResultRetcodeDescription()); return false;
}
bool OpenSell() {
   if(g_proto_trade.Sell(Proto_LotSize, _Symbol, 0, 0, 0, "ATH3")) return true;
   Print("SELL failed: ", g_proto_trade.ResultRetcodeDescription()); return false;
}
int CountByType(ENUM_POSITION_TYPE type) {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == type) count++;
   }
   return count;
}
bool CheckEmergencyKill() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double loss    = balance - equity;
   if(balance > 0 && loss > 0 && (loss / balance * 100.0) >= MaxFloatingLossPct) {
      Proto_CloseAll(MagicNumber, _Symbol); return true;
   }
   return false;
}
void EnsureHedge() {
   if(CountByType(POSITION_TYPE_BUY) == 0) OpenBuy();
   if(CountByType(POSITION_TYPE_SELL) == 0) OpenSell();
}
void CheckHarvest() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      double op = g_proto_position.PriceOpen();
      double profitPips = (g_proto_position.PositionType() == POSITION_TYPE_BUY)
         ? (bid - op) / g_pipSize : (op - ask) / g_pipSize;
      if(profitPips >= HarvestPips) {
         g_proto_trade.PositionClose(g_proto_position.Ticket());
         OpenBuy(); OpenSell(); return;
      }
   }
}

//+------------------------------------------------------------------+
//| WT-based batch close: use WT cross in OS/OB zones                 |
//+------------------------------------------------------------------+
void CheckBatchCloseWT() {
   // Close accumulated BUYs when WT oversold + bull cross (reversal up)
   if(CountByType(POSITION_TYPE_BUY) > 1 &&
      WT_IsOversold(g_wt, WTOSLevel) && WT_BullCross(g_wt)) {
      CloseAllByType(POSITION_TYPE_BUY);
      OpenBuy();
   }
   // Close accumulated SELLs when WT overbought + bear cross (reversal down)
   if(CountByType(POSITION_TYPE_SELL) > 1 &&
      WT_IsOverbought(g_wt, WTOBLevel) && WT_BearCross(g_wt)) {
      CloseAllByType(POSITION_TYPE_SELL);
      OpenSell();
   }
}

void CloseAllByType(ENUM_POSITION_TYPE type) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == type)
         g_proto_trade.PositionClose(g_proto_position.Ticket());
   }
}
