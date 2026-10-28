//+------------------------------------------------------------------+
//| 0408_210740_accumulating_hedge_pure_distance_v2.mq5              |
//| Trend protection — increasing harvest distance                    |
//| Each consecutive same-direction harvest increases the distance    |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>

input int    HarvestPips           = 60;   // Base harvest distance (pips)
input int    HarvestIncrement      = 30;   // Increment per consecutive harvest (pips)
input int    BatchClosePips        = 70;   // Batch close threshold (pips)
input double MaxFloatingLossPct    = 5.0;  // Emergency kill (%)
input int    MagicNumber           = 408402;

double g_lastHarvestPrice = 0;
double g_pipSize = 0;
int    g_consecutiveHarvests = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;
   g_lastHarvestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(CountByType(POSITION_TYPE_BUY) == 0 && CountByType(POSITION_TYPE_SELL) == 0) {
      OpenBuy(); OpenSell();
   }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason) {}
void OnTick() {
   if(CheckEmergencyKill()) return;
   if(Proto_IsInNoTradeWindow()) return;
   EnsureHedge(); CheckHarvest(); CheckBatchClose();
}

bool OpenBuy() {
   if(g_proto_trade.Buy(Proto_LotSize, _Symbol, 0, 0, 0, "TPv2")) return true;
   return false;
}
bool OpenSell() {
   if(g_proto_trade.Sell(Proto_LotSize, _Symbol, 0, 0, 0, "TPv2")) return true;
   return false;
}
int CountByType(ENUM_POSITION_TYPE type) {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber || g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == type) count++;
   }
   return count;
}
bool CheckEmergencyKill() {
   double bal = AccountInfoDouble(ACCOUNT_BALANCE), eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double loss = bal - eq;
   if(bal > 0 && loss > 0 && (loss / bal * 100.0) >= MaxFloatingLossPct) {
      Proto_CloseAll(MagicNumber, _Symbol); return true;
   }
   return false;
}
void EnsureHedge() {
   if(CountByType(POSITION_TYPE_BUY) == 0) OpenBuy();
   if(CountByType(POSITION_TYPE_SELL) == 0) OpenSell();
}
void CloseAllByType(ENUM_POSITION_TYPE type) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber || g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == type)
         g_proto_trade.PositionClose(g_proto_position.Ticket());
   }
}

void CheckHarvest() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentDist = (HarvestPips + g_consecutiveHarvests * HarvestIncrement) * g_pipSize;

   if(bid >= g_lastHarvestPrice + currentDist) {
      CloseAllByType(POSITION_TYPE_BUY);
      OpenBuy(); OpenSell();
      g_lastHarvestPrice = bid;
      g_consecutiveHarvests++;
      return;
   }
   if(bid <= g_lastHarvestPrice - currentDist) {
      CloseAllByType(POSITION_TYPE_SELL);
      OpenBuy(); OpenSell();
      g_lastHarvestPrice = bid;
      g_consecutiveHarvests++;
      return;
   }
}

void CheckBatchClose() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   int buyCount = 0, sellCount = 0;
   double buyPips = 0, sellPips = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber || g_proto_position.Symbol() != _Symbol) continue;
      double op = g_proto_position.PriceOpen();
      if(g_proto_position.PositionType() == POSITION_TYPE_BUY) {
         buyCount++; buyPips += (bid - op) / g_pipSize;
      } else {
         sellCount++; sellPips += (op - ask) / g_pipSize;
      }
   }
   if(buyCount > 1 && buyPips > BatchClosePips) {
      CloseAllByType(POSITION_TYPE_BUY); OpenBuy();
      g_consecutiveHarvests = 0; // Reset on batch close
   }
   if(sellCount > 1 && sellPips > BatchClosePips) {
      CloseAllByType(POSITION_TYPE_SELL); OpenSell();
      g_consecutiveHarvests = 0;
   }
}
