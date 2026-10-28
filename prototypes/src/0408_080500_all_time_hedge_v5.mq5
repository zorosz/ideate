//+------------------------------------------------------------------+
//| 0408_080500_all_time_hedge_v5.mq5                                |
//| Accumulating hedge — per-position harvest                         |
//| v5: No batch close — harvest only, emergency kill safety net     |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>

//--- Strategy inputs
input int    HarvestPips        = 30;    // Per-position harvest (pips)
input double MaxFloatingLossPct = 10.0;  // Emergency kill (% of balance)
input int    MagicNumber        = 408305; // Magic number

//--- Globals
double g_pipSize = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;
   if(CountByType(POSITION_TYPE_BUY) == 0 && CountByType(POSITION_TYPE_SELL) == 0) {
      OpenBuy(); OpenSell();
   }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason) {}
void OnTick() {
   if(CheckEmergencyKill()) return;
   if(Proto_IsInNoTradeWindow()) return;
   EnsureHedge();
   CheckHarvest();
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
