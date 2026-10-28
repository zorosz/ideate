//+------------------------------------------------------------------+
//| 0408_232000_session_trailing_v4.mq5                              |
//| Session filter + trailing batch close                             |
//| v4: Extended session (07:00-22:00)          |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>

input int    HarvestPips            = 5;     // Per-position harvest (pips)
input int    MaxPositionsPerSide    = 6;     // Max positions per side
input int    BatchCloseMinPositions = 4;     // Min positions for batch close
input double LotIncrement           = 0.025; // Lot increase per accumulated pos
input double MaxFloatingLossPct     = 4.0;   // Emergency kill (%)
input int    SessionStartHour       = 7;     // Session start hour (broker time)
input int    SessionEndHour         = 22;    // Session end hour (broker time)
input int    MagicNumber            = 408704;

double g_pipSize = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;
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
   EnsureHedge();
   // Harvest ONLY during active session
   if(IsInSession())
      CheckHarvest();
   // Batch close runs 24/7
   CheckBatchClose();
}

//+------------------------------------------------------------------+
bool IsInSession() {
   MqlDateTime now;
   TimeCurrent(now);
   if(SessionStartHour < SessionEndHour)
      return (now.hour >= SessionStartHour && now.hour < SessionEndHour);
   else
      return (now.hour >= SessionStartHour || now.hour < SessionEndHour);
}

bool OpenAtLot(bool isBuy, double lots) {
   double normLot = NormalizeLot(lots);
   if(isBuy)
      return g_proto_trade.Buy(normLot, _Symbol, 0, 0, 0, "ST");
   else
      return g_proto_trade.Sell(normLot, _Symbol, 0, 0, 0, "ST");
}

double NormalizeLot(double lots) {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(lotStep > 0) lots = MathFloor(lots / lotStep) * lotStep;
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
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber || g_proto_position.Symbol() != _Symbol) continue;
      double op = g_proto_position.PriceOpen();
      ENUM_POSITION_TYPE type = g_proto_position.PositionType();
      double profitPips = (type == POSITION_TYPE_BUY)
         ? (bid - op) / g_pipSize : (op - ask) / g_pipSize;
      if(profitPips >= HarvestPips) {
         CloseAllByType(type);
         ENUM_POSITION_TYPE accSide = (type == POSITION_TYPE_BUY)
            ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
         int accCount = CountByType(accSide);
         OpenAtLot(type == POSITION_TYPE_BUY, Proto_LotSize);
         if(accCount < MaxPositionsPerSide) {
            double accLot = Proto_LotSize + accCount * LotIncrement;
            OpenAtLot(type != POSITION_TYPE_BUY, accLot);
         }
         return;
      }
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
   if(buyCount >= BatchCloseMinPositions && buyPips > 0) {
      CloseAllByType(POSITION_TYPE_BUY); OpenAtLot(true, Proto_LotSize);
   }
   if(sellCount >= BatchCloseMinPositions && sellPips > 0) {
      CloseAllByType(POSITION_TYPE_SELL); OpenAtLot(false, Proto_LotSize);
   }
}
//+------------------------------------------------------------------+
