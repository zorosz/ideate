//+------------------------------------------------------------------+
//| 0408_230000_dynamic_lots_v2.mq5                                  |
//| Combined hedge with dynamic lot sizing                            |
//| v2: Conservative (RiskPctPerLot=0.25)                |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <ND_Proto.mqh>

input int    HarvestPips            = 5;     // Per-position harvest (pips)
input int    MaxPositionsPerSide    = 6;     // Max positions per side
input int    BatchCloseMinPositions = 4;     // Min positions for batch close
input double RiskPctPerLot          = 0.25;   // Base lot as % of balance
input double IncrementRatio         = 0.5;   // LotIncrement = baseLot * this
input double MaxFloatingLossPct     = 4.0;   // Emergency kill (%)
input int    MagicNumber            = 408602;

double g_pipSize = 0;

int OnInit() {
   Proto_Init(MagicNumber);
   g_pipSize = 10.0 * _Point;
   if(CountByType(POSITION_TYPE_BUY) == 0 && CountByType(POSITION_TYPE_SELL) == 0) {
      double baseLot = CalcBaseLot();
      OpenAtLot(true, baseLot);
      OpenAtLot(false, baseLot);
   }
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason) {}

void OnTick() {
   if(CheckEmergencyKill()) return;
   if(Proto_IsInNoTradeWindow()) return;
   EnsureHedge();
   CheckHarvest();
   CheckBatchClose();
}

//+------------------------------------------------------------------+
double CalcBaseLot() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot = balance * RiskPctPerLot / 100.0 / 1000.0;
   return NormalizeLot(lot);
}

double CalcAccLot(int accCount) {
   double baseLot = CalcBaseLot();
   double lot = baseLot + (accCount * baseLot * IncrementRatio);
   return NormalizeLot(lot);
}

bool OpenAtLot(bool isBuy, double lots) {
   double normLot = NormalizeLot(lots);
   if(isBuy)
      return g_proto_trade.Buy(normLot, _Symbol, 0, 0, 0, "DL");
   else
      return g_proto_trade.Sell(normLot, _Symbol, 0, 0, 0, "DL");
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
      Proto_CloseAll(MagicNumber, _Symbol);
      return true;
   }
   return false;
}

void EnsureHedge() {
   if(CountByType(POSITION_TYPE_BUY) == 0) OpenAtLot(true, CalcBaseLot());
   if(CountByType(POSITION_TYPE_SELL) == 0) OpenAtLot(false, CalcBaseLot());
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

         // Winning side: always base lot
         OpenAtLot(type == POSITION_TYPE_BUY, CalcBaseLot());

         // Accumulated side: dynamic lot with increment, if under cap
         if(accCount < MaxPositionsPerSide)
            OpenAtLot(type != POSITION_TYPE_BUY, CalcAccLot(accCount));
         return;
      }
   }
}

void CheckBatchClose() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   int buyCount = 0, sellCount = 0;
   double buyPnl = 0, sellPnl = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_proto_position.SelectByIndex(i)) continue;
      if(g_proto_position.Magic() != MagicNumber || g_proto_position.Symbol() != _Symbol) continue;
      // Use actual dollar P&L for batch close (accounts for different lot sizes)
      double profit = g_proto_position.Profit() + g_proto_position.Swap();
      if(g_proto_position.PositionType() == POSITION_TYPE_BUY) {
         buyCount++; buyPnl += profit;
      } else {
         sellCount++; sellPnl += profit;
      }
   }

   if(buyCount >= BatchCloseMinPositions && buyPnl > 0) {
      CloseAllByType(POSITION_TYPE_BUY);
      OpenAtLot(true, CalcBaseLot());
   }
   if(sellCount >= BatchCloseMinPositions && sellPnl > 0) {
      CloseAllByType(POSITION_TYPE_SELL);
      OpenAtLot(false, CalcBaseLot());
   }
}
//+------------------------------------------------------------------+
