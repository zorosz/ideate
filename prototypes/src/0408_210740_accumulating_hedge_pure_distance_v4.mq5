//+------------------------------------------------------------------+
//| 0408_210740_accumulating_hedge_pure_distance_v4.mq5              |
//| Trend protection — increasing lot size on accumulated side        |
//| Martingale-like: larger lots recover faster but amplify risk      |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>

input int    HarvestPips           = 60;    // Harvest distance (pips)
input int    BatchClosePips        = 70;    // Batch close threshold (pips)
input double LotIncrement          = 0.01;  // Lot increase per accumulated position
input double MaxFloatingLossPct    = 5.0;   // Emergency kill (%)
input int    MagicNumber           = 408404;

double g_lastHarvestPrice = 0;
double g_pipSize = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;
   g_lastHarvestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(CountByType(POSITION_TYPE_BUY) == 0 && CountByType(POSITION_TYPE_SELL) == 0) {
      OpenAtLot(true, Proto_LotSize);
      OpenAtLot(false, Proto_LotSize);
   }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason) {}
void OnTick() {
   if(CheckEmergencyKill()) return;
   if(Proto_IsInNoTradeWindow()) return;
   EnsureHedge(); CheckHarvest(); CheckBatchClose();
}

bool OpenAtLot(bool isBuy, double lots) {
   double normLot = NormalizeLot(lots);
   if(isBuy) {
      if(g_proto_trade.Buy(normLot, _Symbol, 0, 0, 0, "TPv4")) return true;
   } else {
      if(g_proto_trade.Sell(normLot, _Symbol, 0, 0, 0, "TPv4")) return true;
   }
   return false;
}

double NormalizeLot(double lots) {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   return NormalizeDouble(lots, 2);
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
   if(CountByType(POSITION_TYPE_BUY) == 0) OpenAtLot(true, Proto_LotSize);
   if(CountByType(POSITION_TYPE_SELL) == 0) OpenAtLot(false, Proto_LotSize);
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
   double harvestDist = HarvestPips * g_pipSize;

   if(bid >= g_lastHarvestPrice + harvestDist) {
      // BUYs win, SELLs accumulate
      int accCount = CountByType(POSITION_TYPE_SELL);
      CloseAllByType(POSITION_TYPE_BUY);
      OpenAtLot(true, Proto_LotSize); // winning side: base lot
      double accLot = Proto_LotSize + accCount * LotIncrement;
      OpenAtLot(false, accLot); // accumulated side: increasing lot
      g_lastHarvestPrice = bid;
      return;
   }
   if(bid <= g_lastHarvestPrice - harvestDist) {
      // SELLs win, BUYs accumulate
      int accCount = CountByType(POSITION_TYPE_BUY);
      CloseAllByType(POSITION_TYPE_SELL);
      OpenAtLot(false, Proto_LotSize);
      double accLot = Proto_LotSize + accCount * LotIncrement;
      OpenAtLot(true, accLot);
      g_lastHarvestPrice = bid;
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
      CloseAllByType(POSITION_TYPE_BUY); OpenAtLot(true, Proto_LotSize);
   }
   if(sellCount > 1 && sellPips > BatchClosePips) {
      CloseAllByType(POSITION_TYPE_SELL); OpenAtLot(false, Proto_LotSize);
   }
}
