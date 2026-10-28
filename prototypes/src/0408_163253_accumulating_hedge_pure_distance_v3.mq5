//+------------------------------------------------------------------+
//| 0408_163253_accumulating_hedge_pure_distance_v3.mq5              |
//| Accumulating hedge — pure distance, no indicators                 |
//| v3: HarvestPips=150 (wider harvest)                              |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>

//--- Strategy inputs
input int    HarvestPips        = 150;   // Harvest distance (pips)
input int    BatchClosePips     = 10;    // Batch close threshold (pips)
input double MaxFloatingLossPct = 10.0;  // Emergency kill (% of balance)
input int    MagicNumber        = 408103; // Magic number

//--- Globals
double g_lastHarvestPrice = 0;
ulong  g_lastBuyTicket    = 0;
ulong  g_lastSellTicket   = 0;
double g_pipSize          = 0;

//+------------------------------------------------------------------+
int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;

   if(CountByType(POSITION_TYPE_BUY) == 0 && CountByType(POSITION_TYPE_SELL) == 0) {
      g_lastHarvestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      OpenBuy();
      OpenSell();
   } else {
      g_lastHarvestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      FindLastTickets();
   }
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
void OnTick() {
   if(CheckEmergencyKill()) return;
   if(Proto_IsInNoTradeWindow()) return;
   EnsureHedge();
   CheckHarvest();
   CheckBatchClose();
}

//+------------------------------------------------------------------+
bool OpenBuy() {
   if(g_proto_trade.Buy(Proto_LotSize, _Symbol, 0, 0, 0, "AHPD")) {
      g_lastBuyTicket = g_proto_trade.ResultOrder();
      return true;
   }
   Print("BUY failed: ", g_proto_trade.ResultRetcodeDescription());
   return false;
}

//+------------------------------------------------------------------+
bool OpenSell() {
   if(g_proto_trade.Sell(Proto_LotSize, _Symbol, 0, 0, 0, "AHPD")) {
      g_lastSellTicket = g_proto_trade.ResultOrder();
      return true;
   }
   Print("SELL failed: ", g_proto_trade.ResultRetcodeDescription());
   return false;
}

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
void FindLastTickets() {
   datetime lastBuyTime = 0, lastSellTime = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == POSITION_TYPE_BUY) {
         if(g_proto_position.Time() > lastBuyTime) {
            lastBuyTime = g_proto_position.Time();
            g_lastBuyTicket = g_proto_position.Ticket();
         }
      } else {
         if(g_proto_position.Time() > lastSellTime) {
            lastSellTime = g_proto_position.Time();
            g_lastSellTicket = g_proto_position.Ticket();
         }
      }
   }
}

//+------------------------------------------------------------------+
bool CheckEmergencyKill() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double loss    = balance - equity;
   if(balance > 0 && loss > 0 && (loss / balance * 100.0) >= MaxFloatingLossPct) {
      Print("EMERGENCY KILL: ", DoubleToString(loss / balance * 100.0, 1), "%");
      Proto_CloseAll(MagicNumber, _Symbol);
      g_lastBuyTicket = 0;
      g_lastSellTicket = 0;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void EnsureHedge() {
   if(CountByType(POSITION_TYPE_BUY) == 0) {
      OpenBuy();
      if(g_lastHarvestPrice == 0)
         g_lastHarvestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
   if(CountByType(POSITION_TYPE_SELL) == 0) {
      OpenSell();
      if(g_lastHarvestPrice == 0)
         g_lastHarvestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
}

//+------------------------------------------------------------------+
void CheckHarvest() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double harvestDist = HarvestPips * g_pipSize;

   if(bid >= g_lastHarvestPrice + harvestDist) {
      if(g_lastBuyTicket > 0)
         g_proto_trade.PositionClose(g_lastBuyTicket);
      OpenBuy();
      OpenSell();
      g_lastHarvestPrice = bid;
      return;
   }

   if(bid <= g_lastHarvestPrice - harvestDist) {
      if(g_lastSellTicket > 0)
         g_proto_trade.PositionClose(g_lastSellTicket);
      OpenBuy();
      OpenSell();
      g_lastHarvestPrice = bid;
      return;
   }
}

//+------------------------------------------------------------------+
void CheckBatchClose() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   int buyCount = 0, sellCount = 0;
   double buyPips = 0, sellPips = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      double op = g_proto_position.PriceOpen();
      if(g_proto_position.PositionType() == POSITION_TYPE_BUY) {
         buyCount++;
         buyPips += (bid - op) / g_pipSize;
      } else {
         sellCount++;
         sellPips += (op - ask) / g_pipSize;
      }
   }

   if(buyCount > 1 && buyPips > BatchClosePips) {
      CloseAllByType(POSITION_TYPE_BUY);
      OpenBuy();
   }
   if(sellCount > 1 && sellPips > BatchClosePips) {
      CloseAllByType(POSITION_TYPE_SELL);
      OpenSell();
   }
}

//+------------------------------------------------------------------+
void CloseAllByType(ENUM_POSITION_TYPE type) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber) continue;
      if(g_proto_position.Symbol() != _Symbol) continue;
      if(g_proto_position.PositionType() == type)
         g_proto_trade.PositionClose(g_proto_position.Ticket());
   }
}
//+------------------------------------------------------------------+
