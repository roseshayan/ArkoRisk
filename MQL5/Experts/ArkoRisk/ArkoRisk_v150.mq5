#property copyright "Shayan Namayandeh (SudoShayanNA) — ArkoRisk"
#property link      "https://github.com/roseshayan/ArkoRisk"
#property version   "1.50"
#property strict
#property icon      "\\Images\\ArkoRisk\\ArkoRisk.ico"
#property description "ArkoRisk MT5 v1.50 — runtime management, smart break-even, Tehran day guard and journal"

// The proven v1.40 engine is compiled as the core. Standard event handlers are
// renamed so v1.50 can route execution through runtime-aware guards/management.
#define OnInit             ArkoCore_OnInit
#define OnDeinit           ArkoCore_OnDeinit
#define OnTick             ArkoCore_OnTick
#define OnTimer            ArkoCore_OnTimer
#define OnTradeTransaction ArkoCore_OnTradeTransaction
#define OnChartEvent       ArkoCore_OnChartEvent
#include "ArkoRiskCore.mqh"
#undef OnInit
#undef OnDeinit
#undef OnTick
#undef OnTimer
#undef OnTradeTransaction
#undef OnChartEvent

input group "--- v1.50 Smart break-even costs ---"
input bool   InpV150CoverLiveSpread              = true;
input bool   InpV150CoverCommissionAndFees       = true;
input double InpV150CommissionPerLotRoundTurn    = 0.0; // account currency / 1 lot; 0 = estimate from history
input double InpV150ExtraBreakEvenBufferPips     = 0.20;

input group "--- v1.50 Runtime panel ---"
input bool   InpV150RememberRuntimeControls      = true;
input bool   InpV150ShowAdvancedPanel            = true;

//+------------------------------------------------------------------+
//| v1.50 runtime state                                              |
//+------------------------------------------------------------------+
bool v_manage_manual=false;
bool v_use_be=true;
bool v_use_partial=true;
bool v_use_trailing=false;
bool v_news_guard=true;
bool v_overtrade_guard=true;
ENUM_RP_HEDGE_POLICY v_hedge_policy=RP_HEDGE_WARN;
ENUM_RP_TRIGGER_MODE v_be_mode=RP_TRIGGER_RR;
ENUM_RP_TRIGGER_MODE v_partial_mode=RP_TRIGGER_RR;
ENUM_RP_TRIGGER_MODE v_trailing_mode=RP_TRIGGER_PIPS;
double v_be_r=1.0;
double v_be_pips=10.0;
double v_be_lock_pips=0.0;
double v_partial_r=1.0;
double v_partial_pips=10.0;
double v_partial_pct=50.0;
double v_trail_start_r=1.5;
double v_trail_start_pips=15.0;
double v_trail_distance_r=0.5;
double v_trail_distance_pips=8.0;
double v_trail_step_r=0.1;
double v_trail_step_pips=2.0;
int v_news_before=15;
int v_news_after=15;
int v_max_daily_trades=20;
int v_max_open_positions=5;
int v_max_pending_orders=10;
bool v_journal_view=false;
string v_day_prefix="";
datetime v_last_tehran_day=0;
ulong v_last_manage_ms=0;
datetime v_commission_cache_time=0;
double v_one_way_commission_per_lot=0.0;
ulong v_screenshot_queue[];

string VUI(const string suffix) { return g_ui_prefix+"V150_"+suffix; }

string VStateKey(const string suffix)
  {
   return StringFormat("ARKO150_%I64d_%I64u_%s",AccountInfoInteger(ACCOUNT_LOGIN),InpMagicNumber,suffix);
  }

double VReadState(const string suffix,const double fallback)
  {
   string key=VStateKey(suffix);
   return(GlobalVariableCheck(key)?GlobalVariableGet(key):fallback);
  }

void VSaveRuntime()
  {
   if(!InpV150RememberRuntimeControls)
      return;
   GlobalVariableSet(VStateKey("MANUAL"),v_manage_manual?1.0:0.0);
   GlobalVariableSet(VStateKey("BE"),v_use_be?1.0:0.0);
   GlobalVariableSet(VStateKey("PART"),v_use_partial?1.0:0.0);
   GlobalVariableSet(VStateKey("TRAIL"),v_use_trailing?1.0:0.0);
   GlobalVariableSet(VStateKey("NEWS"),v_news_guard?1.0:0.0);
   GlobalVariableSet(VStateKey("OVER"),v_overtrade_guard?1.0:0.0);
   GlobalVariableSet(VStateKey("HEDGE"),(double)v_hedge_policy);
   GlobalVariableSet(VStateKey("BEMODE"),(double)v_be_mode);
   GlobalVariableSet(VStateKey("BER"),v_be_r);
   GlobalVariableSet(VStateKey("BEP"),v_be_pips);
   GlobalVariableSet(VStateKey("BELOCK"),v_be_lock_pips);
   GlobalVariableSet(VStateKey("PMODE"),(double)v_partial_mode);
   GlobalVariableSet(VStateKey("PR"),v_partial_r);
   GlobalVariableSet(VStateKey("PP"),v_partial_pips);
   GlobalVariableSet(VStateKey("PPCT"),v_partial_pct);
   GlobalVariableSet(VStateKey("TMODE"),(double)v_trailing_mode);
   GlobalVariableSet(VStateKey("TSR"),v_trail_start_r);
   GlobalVariableSet(VStateKey("TSP"),v_trail_start_pips);
   GlobalVariableSet(VStateKey("TDR"),v_trail_distance_r);
   GlobalVariableSet(VStateKey("TDP"),v_trail_distance_pips);
   GlobalVariableSet(VStateKey("TTR"),v_trail_step_r);
   GlobalVariableSet(VStateKey("TTP"),v_trail_step_pips);
   GlobalVariableSet(VStateKey("NB"),(double)v_news_before);
   GlobalVariableSet(VStateKey("NA"),(double)v_news_after);
   GlobalVariableSet(VStateKey("MAXT"),(double)v_max_daily_trades);
   GlobalVariableSet(VStateKey("MAXP"),(double)v_max_open_positions);
   GlobalVariableSet(VStateKey("MAXO"),(double)v_max_pending_orders);
  }

void VInitRuntime()
  {
   v_manage_manual=InpManageManualPositions;
   v_use_be=InpUseBreakEven;
   v_use_partial=InpUsePartialClose;
   v_use_trailing=InpUseTrailing;
   v_news_guard=InpUseNewsAutoPause;
   v_hedge_policy=InpHedgePolicy;
   v_be_mode=InpBreakEvenTriggerMode;
   v_be_r=InpBreakEvenAtR;
   v_be_pips=InpBreakEvenAtPips;
   v_be_lock_pips=InpBreakEvenLockPips;
   v_partial_mode=InpPartialTriggerMode;
   v_partial_r=InpPartialCloseAtR;
   v_partial_pips=InpPartialCloseAtPips;
   v_partial_pct=InpPartialClosePercent;
   v_trailing_mode=InpTrailingMode;
   v_trail_start_r=InpTrailStartAtR;
   v_trail_start_pips=InpTrailStartPips;
   v_trail_distance_r=InpTrailDistanceR;
   v_trail_distance_pips=InpTrailDistancePips;
   v_trail_step_r=InpTrailStepR;
   v_trail_step_pips=InpTrailStepPips;
   v_news_before=InpNewsPauseMinutesBefore;
   v_news_after=InpNewsPauseMinutesAfter;
   v_max_daily_trades=InpMaxDailyTrades;
   v_max_open_positions=InpMaxOpenPositions;
   v_max_pending_orders=InpMaxPendingOrders;

   if(!InpV150RememberRuntimeControls)
      return;
   v_manage_manual=VReadState("MANUAL",v_manage_manual?1.0:0.0)>0.5;
   v_use_be=VReadState("BE",v_use_be?1.0:0.0)>0.5;
   v_use_partial=VReadState("PART",v_use_partial?1.0:0.0)>0.5;
   v_use_trailing=VReadState("TRAIL",v_use_trailing?1.0:0.0)>0.5;
   v_news_guard=VReadState("NEWS",v_news_guard?1.0:0.0)>0.5;
   v_overtrade_guard=VReadState("OVER",1.0)>0.5;
   v_hedge_policy=(ENUM_RP_HEDGE_POLICY)(int)VReadState("HEDGE",(double)v_hedge_policy);
   v_be_mode=(ENUM_RP_TRIGGER_MODE)(int)VReadState("BEMODE",(double)v_be_mode);
   v_be_r=VReadState("BER",v_be_r);
   v_be_pips=VReadState("BEP",v_be_pips);
   v_be_lock_pips=VReadState("BELOCK",v_be_lock_pips);
   v_partial_mode=(ENUM_RP_TRIGGER_MODE)(int)VReadState("PMODE",(double)v_partial_mode);
   v_partial_r=VReadState("PR",v_partial_r);
   v_partial_pips=VReadState("PP",v_partial_pips);
   v_partial_pct=VReadState("PPCT",v_partial_pct);
   v_trailing_mode=(ENUM_RP_TRIGGER_MODE)(int)VReadState("TMODE",(double)v_trailing_mode);
   v_trail_start_r=VReadState("TSR",v_trail_start_r);
   v_trail_start_pips=VReadState("TSP",v_trail_start_pips);
   v_trail_distance_r=VReadState("TDR",v_trail_distance_r);
   v_trail_distance_pips=VReadState("TDP",v_trail_distance_pips);
   v_trail_step_r=VReadState("TTR",v_trail_step_r);
   v_trail_step_pips=VReadState("TTP",v_trail_step_pips);
   v_news_before=(int)VReadState("NB",(double)v_news_before);
   v_news_after=(int)VReadState("NA",(double)v_news_after);
   v_max_daily_trades=(int)VReadState("MAXT",(double)v_max_daily_trades);
   v_max_open_positions=(int)VReadState("MAXP",(double)v_max_open_positions);
   v_max_pending_orders=(int)VReadState("MAXO",(double)v_max_pending_orders);
  }

//+------------------------------------------------------------------+
//| Managed trade scope                                              |
//+------------------------------------------------------------------+
bool VManagedMagic(const long magic)
  {
   return(magic==(long)InpMagicNumber || (v_manage_manual && magic==0));
  }

bool VManagedPositionSelected()
  {
   return(PositionGetString(POSITION_SYMBOL)==_Symbol && VManagedMagic(PositionGetInteger(POSITION_MAGIC)));
  }

int VManagedPositionCount(const bool current_symbol_only=true)
  {
   int count=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VManagedMagic(PositionGetInteger(POSITION_MAGIC)))
         continue;
      if(!current_symbol_only || PositionGetString(POSITION_SYMBOL)==_Symbol)
         count++;
     }
   return count;
  }

int VManagedPendingCount(const bool current_symbol_only=true)
  {
   int count=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) || !VManagedMagic(OrderGetInteger(ORDER_MAGIC)))
         continue;
      if(!current_symbol_only || OrderGetString(ORDER_SYMBOL)==_Symbol)
         count++;
     }
   return count;
  }

bool VScopeMatches(const string symbol_name,const long magic)
  {
   if(InpDailyGuardScope==RP_SCOPE_ACCOUNT)
      return true;
   if(!VManagedMagic(magic))
      return false;
   if(InpDailyGuardScope==RP_SCOPE_EA_SYMBOL && symbol_name!=_Symbol)
      return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Tehran-day statistics and guard                                  |
//+------------------------------------------------------------------+
void VDailyStats(double &realized,double &floating,int &trade_count)
  {
   realized=0.0; floating=0.0; trade_count=0;
   datetime from=0,to=0;
   TehranDayBoundsInServerTime(from,to);
   to=MathMin(to,ServerNow());
   if(HistorySelect(from,to))
     {
      for(int i=0;i<HistoryDealsTotal();i++)
        {
         ulong deal=HistoryDealGetTicket(i);
         if(deal==0)
            continue;
         ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
         if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)
            continue;
         string symbol_name=HistoryDealGetString(deal,DEAL_SYMBOL);
         long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
         if(!VScopeMatches(symbol_name,magic))
            continue;
         realized+=HistoryDealGetDouble(deal,DEAL_PROFIT);
         realized+=HistoryDealGetDouble(deal,DEAL_SWAP);
         realized+=HistoryDealGetDouble(deal,DEAL_COMMISSION);
         realized+=HistoryDealGetDouble(deal,DEAL_FEE);
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT)
            trade_count++;
        }
     }
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VScopeMatches(PositionGetString(POSITION_SYMBOL),PositionGetInteger(POSITION_MAGIC)))
         continue;
      floating+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
     }
  }

string VGuardKey(const string suffix)
  {
   string symbol_part=(InpDailyGuardScope==RP_SCOPE_EA_SYMBOL?_Symbol:"ALL");
   return StringFormat("ARKO150_GUARD_%I64d_%I64u_%d_%s_%s",AccountInfoInteger(ACCOUNT_LOGIN),
                       InpMagicNumber,(int)InpDailyGuardScope,symbol_part,suffix);
  }

bool VDailyLocked(int &lock_type)
  {
   lock_type=0;
   string day_key=VGuardKey("DAY");
   string type_key=VGuardKey("TYPE");
   datetime today=TehranDayStart();
   if(!GlobalVariableCheck(day_key) || (datetime)GlobalVariableGet(day_key)!=today)
      return false;
   lock_type=(GlobalVariableCheck(type_key)?(int)GlobalVariableGet(type_key):1);
   if((lock_type==1 && !InpUseDailyLossGuard) || (lock_type==2 && !InpUseDailyProfitTarget))
      return false;
   return true;
  }

void VLockDaily(const int lock_type)
  {
   GlobalVariableSet(VGuardKey("DAY"),(double)TehranDayStart());
   GlobalVariableSet(VGuardKey("TYPE"),(double)lock_type);
  }

int VDailyThreshold(double &day_result,double &limit_value)
  {
   double realized=0.0,floating=0.0; int trades=0;
   VDailyStats(realized,floating,trades);
   day_result=realized+(InpIncludeFloatingInDailyLoss?floating:0.0);
   double start_balance=MathMax(0.01,AccountInfoDouble(ACCOUNT_BALANCE)-realized);
   if(InpUseDailyLossGuard)
     {
      limit_value=(InpDailyLossMode==RP_GUARD_MONEY?InpMaxDailyLossMoney:start_balance*InpMaxDailyLossPercent/100.0);
      if(limit_value>0.0 && day_result<=-limit_value)
         return 1;
     }
   if(InpUseDailyProfitTarget)
     {
      limit_value=(InpDailyProfitMode==RP_GUARD_MONEY?InpDailyProfitTargetMoney:start_balance*InpDailyProfitTargetPercent/100.0);
      if(limit_value>0.0 && day_result>=limit_value)
         return 2;
     }
   limit_value=0.0;
   return 0;
  }

int VCloseGuardPositions()
  {
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VScopeMatches(PositionGetString(POSITION_SYMBOL),PositionGetInteger(POSITION_MAGIC)))
         continue;
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      trade.SetTypeFillingBySymbol(symbol_name);
      if(trade.PositionClose(ticket,InpDeviationPoints) && TradeRetcodeOK()) closed++;
     }
   trade.SetTypeFillingBySymbol(_Symbol);
   return closed;
  }

int VCancelGuardPending()
  {
   int deleted=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) || !VScopeMatches(OrderGetString(ORDER_SYMBOL),OrderGetInteger(ORDER_MAGIC)))
         continue;
      if(trade.OrderDelete(ticket) && TradeRetcodeOK()) deleted++;
     }
   return deleted;
  }

void VEnforceDailyGuard()
  {
   int lock_type=0;
   if(VDailyLocked(lock_type))
     {
      bool close_positions=(lock_type==1?InpClosePositionsAtDailyLoss:InpClosePositionsAtProfitTarget);
      bool cancel_pending=(lock_type==1?InpCancelPendingAtDailyLoss:InpCancelPendingAtProfitTarget);
      if(close_positions) VCloseGuardPositions();
      if(cancel_pending) VCancelGuardPending();
      return;
     }
   double day_result=0.0,limit_value=0.0;
   int reached=VDailyThreshold(day_result,limit_value);
   if(reached==0) return;
   VLockDaily(reached);
   bool close_positions=(reached==1?InpClosePositionsAtDailyLoss:InpClosePositionsAtProfitTarget);
   bool cancel_pending=(reached==1?InpCancelPendingAtDailyLoss:InpCancelPendingAtProfitTarget);
   int closed=(close_positions?VCloseGuardPositions():0);
   int cancelled=(cancel_pending?VCancelGuardPending():0);
   SetStatus(StringFormat("TEHRAN DAY %s LOCK | %.2f | closed %d / cancelled %d",
             reached==1?"LOSS":"PROFIT",day_result,closed,cancelled),RP_RED,0);
  }

//+------------------------------------------------------------------+
//| Live spread / commission-aware price protection                  |
//+------------------------------------------------------------------+
double VStopSafetyDistance(const MqlTick &tick,const double multiplier=1.0)
  {
   long stops=(long)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   long freeze=(long)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0) tick_size=_Point;
   double spread=(tick.ask>tick.bid?tick.ask-tick.bid:0.0);
   double rounding=MathMax(2.0*tick_size,2.0*_Point);
   double broker=(double)MathMax(stops,freeze)*_Point;
   double base=MathMax(broker,tick_size)+rounding;
   // Full live spread, not only a fraction of it.
   base=MathMax(base,spread+rounding);
   return base*MathMax(1.0,multiplier);
  }

bool VPrepareMarketStops(const bool buy_side,const MqlTick &tick,double &sl,double &tp,
                         const double multiplier,string &reason)
  {
   if(tick.ask<=0.0 || tick.bid<=0.0) { reason="No live quote"; return false; }
   double distance=VStopSafetyDistance(tick,multiplier);
   if(buy_side)
     {
      sl=NormalizePriceDown(MathMin(sl,tick.bid-distance));
      tp=NormalizePriceUp(MathMax(tp,tick.ask+distance));
      if(sl>=tick.bid-distance+_Point*0.1 || tp<=tick.ask+distance-_Point*0.1)
        { reason="SL/TP too close after live-spread safety"; return false; }
     }
   else
     {
      sl=NormalizePriceUp(MathMax(sl,tick.ask+distance));
      tp=NormalizePriceDown(MathMin(tp,tick.bid-distance));
      if(sl<=tick.ask+distance-_Point*0.1 || tp>=tick.bid-distance+_Point*0.1)
        { reason="SL/TP too close after live-spread safety"; return false; }
     }
   return true;
  }

bool VValidatePending(const bool buy_side,const double entry,const double sl,const double tp,string &reason)
  {
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick)) { reason="No live quote"; return false; }
   double distance=VStopSafetyDistance(tick);
   if(buy_side)
     {
      if(entry>tick.ask-distance) { reason="Buy Limit is inside live-spread safety distance"; return false; }
      if(sl>=entry-distance || tp<=entry+distance) { reason="Pending SL/TP violates live-spread safety"; return false; }
     }
   else
     {
      if(entry<tick.bid+distance) { reason="Sell Limit is inside live-spread safety distance"; return false; }
      if(sl<=entry+distance || tp>=entry-distance) { reason="Pending SL/TP violates live-spread safety"; return false; }
     }
   return true;
  }

double VEstimateOneWayCommissionPerLot(const string symbol_name)
  {
   datetime now=ServerNow();
   if(v_commission_cache_time>0 && now-v_commission_cache_time<300)
      return v_one_way_commission_per_lot;
   v_commission_cache_time=now;
   v_one_way_commission_per_lot=0.0;
   if(!HistorySelect(now-30*86400,now))
      return 0.0;
   double cost=0.0,volume=0.0; int samples=0;
   for(int i=HistoryDealsTotal()-1;i>=0 && samples<200;i--)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=symbol_name) continue;
      ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) continue;
      double v=HistoryDealGetDouble(deal,DEAL_VOLUME);
      double c=MathAbs(HistoryDealGetDouble(deal,DEAL_COMMISSION))+MathAbs(HistoryDealGetDouble(deal,DEAL_FEE));
      if(v<=0.0 || c<=0.0) continue;
      cost+=c; volume+=v; samples++;
     }
   if(volume>0.0) v_one_way_commission_per_lot=cost/volume;
   return v_one_way_commission_per_lot;
  }

double VPositionAccruedCosts(const long position_id)
  {
   if(position_id<=0 || !HistorySelectByPosition((ulong)position_id)) return 0.0;
   double cost=0.0;
   for(int i=0;i<HistoryDealsTotal();i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0) continue;
      cost+=MathAbs(HistoryDealGetDouble(deal,DEAL_COMMISSION));
      cost+=MathAbs(HistoryDealGetDouble(deal,DEAL_FEE));
     }
   return cost;
  }

double VMoneyToPriceDistance(const string symbol_name,const bool buy_side,const double entry,
                             const double volume,const double money)
  {
   if(money<=0.0 || volume<=0.0) return 0.0;
   double tick_size=SymbolInfoDouble(symbol_name,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0) tick_size=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(tick_size<=0.0) return 0.0;
   double one_lot=0.0;
   double close_price=(buy_side?entry+tick_size:entry-tick_size);
   if(!ProfitForOneLotSymbol(symbol_name,buy_side,entry,close_price,one_lot)) return 0.0;
   double per_tick=MathAbs(one_lot)*volume;
   if(per_tick<=0.0) return 0.0;
   return MathCeil(money/per_tick-1e-12)*tick_size;
  }

double VSmartBreakEvenOffset(const ulong ticket,const bool buy_side,const double entry,
                             const double volume,const MqlTick &tick)
  {
   double configured=MathMax(MathMax(0.0,v_be_lock_pips),MathMax(0.0,InpV150ExtraBreakEvenBufferPips))*PipSize();
   configured=MathMax(configured,MathMax(0,InpBreakEvenPlusPoints)*_Point);
   double offset=configured;
   if(InpV150CoverLiveSpread && tick.ask>tick.bid)
      offset+=tick.ask-tick.bid;

   if(InpV150CoverCommissionAndFees && PositionSelectByTicket(ticket))
     {
      long position_id=PositionGetInteger(POSITION_IDENTIFIER);
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      double swap=PositionGetDouble(POSITION_SWAP);
      double accrued=VPositionAccruedCosts(position_id);
      double total_cost=accrued;
      if(InpV150CommissionPerLotRoundTurn>0.0)
         total_cost=MathMax(total_cost,InpV150CommissionPerLotRoundTurn*volume);
      else
        {
         double one_way=VEstimateOneWayCommissionPerLot(symbol_name)*volume;
         // When the opening deal appears to contain only one side of commission,
         // reserve another one-way charge for the eventual stop close.
         if(one_way>0.0 && accrued<one_way*1.5) total_cost+=one_way;
        }
      total_cost+=MathMax(0.0,-swap);
      offset+=VMoneyToPriceDistance(symbol_name,buy_side,entry,volume,total_cost);
     }
   return offset;
  }

//+------------------------------------------------------------------+
//| Runtime automatic position management                            |
//+------------------------------------------------------------------+
bool VTrigger(const ENUM_RP_TRIGGER_MODE mode,const double current_r,const double progress,
              const double at_r,const double at_pips)
  {
   return TriggerReached(mode,current_r,progress,at_r,at_pips);
  }

void VManageOpenPositions()
  {
   ulong now_ms=GetTickCount64();
   if(now_ms-v_last_manage_ms<200) return;
   v_last_manage_ms=now_ms;
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0) return;
   double min_stop=VStopSafetyDistance(tick);

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VManagedPositionSelected()) continue;
      bool buy_side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double current_volume=PositionGetDouble(POSITION_VOLUME);
      long identifier=PositionGetInteger(POSITION_IDENTIFIER);
      if(entry<=0.0 || current_volume<=0.0) continue;

      string risk_key=StateKey(identifier,"R");
      string volume_key=StateKey(identifier,"V");
      string partial_key=StateKey(identifier,"P");
      double fallback_risk=(sl>0.0?MathAbs(entry-sl):DefaultRiskDistance());
      double initial_risk=StateGetOrCreate(risk_key,fallback_risk);
      double initial_volume=StateGetOrCreate(volume_key,current_volume);
      double partial_done=StateGetOrCreate(partial_key,0.0);
      if(initial_risk<=0.0) initial_risk=DefaultRiskDistance();
      double current_price=(buy_side?tick.bid:tick.ask);
      double progress=(buy_side?current_price-entry:entry-current_price);
      double current_r=(initial_risk>0.0?progress/initial_risk:0.0);

      if(v_use_partial && partial_done<0.5 &&
         VTrigger(v_partial_mode,current_r,progress,v_partial_r,v_partial_pips))
        {
         double close_volume=NormalizeVolumeFloor(initial_volume*ClampDouble(v_partial_pct,1.0,99.0)/100.0,false);
         double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
         if(close_volume>0.0 && current_volume-close_volume>=minimum-1e-12)
           {
            string error_text="";
            if(ClosePositionVolume(ticket,close_volume,error_text))
              {
               GlobalVariableSet(partial_key,1.0);
               SetStatus("v1.50 auto save-profit completed",RP_GREEN,5);
              }
            else Print("ArkoRisk v1.50 partial close failed: ",error_text);
           }
         else GlobalVariableSet(partial_key,1.0);
        }

      if(!PositionSelectByTicket(ticket)) continue;
      sl=PositionGetDouble(POSITION_SL); tp=PositionGetDouble(POSITION_TP);
      current_volume=PositionGetDouble(POSITION_VOLUME);
      double desired_sl=sl;
      bool modify=false;

      if(v_use_be && VTrigger(v_be_mode,current_r,progress,v_be_r,v_be_pips))
        {
         double offset=VSmartBreakEvenOffset(ticket,buy_side,entry,current_volume,tick);
         double be=(buy_side?NormalizePriceUp(entry+offset):NormalizePriceDown(entry-offset));
         bool valid=(buy_side?be<=tick.bid-min_stop:be>=tick.ask+min_stop);
         bool improves=(buy_side?(sl<=0.0 || be>sl+_Point*0.5):(sl<=0.0 || be<sl-_Point*0.5));
         if(valid && improves) { desired_sl=be; modify=true; }
        }

      if(v_use_trailing && VTrigger(v_trailing_mode,current_r,progress,v_trail_start_r,v_trail_start_pips))
        {
         double distance=(v_trailing_mode==RP_TRIGGER_PIPS?
                          MathMax(0.1,v_trail_distance_pips)*PipSize():
                          initial_risk*MathMax(0.05,v_trail_distance_r));
         double candidate=(buy_side?NormalizePriceDown(tick.bid-distance):NormalizePriceUp(tick.ask+distance));
         double step=(v_trailing_mode==RP_TRIGGER_PIPS?
                      MathMax(0.1,v_trail_step_pips)*PipSize():
                      initial_risk*MathMax(0.01,v_trail_step_r));
         bool valid=(buy_side?candidate<=tick.bid-min_stop:candidate>=tick.ask+min_stop);
         bool improves=(buy_side?(desired_sl<=0.0 || candidate>desired_sl+step):(desired_sl<=0.0 || candidate<desired_sl-step));
         if(valid && improves) { desired_sl=candidate; modify=true; }
        }

      if(modify)
        {
         trade.SetExpertMagicNumber(InpMagicNumber);
         trade.SetTypeFillingBySymbol(_Symbol);
         if(!trade.PositionModify(ticket,desired_sl,tp) || !TradeRetcodeOK())
            Print("ArkoRisk v1.50 SL modify failed #",ticket,": ",trade.ResultRetcodeDescription());
        }
     }
  }

void VBreakEvenAll()
  {
   MqlTick tick={}; if(!SymbolInfoTick(_Symbol,tick)) return;
   double min_stop=VStopSafetyDistance(tick); int changed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VManagedPositionSelected()) continue;
      bool buy_side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double volume=PositionGetDouble(POSITION_VOLUME);
      double offset=VSmartBreakEvenOffset(ticket,buy_side,entry,volume,tick);
      double next=(buy_side?NormalizePriceUp(entry+offset):NormalizePriceDown(entry-offset));
      bool valid=(buy_side?next<tick.bid-min_stop:next>tick.ask+min_stop);
      bool improves=(buy_side?(sl<=0.0 || next>sl):(sl<=0.0 || next<sl));
      if(valid && improves && trade.PositionModify(ticket,next,tp) && TradeRetcodeOK()) changed++;
     }
   SetStatus(StringFormat("Smart break-even applied to %d position(s)",changed),changed>0?RP_GREEN:RP_AMBER,6);
  }

void VCloseHalfAll()
  {
   int changed=0; string error_text="";
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VManagedPositionSelected()) continue;
      double volume=PositionGetDouble(POSITION_VOLUME);
      double half=NormalizeVolumeFloor(volume*0.5,false);
      double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
      if(half<=0.0 || volume-half<minimum-1e-12) continue;
      if(ClosePositionVolume(ticket,half,error_text)) { changed++; GlobalVariableSet(StateKey(PositionGetInteger(POSITION_IDENTIFIER),"P"),1.0); }
     }
   SetStatus(StringFormat("Saved 50%% on %d managed position(s)",changed),changed>0?RP_GREEN:RP_AMBER,6);
  }

void VCloseByProfit(const bool profitable)
  {
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VManagedPositionSelected()) continue;
      double pnl=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      if((profitable && pnl<=0.0) || (!profitable && pnl>=0.0)) continue;
      if(trade.PositionClose(ticket,InpDeviationPoints) && TradeRetcodeOK()) closed++;
     }
   SetStatus(StringFormat("Closed %d %s managed position(s)",closed,profitable?"profitable":"losing"),closed>0?RP_GREEN:RP_AMBER,6);
  }

void VCloseAll()
  {
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !VManagedPositionSelected()) continue;
      if(trade.PositionClose(ticket,InpDeviationPoints) && TradeRetcodeOK()) closed++;
     }
   SetStatus(StringFormat("Emergency closed %d managed position(s)",closed),closed>0?RP_GREEN:RP_AMBER,6);
  }

void VCancelPending()
  {
   int deleted=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) || OrderGetString(ORDER_SYMBOL)!=_Symbol || !VManagedMagic(OrderGetInteger(ORDER_MAGIC))) continue;
      if(trade.OrderDelete(ticket) && TradeRetcodeOK()) deleted++;
     }
   SetStatus(StringFormat("Cancelled %d managed pending order(s)",deleted),deleted>0?RP_GREEN:RP_AMBER,6);
  }

void VCancelStalePending()
  {
   if(InpCancelPendingAfterMinutes<=0) return;
   datetime now=ServerNow();
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) || !VManagedMagic(OrderGetInteger(ORDER_MAGIC))) continue;
      datetime setup=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(setup>0 && now-setup>=InpCancelPendingAfterMinutes*60)
         trade.OrderDelete(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Runtime news / hedge / entry guards                              |
//+------------------------------------------------------------------+
bool VNewsPause(string &reason)
  {
   reason="";
   if(!v_news_guard) return false;
   bool refreshed=RefreshEconomicNews(false,false);
   if(!refreshed && InpBlockIfCalendarUnavailable) { reason="News guard: calendar unavailable"; return true; }
   datetime now=TehranNow();
   int before=MathMax(0,v_news_before)*60;
   int after=MathMax(0,v_news_after)*60;
   for(int i=0;i<ArraySize(g_news_items);i++)
     {
      ArkoNewsItem item=g_news_items[i];
      if(item.importance!=CALENDAR_IMPORTANCE_HIGH || item.time_mode!=CALENDAR_TIMEMODE_DATETIME || !NewsCurrencyRelevant(item.currency)) continue;
      if(now>=item.tehran_time-before && now<=item.tehran_time+after)
        {
         reason=StringFormat("NEWS BLOCK %s %s %s",TimeToString(item.tehran_time,TIME_MINUTES),item.currency,TruncateText(item.title,24));
         return true;
        }
     }
   return false;
  }

string VHedgeText()
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) return "NETTING";
   if(v_hedge_policy==RP_HEDGE_ALLOW) return "ALLOW";
   if(v_hedge_policy==RP_HEDGE_BLOCK) return "BLOCK";
   return "WARN";
  }

bool VHedgeExposureInScope(const long magic)
  {
   return(InpHedgeCheckAllAccountTrades || VManagedMagic(magic));
  }

bool VHasOpposite(const bool buy,string &details,const bool include_positions=true)
  {
   details="";
   if(include_positions)
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol || !VHedgeExposureInScope(PositionGetInteger(POSITION_MAGIC))) continue;
         bool side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
         if(side!=buy) { details=StringFormat("opposite position #%I64u",ticket); return true; }
        }
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol || !VHedgeExposureInScope(OrderGetInteger(ORDER_MAGIC))) continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(IsPendingOrderType(type) && IsBuyOrderType(type)!=buy) { details=StringFormat("opposite pending #%I64u",ticket); return true; }
     }
   return false;
  }

bool VConfirmHedge(const bool buy,string &reason,const bool include_positions=true)
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) return true;
   if(v_hedge_policy==RP_HEDGE_ALLOW) return true;
   string details="";
   if(!VHasOpposite(buy,details,include_positions)) { g_hedge_confirm_side=0; g_hedge_confirm_until=0; return true; }
   if(v_hedge_policy==RP_HEDGE_BLOCK) { reason="HEDGE BLOCKED • "+details; return false; }
   int side=(buy?1:-1); datetime now=ServerNow();
   if(g_hedge_confirm_side==side && now<=g_hedge_confirm_until) { g_hedge_confirm_side=0; g_hedge_confirm_until=0; return true; }
   g_hedge_confirm_side=side;
   g_hedge_confirm_until=now+MathMax(3,InpHedgeConfirmationSeconds);
   reason=StringFormat("HEDGE WARNING • click again within %ds",MathMax(3,InpHedgeConfirmationSeconds));
   return false;
  }

bool VBasicGuards(string &reason,const bool ignore_position_limits=false)
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     { reason="AutoTrading/account trading disabled"; return false; }
   ENUM_SYMBOL_TRADE_MODE mode=(ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(mode==SYMBOL_TRADE_MODE_DISABLED || mode==SYMBOL_TRADE_MODE_CLOSEONLY) { reason="Symbol not open for entries"; return false; }
   MqlTick tick={}; if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0) { reason="No live quote"; return false; }
   double spread=(tick.ask-tick.bid)/_Point;
   if(InpMaxSpreadPoints>0 && spread>InpMaxSpreadPoints) { reason=StringFormat("Spread %.0f exceeds %d",spread,InpMaxSpreadPoints); return false; }
   int lock_type=0; if(VDailyLocked(lock_type)) { reason=(lock_type==1?"Tehran daily loss lock":"Tehran daily profit lock"); return false; }
   double day=0.0,limit=0.0; if(VDailyThreshold(day,limit)>0) { reason="Tehran daily guard threshold reached"; return false; }
   string news=""; if(VNewsPause(news)) { reason=news; return false; }
   if(v_overtrade_guard)
     {
      double r=0.0,f=0.0; int trades=0; VDailyStats(r,f,trades);
      if(v_max_daily_trades>0 && trades>=v_max_daily_trades) { reason=StringFormat("Daily trade limit %d reached",v_max_daily_trades); return false; }
      if(!ignore_position_limits && v_max_open_positions>0 && VManagedPositionCount(false)>=v_max_open_positions) { reason=StringFormat("Open-position limit %d reached",v_max_open_positions); return false; }
     }
   if(!ignore_position_limits && InpOnePositionPerSymbol && VManagedPositionCount(true)>0) { reason="Managed position already exists on symbol"; return false; }
   return true;
  }

//+------------------------------------------------------------------+
//| Runtime order execution                                          |
//+------------------------------------------------------------------+
void VPlaceMarket(const bool buy)
  {
   string reason="";
   if(!VBasicGuards(reason) || !CheckDirectionAllowed(buy,reason) || !VConfirmHedge(buy,reason))
     { SetStatus(reason,RP_RED,8); return; }
   MqlTick tick={}; if(!SymbolInfoTick(_Symbol,tick)) { SetStatus("No live quote",RP_RED,6); return; }
   double entry=(buy?tick.ask:tick.bid),sl=0.0,tp=0.0;
   DefaultMarketStops(buy,entry,sl,tp);
   if(!VPrepareMarketStops(buy,tick,sl,tp,1.0,reason)) { SetStatus(reason,RP_RED,8); return; }
   double volume=0.0,risk=0.0;
   if(!CalculateVolume(buy,entry,sl,volume,risk,reason) || !CheckOpenRiskGuard(risk,reason)) { SetStatus(reason,RP_RED,8); return; }
   trade.SetExpertMagicNumber(InpMagicNumber); trade.SetDeviationInPoints(InpDeviationPoints); trade.SetTypeFillingBySymbol(_Symbol);
   bool sent=(buy?trade.Buy(volume,_Symbol,0.0,sl,tp,"ArkoRisk v1.50 BUY"):trade.Sell(volume,_Symbol,0.0,sl,tp,"ArkoRisk v1.50 SELL"));
   if(sent && TradeRetcodeOK()) SetStatus(StringFormat("%s opened • %s lots • spread-safe SL/TP",buy?"BUY":"SELL",DoubleToString(volume,VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)))),RP_GREEN,7);
   else SetStatus("Order rejected: "+trade.ResultRetcodeDescription(),RP_RED,9);
   UpdatePanel();
  }

void VPlaceLimit()
  {
   string reason="";
   if(!VBasicGuards(reason) || !CheckDirectionAllowed(g_is_buy,reason) || !VConfirmHedge(g_is_buy,reason)) { SetStatus(reason,RP_RED,8); return; }
   if(v_overtrade_guard && v_max_pending_orders>0 && VManagedPendingCount(false)>=v_max_pending_orders) { SetStatus(StringFormat("Pending limit %d reached",v_max_pending_orders),RP_RED,8); return; }
   if(!ValidateDesigner(reason)) { SetStatus(reason,RP_RED,7); return; }
   double entry=(g_is_buy?NormalizePriceDown(LinePrice("ENTRY")):NormalizePriceUp(LinePrice("ENTRY")));
   double sl=(g_is_buy?NormalizePriceDown(LinePrice("SL")):NormalizePriceUp(LinePrice("SL")));
   double tp=(g_is_buy?NormalizePriceUp(LinePrice("TP")):NormalizePriceDown(LinePrice("TP")));
   if(!VValidatePending(g_is_buy,entry,sl,tp,reason)) { SetStatus(reason,RP_RED,8); return; }
   double volume=0.0,risk=0.0;
   if(!CalculateVolume(g_is_buy,entry,sl,volume,risk,reason) || !CheckOpenRiskGuard(risk,reason)) { SetStatus(reason,RP_RED,8); return; }
   trade.SetExpertMagicNumber(InpMagicNumber); trade.SetDeviationInPoints(InpDeviationPoints); trade.SetTypeFillingBySymbol(_Symbol);
   bool sent=(g_is_buy?trade.BuyLimit(volume,entry,_Symbol,sl,tp,ORDER_TIME_GTC,0,"ArkoRisk v1.50 BuyLimit"):
                       trade.SellLimit(volume,entry,_Symbol,sl,tp,ORDER_TIME_GTC,0,"ArkoRisk v1.50 SellLimit"));
   if(sent && TradeRetcodeOK()) SetStatus("Spread-safe Limit placed",RP_GREEN,7);
   else SetStatus("Limit rejected: "+trade.ResultRetcodeDescription(),RP_RED,9);
   UpdatePanel();
  }

bool VOpenFixed(const bool buy,const double requested,string &reason)
  {
   MqlTick tick={}; if(!SymbolInfoTick(_Symbol,tick)) { reason="No quote"; return false; }
   double volume=NormalizeVolumeFloor(requested,true); if(volume<=0.0) { reason="Invalid reverse volume"; return false; }
   double entry=(buy?tick.ask:tick.bid),sl=0.0,tp=0.0;
   DefaultMarketStops(buy,entry,sl,tp);
   if(!VPrepareMarketStops(buy,tick,sl,tp,1.0,reason)) return false;
   trade.SetExpertMagicNumber(InpMagicNumber); trade.SetDeviationInPoints(InpDeviationPoints); trade.SetTypeFillingBySymbol(_Symbol);
   bool sent=(buy?trade.Buy(volume,_Symbol,0.0,sl,tp,"ArkoRisk v1.50 REVERSE BUY"):
                  trade.Sell(volume,_Symbol,0.0,sl,tp,"ArkoRisk v1.50 REVERSE SELL"));
   if(!sent || !TradeRetcodeOK()) { reason="Reverse rejected: "+trade.ResultRetcodeDescription(); return false; }
   return true;
  }

void VReverse()
  {
   string reason=""; if(!VBasicGuards(reason,true)) { SetStatus(reason,RP_RED,8); return; }
   int direction=0,count=0; double total=0.0; ulong tickets[];
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i); if(ticket==0 || !VManagedPositionSelected()) continue;
      int side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1);
      if(direction!=0 && side!=direction) { SetStatus("Reverse refused: mixed directions",RP_RED,8); return; }
      direction=side; total+=PositionGetDouble(POSITION_VOLUME); ArrayResize(tickets,count+1); tickets[count++]=ticket;
     }
   if(count==0) { SetStatus("No managed position to reverse",RP_AMBER,6); return; }
   bool reverse_buy=(direction<0);
   if(!VConfirmHedge(reverse_buy,reason,false)) { SetStatus(reason,RP_AMBER,8); return; }
   int closed=0; for(int i=count-1;i>=0;i--) if(trade.PositionClose(tickets[i],InpDeviationPoints) && TradeRetcodeOK()) closed++;
   if(closed!=count) { SetStatus(StringFormat("Reverse stopped: %d/%d closed",closed,count),RP_RED,8); return; }
   if(VOpenFixed(reverse_buy,total,reason)) SetStatus(StringFormat("Reversed to %s • %.2f lots",reverse_buy?"BUY":"SELL",total),RP_GREEN,8);
   else SetStatus(reason,RP_RED,8);
  }

//+------------------------------------------------------------------+
//| Tehran day markers                                               |
//+------------------------------------------------------------------+
string VWeekday(const int d)
  {
   if(d==0) return "SUNDAY"; if(d==1) return "MONDAY"; if(d==2) return "TUESDAY";
   if(d==3) return "WEDNESDAY"; if(d==4) return "THURSDAY"; if(d==5) return "FRIDAY"; return "SATURDAY";
  }

void VDeleteDayMarkers()
  {
   if(v_day_prefix!="") ObjectsDeleteAll(0,v_day_prefix);
  }

void VDrawDayMarkers(const bool force=false)
  {
   datetime today=TehranDayStart();
   if(!force && v_last_tehran_day==today) return;
   v_last_tehran_day=today;
   VDeleteDayMarkers();
   double price_max=0.0,price_min=0.0; ChartGetDouble(0,CHART_PRICE_MAX,0,price_max); ChartGetDouble(0,CHART_PRICE_MIN,0,price_min);
   double label_price=price_max-(price_max-price_min)*0.015;
   int lookback=MathMax(1,MathMin(20,InpSessionLookbackDays)); long server_offset=ServerUTCOffsetSeconds();
   for(int i=0;i<lookback;i++)
     {
      datetime local_midnight=(datetime)((long)today-(long)i*86400); MqlDateTime tm={}; TimeToStruct(local_midnight,tm);
      datetime utc=(datetime)((long)local_midnight-TehranOffsetSeconds()); datetime server=(datetime)((long)utc+server_offset);
      string id=StringFormat("%04d%02d%02d",tm.year,tm.mon,tm.day); string line=v_day_prefix+id+"_L"; string label=v_day_prefix+id+"_T";
      string text=StringFormat("%s • %04d-%02d-%02d • TEHRAN",VWeekday(tm.day_of_week),tm.year,tm.mon,tm.day);
      if(ObjectCreate(0,line,OBJ_VLINE,0,server,0.0))
        {
         ObjectSetInteger(0,line,OBJPROP_COLOR,RP_BORDER); ObjectSetInteger(0,line,OBJPROP_STYLE,STYLE_DASHDOTDOT);
         ObjectSetInteger(0,line,OBJPROP_BACK,true); ObjectSetInteger(0,line,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,line,OBJPROP_HIDDEN,true);
         ObjectSetString(0,line,OBJPROP_TOOLTIP,text);
        }
      if(ObjectCreate(0,label,OBJ_TEXT,0,server,label_price))
        {
         ObjectSetString(0,label,OBJPROP_TEXT,text); ObjectSetString(0,label,OBJPROP_FONT,InpPanelFont);
         ObjectSetInteger(0,label,OBJPROP_FONTSIZE,8); ObjectSetInteger(0,label,OBJPROP_COLOR,RP_MUTED);
         ObjectSetInteger(0,label,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER); ObjectSetInteger(0,label,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,label,OBJPROP_HIDDEN,true);
        }
     }
  }

//+------------------------------------------------------------------+
//| Journal screenshots                                              |
//+------------------------------------------------------------------+
string VJournalDateFolder(const datetime tehran_time)
  {
   MqlDateTime tm={}; TimeToStruct(tehran_time,tm);
   return StringFormat("%s\\%04d-%02d-%02d",InpScreenshotFolder,tm.year,tm.mon,tm.day);
  }

void VCaptureDealScreenshot(const ulong deal)
  {
   if(!InpTakeEntryScreenshot || deal==0 || !HistoryDealSelect(deal)) return;
   ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
   ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
   long magic=HistoryDealGetInteger(deal,DEAL_MAGIC); string symbol_name=HistoryDealGetString(deal,DEAL_SYMBOL);
   if((entry!=DEAL_ENTRY_IN && entry!=DEAL_ENTRY_INOUT) || (type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) || !VManagedMagic(magic) || symbol_name!=_Symbol) return;
   datetime server=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
   datetime tehran=(datetime)((long)server-ServerUTCOffsetSeconds()+TehranOffsetSeconds());
   MqlDateTime tm={}; TimeToStruct(tehran,tm); string folder=VJournalDateFolder(tehran);
   FolderCreate("ArkoRisk"); FolderCreate(InpScreenshotFolder); FolderCreate(folder);
   string safe=StringSubstr(SafeFileToken(symbol_name),0,10); string side=(type==DEAL_TYPE_BUY?"BUY":"SELL");
   string file=StringFormat("%s\\%02d%02d%02d_%s_%s_%05u.png",folder,tm.hour,tm.min,tm.sec,safe,side,(uint)(deal%100000));
   if(StringLen(file)>63) { Print("ArkoRisk v1.50 screenshot path too long: ",file); return; }
   ChartRedraw();
   if(ChartScreenShot(0,file,MathMax(640,InpScreenshotWidth),MathMax(360,InpScreenshotHeight),ALIGN_RIGHT))
      Print("ArkoRisk journal: MQL5\\Files\\",file);
   else Print("ArkoRisk screenshot failed: ",GetLastError());
  }

void VQueueScreenshot(const ulong deal)
  {
   if(!InpTakeEntryScreenshot || deal==0 || !HistoryDealSelect(deal)) return;
   ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
   ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
   if((entry!=DEAL_ENTRY_IN && entry!=DEAL_ENTRY_INOUT) || (type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) || !VManagedMagic(HistoryDealGetInteger(deal,DEAL_MAGIC))) return;
   int n=ArraySize(v_screenshot_queue); if(n>=32) return; ArrayResize(v_screenshot_queue,n+1); v_screenshot_queue[n]=deal;
  }

void VProcessScreenshotQueue()
  {
   int n=ArraySize(v_screenshot_queue); if(n<=0) return; ulong deal=v_screenshot_queue[0];
   for(int i=1;i<n;i++) v_screenshot_queue[i-1]=v_screenshot_queue[i]; ArrayResize(v_screenshot_queue,n-1); VCaptureDealScreenshot(deal);
  }

void VTakeScreenshot()
  {
   if(!InpTakeEntryScreenshot) { SetStatus("Journal screenshots disabled in Inputs",RP_AMBER,6); return; }
   datetime now=TehranNow(); MqlDateTime tm={}; TimeToStruct(now,tm); string folder=VJournalDateFolder(now);
   FolderCreate("ArkoRisk"); FolderCreate(InpScreenshotFolder); FolderCreate(folder);
   string file=StringFormat("%s\\%02d%02d%02d_%s_MANUAL.png",folder,tm.hour,tm.min,tm.sec,StringSubstr(SafeFileToken(_Symbol),0,10));
   ChartRedraw();
   if(ChartScreenShot(0,file,MathMax(640,InpScreenshotWidth),MathMax(360,InpScreenshotHeight),ALIGN_RIGHT)) SetStatus("Screenshot saved • "+file,RP_GREEN,9);
   else SetStatus(StringFormat("Screenshot failed (%d)",GetLastError()),RP_RED,8);
  }

//+------------------------------------------------------------------+
//| Advanced runtime panel                                           |
//+------------------------------------------------------------------+
int VSideX()
  {
   long width=1000; ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,width);
   if(g_panel_x>=326) return g_panel_x-324;
   if(g_panel_x+g_panel_w+324<width) return g_panel_x+g_panel_w+8;
   return MathMax(4,(int)width-324);
  }

void VBuildControlsPanel()
  {
   if(!InpV150ShowAdvancedPanel || g_collapsed || g_active_tab!=RP_TAB_MANAGE) return;
   int x=VSideX(),y=g_panel_y;
   CreateRectangle(VUI("BG"),x,y,316,455,RP_BG,RP_BORDER);
   CreateLabel(VUI("TITLE"),v_journal_view?"ARKORISK JOURNAL • TEHRAN":"ARKORISK v1.50 • RUNTIME",x+12,y+10,10,RP_TEXT);
   CreateButton(VUI("VIEW"),v_journal_view?"CONTROLS":"JOURNAL",x+224,y+8,80,25,RP_CARD,RP_BLUE,RP_BORDER);
   if(v_journal_view)
     {
      CreateLabel(VUI("PATH"),"MQL5\\Files\\"+InpScreenshotFolder,x+12,y+48,8,RP_MUTED);
      CreateButton(VUI("SHOT"),"TAKE SCREENSHOT",x+12,y+72,138,29,RP_BLUE,RP_BG,RP_BLUE);
      CreateButton(VUI("SHOWPATH"),"SHOW PATH",x+158,y+72,146,29,RP_CARD,RP_TEXT,RP_BORDER);
      CreateLabel(VUI("RECENT"),"RECENT MANAGED ENTRIES",x+12,y+120,8,RP_MUTED);
      for(int i=0;i<7;i++)
        {
         int ry=y+145+i*36; CreateRectangle(VUI("JBG_"+IntegerToString(i)),x+10,ry,296,30,RP_CARD_2,RP_BORDER);
         CreateLabel(VUI("JROW_"+IntegerToString(i)),"",x+17,ry+8,8,RP_TEXT);
        }
      CreateLabel(VUI("JNOTE"),"Screenshots grouped by Tehran date",x+12,y+414,8,RP_MUTED);
      return;
     }

   CreateLabel(VUI("BE_L"),"RISK FREE",x+12,y+48,8,RP_MUTED);
   CreateButton(VUI("BE"),v_use_be?"ON":"OFF",x+84,y+41,48,28,v_use_be?RP_GREEN_2:RP_CARD,RP_TEXT,v_use_be?RP_GREEN_2:RP_BORDER);
   CreateButton(VUI("BEMODE"),v_be_mode==RP_TRIGGER_RR?"R":"PIPS",x+138,y+41,48,28,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(VUI("BETRIG"),DoubleToString(v_be_mode==RP_TRIGGER_RR?v_be_r:v_be_pips,2),x+192,y+41,52,28);
   CreateEdit(VUI("BELOCK"),DoubleToString(v_be_lock_pips,1),x+250,y+41,54,28);

   CreateLabel(VUI("PART_L"),"SAVE PROFIT",x+12,y+84,8,RP_MUTED);
   CreateButton(VUI("PART"),v_use_partial?"ON":"OFF",x+84,y+77,48,28,v_use_partial?RP_GREEN_2:RP_CARD,RP_TEXT,v_use_partial?RP_GREEN_2:RP_BORDER);
   CreateButton(VUI("PARTMODE"),v_partial_mode==RP_TRIGGER_RR?"R":"PIPS",x+138,y+77,48,28,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(VUI("PARTTRIG"),DoubleToString(v_partial_mode==RP_TRIGGER_RR?v_partial_r:v_partial_pips,2),x+192,y+77,52,28);
   CreateEdit(VUI("PARTPCT"),DoubleToString(v_partial_pct,0),x+250,y+77,54,28);

   CreateLabel(VUI("TR_L"),"TRAILING",x+12,y+120,8,RP_MUTED);
   CreateButton(VUI("TRAIL"),v_use_trailing?"ON":"OFF",x+84,y+113,48,28,v_use_trailing?RP_GREEN_2:RP_CARD,RP_TEXT,v_use_trailing?RP_GREEN_2:RP_BORDER);
   CreateButton(VUI("TRMODE"),v_trailing_mode==RP_TRIGGER_RR?"R":"PIPS",x+138,y+113,48,28,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(VUI("TRSTART"),DoubleToString(v_trailing_mode==RP_TRIGGER_RR?v_trail_start_r:v_trail_start_pips,2),x+192,y+113,52,28);
   CreateEdit(VUI("TRDIST"),DoubleToString(v_trailing_mode==RP_TRIGGER_RR?v_trail_distance_r:v_trail_distance_pips,2),x+250,y+113,54,28);
   CreateLabel(VUI("TRHINT"),"trigger/start      distance      step below",x+84,y+146,7,RP_MUTED);
   CreateEdit(VUI("TRSTEP"),DoubleToString(v_trailing_mode==RP_TRIGGER_RR?v_trail_step_r:v_trail_step_pips,2),x+250,y+157,54,27);

   CreateLabel(VUI("GUARDS"),"ENTRY GUARDS",x+12,y+202,8,RP_MUTED);
   CreateButton(VUI("NEWS"),v_news_guard?"NEWS BLOCK":"NEWS ALLOW",x+12,y+218,92,29,v_news_guard?RP_RED_2:RP_GREEN_2,RP_TEXT,v_news_guard?RP_RED_2:RP_GREEN_2);
   CreateEdit(VUI("NBEFORE"),IntegerToString(v_news_before),x+110,y+218,42,29);
   CreateEdit(VUI("NAFTER"),IntegerToString(v_news_after),x+158,y+218,42,29);
   CreateButton(VUI("HEDGE"),"HEDGE "+VHedgeText(),x+206,y+218,98,29,RP_CARD,RP_TEXT,RP_BORDER);

   CreateButton(VUI("MANUAL"),v_manage_manual?"MANUAL ON":"MANUAL OFF",x+12,y+255,92,29,v_manage_manual?RP_GREEN_2:RP_CARD,RP_TEXT,v_manage_manual?RP_GREEN_2:RP_BORDER);
   CreateButton(VUI("OVER"),v_overtrade_guard?"OVER ON":"OVER OFF",x+110,y+255,90,29,v_overtrade_guard?RP_GREEN_2:RP_CARD,RP_TEXT,v_overtrade_guard?RP_GREEN_2:RP_BORDER);
   CreateLabel(VUI("MAXH"),"MAX T / P / O",x+212,y+264,7,RP_MUTED);
   CreateEdit(VUI("MAXT"),IntegerToString(v_max_daily_trades),x+12,y+292,50,27);
   CreateEdit(VUI("MAXP"),IntegerToString(v_max_open_positions),x+68,y+292,50,27);
   CreateEdit(VUI("MAXO"),IntegerToString(v_max_pending_orders),x+124,y+292,50,27);
   CreateLabel(VUI("MAXNOTE"),"trades / positions / pending",x+184,y+300,7,RP_MUTED);

   CreateButton(VUI("SHOT"),"TAKE SCREENSHOT",x+12,y+337,138,29,RP_CARD,RP_BLUE,RP_BORDER);
   CreateButton(VUI("SHOWPATH"),"JOURNAL PATH",x+158,y+337,146,29,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(VUI("COST"),StringFormat("Smart BE: spread %s • commission %s • +%.1f pip buffer",
               InpV150CoverLiveSpread?"ON":"OFF",InpV150CoverCommissionAndFees?"ON":"OFF",InpV150ExtraBreakEvenBufferPips),x+12,y+382,7,RP_MUTED);
   CreateLabel(VUI("TEHRAN"),"Daily limits + weekday boundaries: TEHRAN UTC+03:30",x+12,y+404,7,RP_MUTED);
   CreateLabel(VUI("NOTE"),"Runtime changes are saved automatically",x+12,y+426,7,RP_MUTED);
  }

void VUpdateJournalRows()
  {
   if(!v_journal_view || g_collapsed || g_active_tab!=RP_TAB_MANAGE) return;
   datetime from=0,to=0; TehranDayBoundsInServerTime(from,to); to=ServerNow(); int row=0;
   if(HistorySelect(from,to))
     {
      for(int i=HistoryDealsTotal()-1;i>=0 && row<7;i--)
        {
         ulong deal=HistoryDealGetTicket(i); if(deal==0) continue;
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
         ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
         if((entry!=DEAL_ENTRY_IN && entry!=DEAL_ENTRY_INOUT) || (type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL) || !VManagedMagic(HistoryDealGetInteger(deal,DEAL_MAGIC))) continue;
         datetime server=(datetime)HistoryDealGetInteger(deal,DEAL_TIME); datetime tt=(datetime)((long)server-ServerUTCOffsetSeconds()+TehranOffsetSeconds());
         string text=StringFormat("%s  %-9s %-4s  #%05u",TimeToString(tt,TIME_MINUTES),HistoryDealGetString(deal,DEAL_SYMBOL),type==DEAL_TYPE_BUY?"BUY":"SELL",(uint)(deal%100000));
         SetLabelText("V150_JROW_"+IntegerToString(row),text,type==DEAL_TYPE_BUY?RP_GREEN:RP_RED); row++;
        }
     }
   for(int i=row;i<7;i++) SetLabelText("V150_JROW_"+IntegerToString(i),i==0?"No managed entries today":"",RP_MUTED);
  }

void VRebuildAddon()
  {
   ObjectsDeleteAll(0,g_ui_prefix+"V150_");
   // BuildPanel reset is not required; custom objects use the existing registry
   // and therefore move together with the main panel while dragging.
   VBuildControlsPanel();
   VUpdateJournalRows();
   ChartRedraw();
  }

void VOverridePanelData()
  {
   double realized=0.0,floating=0.0; int trades=0; VDailyStats(realized,floating,trades);
   double result=realized+(InpIncludeFloatingInDailyLoss?floating:0.0);
   if(g_collapsed)
      SetLabelText("MINI_STATS",StringFormat("Tehran day %+.2f | Risk %.2f%s",result,g_risk_value,RiskUnit()),RP_MUTED);
   else if(g_active_tab==RP_TAB_TRADE)
     {
      SetLabelText("DAY_PL",StringFormat("Tehran P/L %+.2f (%d)",result,trades),result>=0?RP_GREEN:RP_RED);
      string reason=""; bool enabled=VBasicGuards(reason);
      if(enabled)
        {
         SetButtonPalette("BUY_NOW",RP_GREEN,RP_WHITE,RP_GREEN); SetButtonPalette("SELL_NOW",RP_RED,RP_WHITE,RP_RED); SetButtonPalette("PLACE",RP_BLUE,RP_BG,RP_BLUE);
        }
      else
        {
         SetButtonPalette("BUY_NOW",RP_CARD,RP_MUTED,RP_BORDER); SetButtonPalette("SELL_NOW",RP_CARD,RP_MUTED,RP_BORDER); SetButtonPalette("PLACE",RP_CARD,RP_MUTED,RP_BORDER);
        }
     }
   else if(g_active_tab==RP_TAB_MANAGE)
     {
      int lock=0; bool locked=VDailyLocked(lock);
      SetLabelText("GUARD_STATE",locked?(lock==1?"LOCKED • TEHRAN LOSS":"LOCKED • TEHRAN PROFIT"):"UNLOCKED • TEHRAN DAY",locked?RP_RED:RP_GREEN);
      SetLabelText("GUARD_DAY",StringFormat("Tehran P/L %+.2f • %d trade(s)",result,trades),result>=0?RP_GREEN:RP_RED);
      string news=""; bool paused=VNewsPause(news); SetLabelText("NEWS_STATE",paused?news:(v_news_guard?"News guard active":"Trading during news allowed"),paused?RP_RED:(v_news_guard?RP_MUTED:RP_GREEN));
      SetLabelText("AUTO_BE",v_use_be?"BE ON • "+TriggerSummary(v_be_mode,v_be_r,v_be_pips):"BE OFF",v_use_be?RP_GREEN:RP_MUTED);
      SetLabelText("AUTO_PARTIAL",v_use_partial?StringFormat("PART ON • %.0f%% @ %s",v_partial_pct,TriggerSummary(v_partial_mode,v_partial_r,v_partial_pips)):"PART OFF",v_use_partial?RP_GREEN:RP_MUTED);
      SetLabelText("AUTO_TRAIL",v_use_trailing?"TRAIL ON • "+TriggerSummary(v_trailing_mode,v_trail_start_r,v_trail_start_pips):"TRAIL OFF",v_use_trailing?RP_GREEN:RP_MUTED);
      SetLabelText("HEDGE_STATE","HEDGE "+VHedgeText(),v_hedge_policy==RP_HEDGE_ALLOW?RP_AMBER:RP_TEXT);
      VUpdateJournalRows();
     }
  }

void VToggle(bool &value,const string title)
  {
   value=!value; VSaveRuntime(); SetStatus(title+(value?" ON":" OFF"),value?RP_GREEN:RP_AMBER,5); VRebuildAddon(); VOverridePanelData();
  }

void VCycleHedge()
  {
   if(v_hedge_policy==RP_HEDGE_WARN) v_hedge_policy=RP_HEDGE_ALLOW;
   else if(v_hedge_policy==RP_HEDGE_ALLOW) v_hedge_policy=RP_HEDGE_BLOCK;
   else v_hedge_policy=RP_HEDGE_WARN;
   VSaveRuntime(); SetStatus("Hedge policy: "+VHedgeText(),RP_BLUE,5); VRebuildAddon(); VOverridePanelData();
  }

void VToggleMode(ENUM_RP_TRIGGER_MODE &mode)
  {
   mode=(mode==RP_TRIGGER_RR?RP_TRIGGER_PIPS:RP_TRIGGER_RR); VSaveRuntime(); VRebuildAddon();
  }

void VReadEdit(const string name)
  {
   double value=StringToDouble(ObjectGetString(0,name,OBJPROP_TEXT));
   if(name==VUI("BETRIG") && value>0.0) { if(v_be_mode==RP_TRIGGER_RR) v_be_r=ClampDouble(value,0.05,20.0); else v_be_pips=ClampDouble(value,0.1,10000.0); }
   else if(name==VUI("BELOCK")) v_be_lock_pips=ClampDouble(value,0.0,10000.0);
   else if(name==VUI("PARTTRIG") && value>0.0) { if(v_partial_mode==RP_TRIGGER_RR) v_partial_r=ClampDouble(value,0.05,20.0); else v_partial_pips=ClampDouble(value,0.1,10000.0); }
   else if(name==VUI("PARTPCT")) v_partial_pct=ClampDouble(value,1.0,99.0);
   else if(name==VUI("TRSTART") && value>0.0) { if(v_trailing_mode==RP_TRIGGER_RR) v_trail_start_r=ClampDouble(value,0.05,20.0); else v_trail_start_pips=ClampDouble(value,0.1,10000.0); }
   else if(name==VUI("TRDIST") && value>0.0) { if(v_trailing_mode==RP_TRIGGER_RR) v_trail_distance_r=ClampDouble(value,0.01,20.0); else v_trail_distance_pips=ClampDouble(value,0.1,10000.0); }
   else if(name==VUI("TRSTEP") && value>0.0) { if(v_trailing_mode==RP_TRIGGER_RR) v_trail_step_r=ClampDouble(value,0.01,20.0); else v_trail_step_pips=ClampDouble(value,0.1,10000.0); }
   else if(name==VUI("NBEFORE")) v_news_before=(int)ClampDouble(value,0,240);
   else if(name==VUI("NAFTER")) v_news_after=(int)ClampDouble(value,0,240);
   else if(name==VUI("MAXT")) v_max_daily_trades=(int)ClampDouble(value,0,1000);
   else if(name==VUI("MAXP")) v_max_open_positions=(int)ClampDouble(value,0,1000);
   else if(name==VUI("MAXO")) v_max_pending_orders=(int)ClampDouble(value,0,1000);
   VSaveRuntime(); VRebuildAddon(); VOverridePanelData();
  }

bool VIsEdit(const string name)
  {
   return(name==VUI("BETRIG") || name==VUI("BELOCK") || name==VUI("PARTTRIG") || name==VUI("PARTPCT") ||
          name==VUI("TRSTART") || name==VUI("TRDIST") || name==VUI("TRSTEP") || name==VUI("NBEFORE") ||
          name==VUI("NAFTER") || name==VUI("MAXT") || name==VUI("MAXP") || name==VUI("MAXO"));
  }

bool VHandleButton(const string name)
  {
   if(name==VUI("VIEW")) { v_journal_view=!v_journal_view; VRebuildAddon(); return true; }
   if(name==VUI("BE")) { VToggle(v_use_be,"Automatic risk-free"); return true; }
   if(name==VUI("BEMODE")) { VToggleMode(v_be_mode); return true; }
   if(name==VUI("PART")) { VToggle(v_use_partial,"Automatic save-profit"); return true; }
   if(name==VUI("PARTMODE")) { VToggleMode(v_partial_mode); return true; }
   if(name==VUI("TRAIL")) { VToggle(v_use_trailing,"Trailing stop"); return true; }
   if(name==VUI("TRMODE")) { VToggleMode(v_trailing_mode); return true; }
   if(name==VUI("NEWS")) { VToggle(v_news_guard,"News blocking"); return true; }
   if(name==VUI("HEDGE")) { VCycleHedge(); return true; }
   if(name==VUI("MANUAL")) { VToggle(v_manage_manual,"Manual trade management"); return true; }
   if(name==VUI("OVER")) { VToggle(v_overtrade_guard,"Overtrading guard"); return true; }
   if(name==VUI("SHOT")) { VTakeScreenshot(); return true; }
   if(name==VUI("SHOWPATH")) { SetStatus("Journal: MQL5\\Files\\"+InpScreenshotFolder,RP_BLUE,10); Print("ArkoRisk journal path: ",TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL5\\Files\\",InpScreenshotFolder); return true; }
   return false;
  }

//+------------------------------------------------------------------+
//| Standard v1.50 event handlers                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   int result=ArkoCore_OnInit();
   if(result!=INIT_SUCCEEDED) return result;
   VInitRuntime();
   v_day_prefix=g_prefix+"TEHRAN_DAY_";
   v_last_tehran_day=0;
   VDrawDayMarkers(true);
   VRebuildAddon();
   VOverridePanelData();
   SetStatus("ArkoRisk v1.50 ready • Smart BE uses live trading costs",RP_BLUE,7);
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   VSaveRuntime();
   VDeleteDayMarkers();
   ArkoCore_OnDeinit(reason);
  }

void OnTick()
  {
   VManageOpenPositions();
  }

void OnTimer()
  {
   VEnforceDailyGuard();
   if(v_news_guard) RefreshEconomicNews(false,false);
   if(g_panel_dragging && GetTickCount64()-g_last_panel_drag_event_ms>2000) FinishPanelDrag(true);
   if(g_panel_dragging) return;
   VCancelStalePending();
   VProcessScreenshotQueue();
   UpdateCandleTimer();
   datetime today=TehranDayStart();
   if(today!=v_last_tehran_day)
     {
      VDrawDayMarkers(true);
      DrawSessionMarkers(true); // session labels stay Tehran-based and refresh on Tehran midnight
     }
   else DrawSessionMarkers(false);
   UpdatePanel();
   VOverridePanelData();
   ChartRedraw();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   g_daily_stats_cache_time=0;
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD && trans.deal>0) VQueueScreenshot(trans.deal);
   if(!g_panel_dragging) { UpdatePanel(); VOverridePanelData(); }
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      ReleaseButton(sparam);
      if(VHandleButton(sparam)) { ChartRedraw(); return; }
      // Intercept legacy execution/management buttons so they use runtime state.
      if(sparam==UI("BUY_NOW")) { VPlaceMarket(true); return; }
      if(sparam==UI("SELL_NOW")) { VPlaceMarket(false); return; }
      if(sparam==UI("PLACE")) { VPlaceLimit(); return; }
      if(sparam==UI("BE_ALL")) { VBreakEvenAll(); return; }
      if(sparam==UI("HALF_ALL")) { VCloseHalfAll(); return; }
      if(sparam==UI("CLOSE_PROFIT")) { VCloseByProfit(true); return; }
      if(sparam==UI("CLOSE_LOSS")) { VCloseByProfit(false); return; }
      if(sparam==UI("CLOSE_ALL")) { VCloseAll(); return; }
      if(sparam==UI("CANCEL_PENDING")) { VCancelPending(); return; }
      if(sparam==UI("REVERSE")) { VReverse(); return; }
     }

   if(id==CHARTEVENT_OBJECT_ENDEDIT && VIsEdit(sparam))
     {
      VReadEdit(sparam); return;
     }

   if(id==CHARTEVENT_KEYDOWN && InpEnableHotkeys)
     {
      int key=(int)lparam;
      if(key==66) { VPlaceMarket(true); return; }
      if(key==83) { VPlaceMarket(false); return; }
      if(key==13) { VPlaceLimit(); return; }
     }

   ArkoCore_OnChartEvent(id,lparam,dparam,sparam);

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam==UI("TAB_MANAGE") || sparam==UI("TAB_TRADE") || sparam==UI("TAB_NEWS") || sparam==UI("TAB_CHART") || sparam==UI("COLLAPSE"))
         VRebuildAddon();
     }
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      VDrawDayMarkers(true);
      if(g_active_tab==RP_TAB_MANAGE && !g_collapsed) VRebuildAddon();
     }
   VOverridePanelData();
  }
