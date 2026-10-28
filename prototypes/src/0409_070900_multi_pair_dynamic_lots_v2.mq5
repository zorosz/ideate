//+------------------------------------------------------------------+
//| 0409_070900_multi_pair_dynamic_lots_v2.mq5                       |
//| Single EA, multi-pair accumulating hedge with dynamic lots        |
//| v2: EURUSD + USDJPY only, RiskPctPerLot=0.14    |
//+------------------------------------------------------------------+
#property copyright "New Dawn"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Pair configuration
input string Pair1              = "EURUSD";  // First pair
input string Pair2              = "";  // Second pair (empty=off)
input string Pair3              = "USDJPY";  // Third pair (empty=off)
input int    BaseMagic          = 408510;    // Base magic (+1,+2,+3 per pair)

//--- Strategy parameters
input double HarvestPips           = 5;      // Per-position harvest (pips)
input int    MaxPositionsPerSide   = 6;      // Cap per pair per side
input int    BatchCloseMinPositions = 4;     // Min positions for batch close
input double RiskPctPerLot         = 0.14;   // Total risk %, auto-split
input double IncrementRatio        = 1.0;    // Lot increment multiplier
input double MaxLotSize            = 1.0;    // Max lot per position
input double MaxFloatingLossPct    = 4.0;    // Emergency kill — ALL pairs
input bool   SplitRisk             = true;   // Split risk by pair count

//--- Time filter
input int    NoTradeStartHour      = 23;     // No-harvest start hour
input int    NoTradeEndHour        = 0;      // No-harvest end hour

//+------------------------------------------------------------------+
//| PairState — per-pair independent state                            |
//+------------------------------------------------------------------+
struct PairState {
   string   symbol;
   int      magicNumber;
   double   pipSize;       // 1 pip in price terms (handles JPY)
   bool     active;
};

//--- Globals
PairState      g_pairs[3];
int            g_activePairCount = 0;
CTrade         g_trade;
CPositionInfo  g_pos;

//+------------------------------------------------------------------+
//| Initialize a single pair                                          |
//+------------------------------------------------------------------+
void InitPair(PairState &ps, string sym, int magic) {
   ps.symbol = sym;
   ps.magicNumber = magic;
   ps.active = (sym != "" && sym != "NULL");
   ps.pipSize = 0;

   if(ps.active) {
      // Ensure symbol is in Market Watch for tester
      SymbolSelect(sym, true);
      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double point = SymbolInfoDouble(sym, SYMBOL_POINT);
      // 3 or 5 digit broker: 1 pip = 10 points
      // 2 or 4 digit broker: 1 pip = 1 point
      if(digits == 3 || digits == 5)
         ps.pipSize = point * 10.0;
      else
         ps.pipSize = point;
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit() {
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);

   InitPair(g_pairs[0], Pair1, BaseMagic + 1);
   InitPair(g_pairs[1], Pair2, BaseMagic + 2);
   InitPair(g_pairs[2], Pair3, BaseMagic + 3);

   g_activePairCount = 0;
   for(int i = 0; i < 3; i++)
      if(g_pairs[i].active) g_activePairCount++;

   if(g_activePairCount == 0) {
      Print("ERROR: no active pairs configured");
      return INIT_FAILED;
   }

   // Open initial hedge on each pair
   for(int i = 0; i < 3; i++) {
      if(!g_pairs[i].active) continue;
      if(CountByType(g_pairs[i], POSITION_TYPE_BUY) == 0 &&
         CountByType(g_pairs[i], POSITION_TYPE_SELL) == 0) {
         double lot = CalcBaseLot();
         g_trade.SetExpertMagicNumber(g_pairs[i].magicNumber);
         OpenBuy(g_pairs[i], lot);
         OpenSell(g_pairs[i], lot);
      }
   }
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

//+------------------------------------------------------------------+
//| OnTick — orchestrator                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // Combined emergency kill across ALL pairs
   if(CheckCombinedEmergencyKill()) return;

   bool noTrade = IsInNoTradeWindow();

   for(int i = 0; i < 3; i++) {
      if(!g_pairs[i].active) continue;
      g_trade.SetExpertMagicNumber(g_pairs[i].magicNumber);

      EnsureHedge(g_pairs[i]);

      if(!noTrade) {
         CheckHarvest(g_pairs[i]);
         CheckBatchClose(g_pairs[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Dynamic lot sizing — shared balance, split by pair count          |
//+------------------------------------------------------------------+
double CalcBaseLot() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskPct = RiskPctPerLot;
   if(SplitRisk && g_activePairCount > 0)
      riskPct = RiskPctPerLot / g_activePairCount;
   double lot = balance * riskPct / 100.0 / 1000.0;
   return NormLot(lot, _Symbol); // use chart symbol for normalization
}

double CalcAccLot(int accCount) {
   double baseLot = CalcBaseLot();
   double lot = baseLot + (accCount * baseLot * IncrementRatio);
   return NormLot(lot, _Symbol);
}

double NormLot(double lots, string sym) {
   double minLot  = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(lotStep > 0) lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   if(lots > MaxLotSize) lots = MaxLotSize;
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Position management — per pair via magic number                   |
//+------------------------------------------------------------------+
int CountByType(const PairState &ps, ENUM_POSITION_TYPE type) {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Magic() != ps.magicNumber || g_pos.Symbol() != ps.symbol) continue;
      if(g_pos.PositionType() == type) count++;
   }
   return count;
}

void CloseAllByType(const PairState &ps, ENUM_POSITION_TYPE type) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Magic() != ps.magicNumber || g_pos.Symbol() != ps.symbol) continue;
      if(g_pos.PositionType() == type)
         g_trade.PositionClose(g_pos.Ticket());
   }
}

void CloseAllPair(const PairState &ps) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Magic() != ps.magicNumber || g_pos.Symbol() != ps.symbol) continue;
      g_trade.PositionClose(g_pos.Ticket());
   }
}

bool OpenBuy(const PairState &ps, double lots) {
   double normLot = NormLot(lots, ps.symbol);
   return g_trade.Buy(normLot, ps.symbol, 0, 0, 0, "MPH");
}

bool OpenSell(const PairState &ps, double lots) {
   double normLot = NormLot(lots, ps.symbol);
   return g_trade.Sell(normLot, ps.symbol, 0, 0, 0, "MPH");
}

//+------------------------------------------------------------------+
//| Time filter                                                       |
//+------------------------------------------------------------------+
bool IsInNoTradeWindow() {
   MqlDateTime now;
   TimeCurrent(now);
   if(NoTradeStartHour > NoTradeEndHour)
      return (now.hour >= NoTradeStartHour || now.hour < NoTradeEndHour);
   else if(NoTradeStartHour < NoTradeEndHour)
      return (now.hour >= NoTradeStartHour && now.hour < NoTradeEndHour);
   return false; // start == end means no window
}

//+------------------------------------------------------------------+
//| Combined emergency kill — ALL pairs total floating loss           |
//+------------------------------------------------------------------+
bool CheckCombinedEmergencyKill() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double totalLoss = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_pos.SelectByIndex(i)) continue;
      // Check if this position belongs to ANY of our pairs
      bool ours = false;
      for(int p = 0; p < 3; p++) {
         if(g_pairs[p].active && g_pos.Magic() == g_pairs[p].magicNumber
            && g_pos.Symbol() == g_pairs[p].symbol) {
            ours = true;
            break;
         }
      }
      if(!ours) continue;

      double pnl = g_pos.Profit() + g_pos.Swap();
      if(pnl < 0) totalLoss += MathAbs(pnl);
   }

   if(balance > 0 && totalLoss > 0 && (totalLoss / balance * 100.0) >= MaxFloatingLossPct) {
      PrintFormat("EMERGENCY KILL: combined loss %.2f (%.1f%%) across all pairs",
                  totalLoss, totalLoss / balance * 100.0);
      for(int p = 0; p < 3; p++) {
         if(!g_pairs[p].active) continue;
         g_trade.SetExpertMagicNumber(g_pairs[p].magicNumber);
         CloseAllPair(g_pairs[p]);
      }
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Ensure at least 1 BUY + 1 SELL per pair                          |
//+------------------------------------------------------------------+
void EnsureHedge(const PairState &ps) {
   if(CountByType(ps, POSITION_TYPE_BUY) == 0)
      OpenBuy(ps, CalcBaseLot());
   if(CountByType(ps, POSITION_TYPE_SELL) == 0)
      OpenSell(ps, CalcBaseLot());
}

//+------------------------------------------------------------------+
//| Per-position harvest — any position at HarvestPips profit         |
//| Close ALL winning side, open replacement + accumulated (with cap) |
//+------------------------------------------------------------------+
void CheckHarvest(const PairState &ps) {
   double bid = SymbolInfoDouble(ps.symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(ps.symbol, SYMBOL_ASK);
   if(bid == 0 || ask == 0) return; // no price data

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Magic() != ps.magicNumber || g_pos.Symbol() != ps.symbol) continue;

      double op = g_pos.PriceOpen();
      ENUM_POSITION_TYPE type = g_pos.PositionType();
      double profitPips = (type == POSITION_TYPE_BUY)
         ? (bid - op) / ps.pipSize : (op - ask) / ps.pipSize;

      if(profitPips >= HarvestPips) {
         // Close ALL positions on winning side
         CloseAllByType(ps, type);

         // Determine accumulated (losing) side
         ENUM_POSITION_TYPE accSide = (type == POSITION_TYPE_BUY)
            ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
         int accCount = CountByType(ps, accSide);

         // Winning side: always base lot
         if(type == POSITION_TYPE_BUY)
            OpenBuy(ps, CalcBaseLot());
         else
            OpenSell(ps, CalcBaseLot());

         // Accumulated side: dynamic lot, if under cap
         if(accCount < MaxPositionsPerSide) {
            if(accSide == POSITION_TYPE_BUY)
               OpenBuy(ps, CalcAccLot(accCount));
            else
               OpenSell(ps, CalcAccLot(accCount));
         }
         return; // one harvest per tick per pair
      }
   }
}

//+------------------------------------------------------------------+
//| Count-based batch close: count >= min AND total P&L > 0           |
//| Uses dollar P&L (accounts for different lot sizes)                |
//+------------------------------------------------------------------+
void CheckBatchClose(const PairState &ps) {
   int buyCount = 0, sellCount = 0;
   double buyPnl = 0, sellPnl = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Magic() != ps.magicNumber || g_pos.Symbol() != ps.symbol) continue;
      double pnl = g_pos.Profit() + g_pos.Swap();
      if(g_pos.PositionType() == POSITION_TYPE_BUY) {
         buyCount++; buyPnl += pnl;
      } else {
         sellCount++; sellPnl += pnl;
      }
   }

   if(buyCount >= BatchCloseMinPositions && buyPnl > 0) {
      CloseAllByType(ps, POSITION_TYPE_BUY);
      OpenBuy(ps, CalcBaseLot());
   }
   if(sellCount >= BatchCloseMinPositions && sellPnl > 0) {
      CloseAllByType(ps, POSITION_TYPE_SELL);
      OpenSell(ps, CalcBaseLot());
   }
}
//+------------------------------------------------------------------+
