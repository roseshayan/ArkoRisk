from pathlib import Path

PATH = Path('MQL5/Experts/ArkoRisk/ArkoRisk.mq5')
text = PATH.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str):
    global text
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly one anchor, found {count}')
    text = text.replace(old, new, 1)


def replace_all(old: str, new: str, label: str, minimum: int = 1):
    global text
    count = text.count(old)
    if count < minimum:
        raise SystemExit(f'{label}: expected at least {minimum} anchor(s), found {count}')
    text = text.replace(old, new)
    return count

# -----------------------------------------------------------------------------
# Version and inputs
# -----------------------------------------------------------------------------
replace_once('#property version   "1.40"', '#property version   "1.50"', 'version')

replace_once(
'''enum ENUM_RP_PANEL_TAB
  {
   RP_TAB_TRADE = 0,
   RP_TAB_MANAGE= 1,
   RP_TAB_NEWS  = 2,
   RP_TAB_CHART = 3
  };''',
'''enum ENUM_RP_PANEL_TAB
  {
   RP_TAB_TRADE   = 0,
   RP_TAB_MANAGE  = 1,
   RP_TAB_NEWS    = 2,
   RP_TAB_JOURNAL = 3,
   RP_TAB_CHART   = 4
  };''',
'panel enum')

replace_once(
'''input double             InpBreakEvenLockPips           = 0.0;
input int                InpBreakEvenPlusPoints         = 2;''',
'''input double             InpBreakEvenLockPips           = 0.0;
input int                InpBreakEvenPlusPoints         = 2;
input bool               InpBreakEvenCoverSpread        = true;  // add live spread to protected break-even
input bool               InpBreakEvenCoverCommission    = true;  // cover commission/fee and negative swap where possible
input double             InpCommissionPerLotRoundTurn   = 0.0;   // account currency per 1 lot; 0 = estimate from history''',
'break-even cost inputs')

# -----------------------------------------------------------------------------
# Runtime state
# -----------------------------------------------------------------------------
replace_once(
'''string g_timer_name = "";
string g_session_prefix = "";''',
'''string g_timer_name = "";
string g_session_prefix = "";
string g_day_prefix = "";''',
'day prefix')

replace_once(
'''bool   g_timer_visible = true;
int    g_panel_drag_offset_x = 0;''',
'''bool   g_timer_visible = true;

// Runtime controls. Inputs are immutable in MQL5, so panel changes live here.
bool   g_manage_manual_positions = false;
bool   g_use_break_even = true;
bool   g_use_partial_close = true;
bool   g_use_trailing = false;
bool   g_use_news_auto_pause = true;
bool   g_overtrade_guard_enabled = true;
ENUM_RP_HEDGE_POLICY g_runtime_hedge_policy = RP_HEDGE_WARN;
ENUM_RP_TRIGGER_MODE g_be_trigger_mode = RP_TRIGGER_RR;
ENUM_RP_TRIGGER_MODE g_partial_trigger_mode = RP_TRIGGER_RR;
ENUM_RP_TRIGGER_MODE g_trailing_mode = RP_TRIGGER_PIPS;
double g_be_at_r = 1.0;
double g_be_at_pips = 10.0;
double g_be_lock_pips = 0.0;
double g_partial_at_r = 1.0;
double g_partial_at_pips = 10.0;
double g_partial_percent = 50.0;
double g_trail_start_r = 1.5;
double g_trail_distance_r = 0.5;
double g_trail_step_r = 0.1;
double g_trail_start_pips = 15.0;
double g_trail_distance_pips = 8.0;
double g_trail_step_pips = 2.0;
int    g_news_before_minutes = 15;
int    g_news_after_minutes = 15;
int    g_max_daily_trades = 20;
int    g_max_open_positions = 5;
int    g_max_pending_orders = 10;
datetime g_last_day_marker_refresh = 0;
datetime g_commission_cache_time = 0;
double g_commission_one_way_per_lot_cache = 0.0;

int    g_panel_drag_offset_x = 0;''',
'runtime globals')

replace_once('int    g_panel_h    = 455;', 'int    g_panel_h    = 530;', 'panel height')

# -----------------------------------------------------------------------------
# Runtime persistence helpers and Tehran weekday helpers
# -----------------------------------------------------------------------------
anchor = '''datetime TehranDayStart()
  {
   MqlDateTime tm={};
   TimeToStruct(TehranNow(),tm);
   tm.hour=0;
   tm.min=0;
   tm.sec=0;
   return StructToTime(tm);
  }
'''
insert = anchor + r'''
string RuntimeKey(const string suffix)
  {
   return StringFormat("ARKO_RT_%I64d_%I64u_%s",AccountInfoInteger(ACCOUNT_LOGIN),InpMagicNumber,suffix);
  }

void SaveRuntimeState()
  {
   GlobalVariableSet(RuntimeKey("MANUAL"),g_manage_manual_positions?1.0:0.0);
   GlobalVariableSet(RuntimeKey("BE"),g_use_break_even?1.0:0.0);
   GlobalVariableSet(RuntimeKey("PART"),g_use_partial_close?1.0:0.0);
   GlobalVariableSet(RuntimeKey("TRAIL"),g_use_trailing?1.0:0.0);
   GlobalVariableSet(RuntimeKey("NEWS"),g_use_news_auto_pause?1.0:0.0);
   GlobalVariableSet(RuntimeKey("OVER"),g_overtrade_guard_enabled?1.0:0.0);
   GlobalVariableSet(RuntimeKey("HEDGE"),(double)g_runtime_hedge_policy);
   GlobalVariableSet(RuntimeKey("BEMODE"),(double)g_be_trigger_mode);
   GlobalVariableSet(RuntimeKey("BE_R"),g_be_at_r);
   GlobalVariableSet(RuntimeKey("BE_P"),g_be_at_pips);
   GlobalVariableSet(RuntimeKey("BE_LOCK"),g_be_lock_pips);
   GlobalVariableSet(RuntimeKey("PMODE"),(double)g_partial_trigger_mode);
   GlobalVariableSet(RuntimeKey("P_R"),g_partial_at_r);
   GlobalVariableSet(RuntimeKey("P_P"),g_partial_at_pips);
   GlobalVariableSet(RuntimeKey("P_PCT"),g_partial_percent);
   GlobalVariableSet(RuntimeKey("TMODE"),(double)g_trailing_mode);
   GlobalVariableSet(RuntimeKey("T_R"),g_trail_start_r);
   GlobalVariableSet(RuntimeKey("T_P"),g_trail_start_pips);
   GlobalVariableSet(RuntimeKey("T_DIST_R"),g_trail_distance_r);
   GlobalVariableSet(RuntimeKey("T_DIST_P"),g_trail_distance_pips);
   GlobalVariableSet(RuntimeKey("T_STEP_R"),g_trail_step_r);
   GlobalVariableSet(RuntimeKey("T_STEP_P"),g_trail_step_pips);
   GlobalVariableSet(RuntimeKey("NEWS_B"),(double)g_news_before_minutes);
   GlobalVariableSet(RuntimeKey("NEWS_A"),(double)g_news_after_minutes);
   GlobalVariableSet(RuntimeKey("MAX_T"),(double)g_max_daily_trades);
   GlobalVariableSet(RuntimeKey("MAX_P"),(double)g_max_open_positions);
   GlobalVariableSet(RuntimeKey("MAX_O"),(double)g_max_pending_orders);
  }

void InitRuntimeState()
  {
   g_manage_manual_positions=InpManageManualPositions;
   g_use_break_even=InpUseBreakEven;
   g_use_partial_close=InpUsePartialClose;
   g_use_trailing=InpUseTrailing;
   g_use_news_auto_pause=InpUseNewsAutoPause;
   g_runtime_hedge_policy=InpHedgePolicy;
   g_be_trigger_mode=InpBreakEvenTriggerMode;
   g_be_at_r=InpBreakEvenAtR;
   g_be_at_pips=InpBreakEvenAtPips;
   g_be_lock_pips=InpBreakEvenLockPips;
   g_partial_trigger_mode=InpPartialTriggerMode;
   g_partial_at_r=InpPartialCloseAtR;
   g_partial_at_pips=InpPartialCloseAtPips;
   g_partial_percent=InpPartialClosePercent;
   g_trailing_mode=InpTrailingMode;
   g_trail_start_r=InpTrailStartAtR;
   g_trail_start_pips=InpTrailStartPips;
   g_trail_distance_r=InpTrailDistanceR;
   g_trail_distance_pips=InpTrailDistancePips;
   g_trail_step_r=InpTrailStepR;
   g_trail_step_pips=InpTrailStepPips;
   g_news_before_minutes=InpNewsPauseMinutesBefore;
   g_news_after_minutes=InpNewsPauseMinutesAfter;
   g_max_daily_trades=InpMaxDailyTrades;
   g_max_open_positions=InpMaxOpenPositions;
   g_max_pending_orders=InpMaxPendingOrders;

   if(GlobalVariableCheck(RuntimeKey("MANUAL"))) g_manage_manual_positions=(GlobalVariableGet(RuntimeKey("MANUAL"))>0.5);
   if(GlobalVariableCheck(RuntimeKey("BE"))) g_use_break_even=(GlobalVariableGet(RuntimeKey("BE"))>0.5);
   if(GlobalVariableCheck(RuntimeKey("PART"))) g_use_partial_close=(GlobalVariableGet(RuntimeKey("PART"))>0.5);
   if(GlobalVariableCheck(RuntimeKey("TRAIL"))) g_use_trailing=(GlobalVariableGet(RuntimeKey("TRAIL"))>0.5);
   if(GlobalVariableCheck(RuntimeKey("NEWS"))) g_use_news_auto_pause=(GlobalVariableGet(RuntimeKey("NEWS"))>0.5);
   if(GlobalVariableCheck(RuntimeKey("OVER"))) g_overtrade_guard_enabled=(GlobalVariableGet(RuntimeKey("OVER"))>0.5);
   if(GlobalVariableCheck(RuntimeKey("HEDGE"))) g_runtime_hedge_policy=(ENUM_RP_HEDGE_POLICY)(int)GlobalVariableGet(RuntimeKey("HEDGE"));
   if(GlobalVariableCheck(RuntimeKey("BEMODE"))) g_be_trigger_mode=(ENUM_RP_TRIGGER_MODE)(int)GlobalVariableGet(RuntimeKey("BEMODE"));
   if(GlobalVariableCheck(RuntimeKey("BE_R"))) g_be_at_r=GlobalVariableGet(RuntimeKey("BE_R"));
   if(GlobalVariableCheck(RuntimeKey("BE_P"))) g_be_at_pips=GlobalVariableGet(RuntimeKey("BE_P"));
   if(GlobalVariableCheck(RuntimeKey("BE_LOCK"))) g_be_lock_pips=GlobalVariableGet(RuntimeKey("BE_LOCK"));
   if(GlobalVariableCheck(RuntimeKey("PMODE"))) g_partial_trigger_mode=(ENUM_RP_TRIGGER_MODE)(int)GlobalVariableGet(RuntimeKey("PMODE"));
   if(GlobalVariableCheck(RuntimeKey("P_R"))) g_partial_at_r=GlobalVariableGet(RuntimeKey("P_R"));
   if(GlobalVariableCheck(RuntimeKey("P_P"))) g_partial_at_pips=GlobalVariableGet(RuntimeKey("P_P"));
   if(GlobalVariableCheck(RuntimeKey("P_PCT"))) g_partial_percent=GlobalVariableGet(RuntimeKey("P_PCT"));
   if(GlobalVariableCheck(RuntimeKey("TMODE"))) g_trailing_mode=(ENUM_RP_TRIGGER_MODE)(int)GlobalVariableGet(RuntimeKey("TMODE"));
   if(GlobalVariableCheck(RuntimeKey("T_R"))) g_trail_start_r=GlobalVariableGet(RuntimeKey("T_R"));
   if(GlobalVariableCheck(RuntimeKey("T_P"))) g_trail_start_pips=GlobalVariableGet(RuntimeKey("T_P"));
   if(GlobalVariableCheck(RuntimeKey("T_DIST_R"))) g_trail_distance_r=GlobalVariableGet(RuntimeKey("T_DIST_R"));
   if(GlobalVariableCheck(RuntimeKey("T_DIST_P"))) g_trail_distance_pips=GlobalVariableGet(RuntimeKey("T_DIST_P"));
   if(GlobalVariableCheck(RuntimeKey("T_STEP_R"))) g_trail_step_r=GlobalVariableGet(RuntimeKey("T_STEP_R"));
   if(GlobalVariableCheck(RuntimeKey("T_STEP_P"))) g_trail_step_pips=GlobalVariableGet(RuntimeKey("T_STEP_P"));
   if(GlobalVariableCheck(RuntimeKey("NEWS_B"))) g_news_before_minutes=(int)GlobalVariableGet(RuntimeKey("NEWS_B"));
   if(GlobalVariableCheck(RuntimeKey("NEWS_A"))) g_news_after_minutes=(int)GlobalVariableGet(RuntimeKey("NEWS_A"));
   if(GlobalVariableCheck(RuntimeKey("MAX_T"))) g_max_daily_trades=(int)GlobalVariableGet(RuntimeKey("MAX_T"));
   if(GlobalVariableCheck(RuntimeKey("MAX_P"))) g_max_open_positions=(int)GlobalVariableGet(RuntimeKey("MAX_P"));
   if(GlobalVariableCheck(RuntimeKey("MAX_O"))) g_max_pending_orders=(int)GlobalVariableGet(RuntimeKey("MAX_O"));
  }

string TehranWeekdayName(const int day_of_week)
  {
   if(day_of_week==0) return "SUNDAY";
   if(day_of_week==1) return "MONDAY";
   if(day_of_week==2) return "TUESDAY";
   if(day_of_week==3) return "WEDNESDAY";
   if(day_of_week==4) return "THURSDAY";
   if(day_of_week==5) return "FRIDAY";
   return "SATURDAY";
  }
'''
replace_once(anchor, insert, 'runtime helpers')

# -----------------------------------------------------------------------------
# News runtime state
# -----------------------------------------------------------------------------
replace_all('MathMax(InpNewsPauseMinutesBefore,InpNewsPauseMinutesAfter)', 'MathMax(g_news_before_minutes,g_news_after_minutes)', 'news margin')
replace_once('if(!InpUseNewsAutoPause)\n      return false;', 'if(!g_use_news_auto_pause)\n      return false;', 'news runtime toggle')
replace_once('int before=MathMax(0,InpNewsPauseMinutesBefore)*60;\n   int after=MathMax(0,InpNewsPauseMinutesAfter)*60;', 'int before=MathMax(0,g_news_before_minutes)*60;\n   int after=MathMax(0,g_news_after_minutes)*60;', 'news runtime window')

# -----------------------------------------------------------------------------
# Tehran-day statistics and guards
# -----------------------------------------------------------------------------
replace_once('''   datetime from=StartOfServerDay();
   datetime to=ServerNow();''', '''   datetime from=0,to=0;
   TehranDayBoundsInServerTime(from,to);
   to=MathMin(to,ServerNow());''', 'daily stats Tehran bounds')

# Scope manual trades when runtime management is enabled.
replace_once(
'''   if(magic!=(long)InpMagicNumber)
      return false;
   if(InpDailyGuardScope==RP_SCOPE_EA_SYMBOL && symbol_name!=_Symbol)''',
'''   bool managed_magic=(magic==(long)InpMagicNumber || (g_manage_manual_positions && magic==0));
   if(!managed_magic)
      return false;
   if(InpDailyGuardScope==RP_SCOPE_EA_SYMBOL && symbol_name!=_Symbol)''',
'scope manual')

replace_all('StartOfServerDay()', 'TehranDayStart()', 'guard day boundary', minimum=5)

# -----------------------------------------------------------------------------
# Spread-aware broker safety
# -----------------------------------------------------------------------------
replace_once('base=MathMax(base,spread*0.25+rounding_buffer);', 'base=MathMax(base,spread+rounding_buffer);', 'full spread stop safety')

# -----------------------------------------------------------------------------
# Runtime manual position / pending selection
# -----------------------------------------------------------------------------
replace_all('InpManageManualPositions && magic==0', 'g_manage_manual_positions && magic==0', 'manual runtime', minimum=4)
replace_once('return(InpManageManualPositions && magic==0);', 'return(g_manage_manual_positions && magic==0);', 'manual selected runtime')

# Pending count and cancellation should include manual pending orders when enabled.
replace_once(
'''      if(magic==(long)InpMagicNumber && (!current_symbol_only || symbol_name==_Symbol))
         count++;''',
'''      bool managed=(magic==(long)InpMagicNumber || (g_manage_manual_positions && magic==0));
      if(managed && (!current_symbol_only || symbol_name==_Symbol))
         count++;''',
'managed pending count')

# -----------------------------------------------------------------------------
# Runtime overtrading and hedge policy
# -----------------------------------------------------------------------------
replace_once(
'''   if(InpMaxDailyTrades>0 && trades>=InpMaxDailyTrades)
     {
      reason=StringFormat("Daily trade limit reached (%d)",InpMaxDailyTrades);
      return false;
     }
   if(!ignore_position_limits && InpMaxOpenPositions>0 && ManagedPositionCount(false)>=InpMaxOpenPositions)
     {
      reason=StringFormat("Open-position limit reached (%d)",InpMaxOpenPositions);
      return false;
     }''',
'''   if(g_overtrade_guard_enabled && g_max_daily_trades>0 && trades>=g_max_daily_trades)
     {
      reason=StringFormat("Daily trade limit reached (%d)",g_max_daily_trades);
      return false;
     }
   if(g_overtrade_guard_enabled && !ignore_position_limits && g_max_open_positions>0 && ManagedPositionCount(false)>=g_max_open_positions)
     {
      reason=StringFormat("Open-position limit reached (%d)",g_max_open_positions);
      return false;
     }''',
'overtrade runtime')

replace_all('InpHedgePolicy==RP_HEDGE_ALLOW', 'g_runtime_hedge_policy==RP_HEDGE_ALLOW', 'hedge allow', minimum=2)
replace_all('InpHedgePolicy==RP_HEDGE_BLOCK', 'g_runtime_hedge_policy==RP_HEDGE_BLOCK', 'hedge block', minimum=4)

replace_once(
'''   if(InpMaxPendingOrders>0 && ManagedPendingCount(false)>=InpMaxPendingOrders)
     {
      SetStatus(StringFormat("Pending-order limit reached (%d)",InpMaxPendingOrders),RP_RED,7);''',
'''   if(g_overtrade_guard_enabled && g_max_pending_orders>0 && ManagedPendingCount(false)>=g_max_pending_orders)
     {
      SetStatus(StringFormat("Pending-order limit reached (%d)",g_max_pending_orders),RP_RED,7);''',
'pending runtime')

# -----------------------------------------------------------------------------
# Smart break-even cost engine
# -----------------------------------------------------------------------------
manage_anchor = '''void ManageOpenPositions()
  {
'''
smart_be = r'''double EstimateOneWayCommissionPerLot(const string symbol_name)
  {
   datetime now=ServerNow();
   if(g_commission_cache_time>0 && now-g_commission_cache_time<300)
      return g_commission_one_way_per_lot_cache;

   g_commission_cache_time=now;
   g_commission_one_way_per_lot_cache=0.0;
   datetime from=now-30*86400;
   if(!HistorySelect(from,now))
      return 0.0;

   double total_cost=0.0,total_volume=0.0;
   int total=HistoryDealsTotal();
   int sampled=0;
   for(int i=total-1;i>=0 && sampled<200;i--)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=symbol_name)
         continue;
      ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
      if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)
         continue;
      double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
      if(volume<=0.0)
         continue;
      double cost=MathAbs(HistoryDealGetDouble(deal,DEAL_COMMISSION))+MathAbs(HistoryDealGetDouble(deal,DEAL_FEE));
      if(cost<=0.0)
         continue;
      total_cost+=cost;
      total_volume+=volume;
      sampled++;
     }
   if(total_volume>0.0)
      g_commission_one_way_per_lot_cache=total_cost/total_volume;
   return g_commission_one_way_per_lot_cache;
  }

double PositionAccruedTradingCosts(const long identifier)
  {
   double cost=0.0;
   if(identifier<=0 || !HistorySelectByPosition((ulong)identifier))
      return 0.0;
   int total=HistoryDealsTotal();
   for(int i=0;i<total;i++)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0)
         continue;
      cost+=MathAbs(HistoryDealGetDouble(deal,DEAL_COMMISSION));
      cost+=MathAbs(HistoryDealGetDouble(deal,DEAL_FEE));
     }
   return cost;
  }

double MoneyToPriceDistance(const string symbol_name,const bool buy_side,const double entry,
                            const double volume,const double money)
  {
   if(money<=0.0 || volume<=0.0)
      return 0.0;
   double tick_size=SymbolInfoDouble(symbol_name,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0)
      tick_size=SymbolInfoDouble(symbol_name,SYMBOL_POINT);
   if(tick_size<=0.0)
      return 0.0;
   double one_lot_profit=0.0;
   double close_price=(buy_side ? entry+tick_size : entry-tick_size);
   if(!ProfitForOneLotSymbol(symbol_name,buy_side,entry,close_price,one_lot_profit))
      return 0.0;
   double money_per_tick=MathAbs(one_lot_profit)*volume;
   if(money_per_tick<=0.0)
      return 0.0;
   double ticks=MathCeil(money/money_per_tick-1e-12);
   return MathMax(0.0,ticks*tick_size);
  }

double SmartBreakEvenOffset(const ulong position_ticket,const bool buy_side,const double entry,
                            const double volume,const MqlTick &tick)
  {
   double offset=MathMax(MathMax(0.0,g_be_lock_pips)*PipSize(),MathMax(0,InpBreakEvenPlusPoints)*_Point);
   if(InpBreakEvenCoverSpread && tick.ask>tick.bid)
      offset+=tick.ask-tick.bid;

   if(InpBreakEvenCoverCommission && PositionSelectByTicket(position_ticket))
     {
      long identifier=PositionGetInteger(POSITION_IDENTIFIER);
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      double accrued=PositionAccruedTradingCosts(identifier);
      double required_commission=accrued;
      if(InpCommissionPerLotRoundTurn>0.0)
         required_commission=MathMax(required_commission,InpCommissionPerLotRoundTurn*volume);
      else
        {
         double one_way=EstimateOneWayCommissionPerLot(symbol_name);
         double expected_one_way=one_way*volume;
         // If the opening charge already looks like a full round-turn charge,
         // do not add another estimated closing side.
         if(expected_one_way>0.0 && accrued<expected_one_way*1.5)
            required_commission+=expected_one_way;
        }
      double negative_swap=MathMax(0.0,-PositionGetDouble(POSITION_SWAP));
      required_commission+=negative_swap;
      offset+=MoneyToPriceDistance(symbol_name,buy_side,entry,volume,required_commission);
     }
   return offset;
  }

'''
replace_once(manage_anchor, smart_be + manage_anchor, 'smart BE helpers')

# Automatic management uses runtime controls and cost-aware BE.
replace_once(
'''      if(InpUsePartialClose && partial_done<0.5 &&
         TriggerReached(InpPartialTriggerMode,current_r,progress,InpPartialCloseAtR,InpPartialCloseAtPips))''',
'''      if(g_use_partial_close && partial_done<0.5 &&
         TriggerReached(g_partial_trigger_mode,current_r,progress,g_partial_at_r,g_partial_at_pips))''',
'partial runtime trigger')
replace_once('initial_volume*ClampDouble(InpPartialClosePercent,1.0,99.0)/100.0', 'initial_volume*ClampDouble(g_partial_percent,1.0,99.0)/100.0', 'partial percent runtime')

replace_once(
'''      if(InpUseBreakEven &&
         TriggerReached(InpBreakEvenTriggerMode,current_r,progress,InpBreakEvenAtR,InpBreakEvenAtPips))
        {
         double be_offset=(InpBreakEvenLockPips>0.0 ? InpBreakEvenLockPips*PipSize()
                                                     : InpBreakEvenPlusPoints*_Point);
         double be=NormalizePrice(buy_side ? entry+be_offset : entry-be_offset);''',
'''      if(g_use_break_even &&
         TriggerReached(g_be_trigger_mode,current_r,progress,g_be_at_r,g_be_at_pips))
        {
         double be_offset=SmartBreakEvenOffset(ticket,buy_side,entry,current_volume,tick);
         double be=(buy_side ? NormalizePriceUp(entry+be_offset) : NormalizePriceDown(entry-be_offset));''',
'BE runtime smart')

replace_once(
'''      if(InpUseTrailing &&
         TriggerReached(InpTrailingMode,current_r,progress,InpTrailStartAtR,InpTrailStartPips))
        {
         double trail_distance=(InpTrailingMode==RP_TRIGGER_PIPS
                                ? MathMax(0.1,InpTrailDistancePips)*PipSize()
                                : initial_risk*MathMax(0.05,InpTrailDistanceR));''',
'''      if(g_use_trailing &&
         TriggerReached(g_trailing_mode,current_r,progress,g_trail_start_r,g_trail_start_pips))
        {
         double trail_distance=(g_trailing_mode==RP_TRIGGER_PIPS
                                ? MathMax(0.1,g_trail_distance_pips)*PipSize()
                                : initial_risk*MathMax(0.05,g_trail_distance_r));''',
'trailing runtime start')
replace_once(
'''         double step_distance=(InpTrailingMode==RP_TRIGGER_PIPS
                               ? MathMax(0.1,InpTrailStepPips)*PipSize()
                               : initial_risk*MathMax(0.01,InpTrailStepR));''',
'''         double step_distance=(g_trailing_mode==RP_TRIGGER_PIPS
                               ? MathMax(0.1,g_trail_step_pips)*PipSize()
                               : initial_risk*MathMax(0.01,g_trail_step_r));''',
'trailing runtime step')

# Manual break-even button also uses live spread/commission protection.
replace_once(
'''      double be_offset=(InpBreakEvenLockPips>0.0 ? InpBreakEvenLockPips*PipSize()
                                                  : InpBreakEvenPlusPoints*_Point);
      double new_sl=NormalizePrice(buy_side ? entry+be_offset : entry-be_offset);''',
'''      double volume=PositionGetDouble(POSITION_VOLUME);
      double be_offset=SmartBreakEvenOffset(ticket,buy_side,entry,volume,tick);
      double new_sl=(buy_side ? NormalizePriceUp(entry+be_offset) : NormalizePriceDown(entry-be_offset));''',
'BE all smart')

# -----------------------------------------------------------------------------
# Screenshots: manual trades + Tehran date folders + manual screenshot
# -----------------------------------------------------------------------------
replace_once(
'''   if(magic!=(long)InpMagicNumber || symbol_name!=_Symbol ||
      (entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_INOUT) ||''',
'''   bool managed_magic=(magic==(long)InpMagicNumber || (g_manage_manual_positions && magic==0));
   if(!managed_magic || symbol_name!=_Symbol ||
      (entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_INOUT) ||''',
'capture manual')

replace_once(
'''   datetime deal_time=(datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
   MqlDateTime tm={};
   TimeToStruct(deal_time,tm);
   string side=(deal_type==DEAL_TYPE_BUY ? "BUY" : "SELL");
   string safe_symbol=StringSubstr(SafeFileToken(symbol_name),0,10);
   uint short_ticket=(uint)(deal_ticket%100000);
   string filename=StringFormat("%s\\%04d%02d%02d_%02d%02d%02d_%s_%s_%05u.png",
      InpScreenshotFolder,tm.year,tm.mon,tm.day,tm.hour,tm.min,tm.sec,
      safe_symbol,side,short_ticket);''',
'''   datetime deal_time=(datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
   datetime tehran_time=(datetime)((long)deal_time-ServerUTCOffsetSeconds()+TehranOffsetSeconds());
   MqlDateTime tm={};
   TimeToStruct(tehran_time,tm);
   string side=(deal_type==DEAL_TYPE_BUY ? "BUY" : "SELL");
   string safe_symbol=StringSubstr(SafeFileToken(symbol_name),0,10);
   uint short_ticket=(uint)(deal_ticket%100000);
   string date_folder=StringFormat("%s\\%04d-%02d-%02d",InpScreenshotFolder,tm.year,tm.mon,tm.day);
   FolderCreate(date_folder);
   string filename=StringFormat("%s\\%02d%02d%02d_%s_%s_%05u.png",
      date_folder,tm.hour,tm.min,tm.sec,safe_symbol,side,short_ticket);''',
'screenshot Tehran folder')

replace_once(
'''   if(magic!=(long)InpMagicNumber ||
      (entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_INOUT))''',
'''   if(!(magic==(long)InpMagicNumber || (g_manage_manual_positions && magic==0)) ||
      (entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_INOUT))''',
'queue manual')

process_anchor = '''void ProcessScreenshotQueue()
  {
   int size=ArraySize(g_screenshot_queue);
   if(size<=0)
      return;
   ulong deal_ticket=g_screenshot_queue[0];
   for(int i=1;i<size;i++)
      g_screenshot_queue[i-1]=g_screenshot_queue[i];
   ArrayResize(g_screenshot_queue,size-1);
   CaptureEntryScreenshot(deal_ticket);
  }
'''
manual_shot = process_anchor + r'''
void CaptureManualScreenshot()
  {
   if(!InpTakeEntryScreenshot)
     {
      SetStatus("Screenshot journal is disabled in inputs",RP_AMBER,6);
      return;
     }
   FolderCreate("ArkoRisk");
   FolderCreate(InpScreenshotFolder);
   datetime now=TehranNow();
   MqlDateTime tm={};
   TimeToStruct(now,tm);
   string date_folder=StringFormat("%s\\%04d-%02d-%02d",InpScreenshotFolder,tm.year,tm.mon,tm.day);
   FolderCreate(date_folder);
   string safe_symbol=StringSubstr(SafeFileToken(_Symbol),0,10);
   string filename=StringFormat("%s\\%02d%02d%02d_%s_MANUAL.png",date_folder,tm.hour,tm.min,tm.sec,safe_symbol);
   ChartRedraw();
   if(ChartScreenShot(0,filename,MathMax(640,InpScreenshotWidth),MathMax(360,InpScreenshotHeight),ALIGN_RIGHT))
      SetStatus("Screenshot saved: MQL5\\Files\\"+filename,RP_GREEN,8);
   else
      SetStatus(StringFormat("Screenshot failed (%d)",GetLastError()),RP_RED,8);
  }
'''
replace_once(process_anchor, manual_shot, 'manual screenshot')

# -----------------------------------------------------------------------------
# Tehran day separators on chart
# -----------------------------------------------------------------------------
session_delete_anchor = '''void DeleteSessionMarkers()
  {
   if(g_session_prefix!="")
      ObjectsDeleteAll(0,g_session_prefix);
  }
'''
day_marker_code = session_delete_anchor + r'''
void DeleteDayMarkers()
  {
   if(g_day_prefix!="")
      ObjectsDeleteAll(0,g_day_prefix);
  }

void DrawTehranDayMarkers(const bool force=false)
  {
   datetime today=TehranDayStart();
   if(!force && g_last_day_marker_refresh==today)
      return;
   g_last_day_marker_refresh=today;
   DeleteDayMarkers();

   double price_max=0.0,price_min=0.0;
   ChartGetDouble(0,CHART_PRICE_MAX,0,price_max);
   ChartGetDouble(0,CHART_PRICE_MIN,0,price_min);
   double label_price=price_max-(price_max-price_min)*0.01;
   int lookback=MathMax(1,MathMin(20,InpSessionLookbackDays));
   long server_offset=ServerUTCOffsetSeconds();
   for(int i=0;i<lookback;i++)
     {
      datetime tehran_midnight=(datetime)((long)today-(long)i*86400);
      MqlDateTime tm={};
      TimeToStruct(tehran_midnight,tm);
      datetime utc_midnight=(datetime)((long)tehran_midnight-TehranOffsetSeconds());
      datetime server_time=(datetime)((long)utc_midnight+server_offset);
      string id=StringFormat("%04d%02d%02d",tm.year,tm.mon,tm.day);
      string line_name=g_day_prefix+id+"_LINE";
      string text_name=g_day_prefix+id+"_TEXT";
      string label=StringFormat("%s  •  %04d-%02d-%02d  •  TEHRAN",TehranWeekdayName(tm.day_of_week),tm.year,tm.mon,tm.day);
      if(ObjectCreate(0,line_name,OBJ_VLINE,0,server_time,0.0))
        {
         ObjectSetInteger(0,line_name,OBJPROP_COLOR,RP_BORDER);
         ObjectSetInteger(0,line_name,OBJPROP_STYLE,STYLE_DASHDOTDOT);
         ObjectSetInteger(0,line_name,OBJPROP_WIDTH,1);
         ObjectSetInteger(0,line_name,OBJPROP_BACK,true);
         ObjectSetInteger(0,line_name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,line_name,OBJPROP_HIDDEN,true);
         ObjectSetString(0,line_name,OBJPROP_TOOLTIP,label);
        }
      if(ObjectCreate(0,text_name,OBJ_TEXT,0,server_time,label_price))
        {
         ObjectSetString(0,text_name,OBJPROP_TEXT,label);
         ObjectSetString(0,text_name,OBJPROP_FONT,InpPanelFont);
         ObjectSetInteger(0,text_name,OBJPROP_FONTSIZE,8);
         ObjectSetInteger(0,text_name,OBJPROP_COLOR,RP_MUTED);
         ObjectSetInteger(0,text_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0,text_name,OBJPROP_BACK,false);
         ObjectSetInteger(0,text_name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,text_name,OBJPROP_HIDDEN,true);
        }
     }
  }
'''
replace_once(session_delete_anchor, day_marker_code, 'day markers')

# Refresh sessions on Tehran day instead of broker day.
old_session_refresh = '''   datetime now=ServerNow();
   // Session objects are static during a trading day. Rebuilding them only on
   // a new day avoids visible chart flicker while still tracking DST changes.
   if(!force && g_last_session_refresh>0)
     {
      MqlDateTime current_day={};
      MqlDateTime last_day={};
      TimeToStruct(now,current_day);
      TimeToStruct(g_last_session_refresh,last_day);
      if(current_day.year==last_day.year && current_day.day_of_year==last_day.day_of_year)
         return;
     }
   g_last_session_refresh=now;'''
new_session_refresh = '''   datetime now=ServerNow();
   datetime tehran_day=TehranDayStart();
   // Refresh on Tehran day boundaries, independent from broker server time.
   if(!force && g_last_session_refresh==tehran_day)
      return;
   g_last_session_refresh=tehran_day;'''
replace_once(old_session_refresh, new_session_refresh, 'session Tehran refresh')

# -----------------------------------------------------------------------------
# Rebuild Manage and add Journal tab
# -----------------------------------------------------------------------------
old_manage = '''void BuildManageTab(const int x,const int y)
  {
   CreateLabel(UI("GUARD_TITLE"),"ACCOUNT & PROP GUARD",x+14,y+94,9,RP_TEXT);
   CreateRectangle(UI("GUARD_CARD"),x+10,y+113,310,66,RP_CARD_2,RP_BORDER);
   CreateLabel(UI("GUARD_STATE"),"Guard state",x+20,y+124,8,RP_TEXT);
   CreateLabel(UI("GUARD_DAY"),"Day result",x+20,y+145,8,RP_MUTED);
   CreateLabel(UI("NEWS_STATE"),"News guard",x+20,y+164,8,RP_MUTED);

   CreateLabel(UI("AUTO_TITLE"),"SMART POSITION MANAGEMENT",x+14,y+195,9,RP_TEXT);
   CreateRectangle(UI("AUTO_CARD"),x+10,y+214,310,63,RP_CARD_2,RP_BORDER);
   CreateLabel(UI("AUTO_BE"),"Break-even",x+20,y+225,8,RP_TEXT);
   CreateLabel(UI("AUTO_PARTIAL"),"Partial close",x+172,y+225,8,RP_TEXT);
   CreateLabel(UI("AUTO_TRAIL"),"Trailing",x+20,y+249,8,RP_TEXT);
   CreateLabel(UI("HEDGE_STATE"),"Hedge protection",x+172,y+249,8,RP_TEXT);

   CreateButton(UI("BE_ALL"),"BREAK EVEN",x+10,y+290,98,30,RP_CARD,RP_TEXT,RP_BORDER);
   CreateButton(UI("HALF_ALL"),"CLOSE 50%",x+116,y+290,98,30,RP_CARD,RP_TEXT,RP_BORDER);
   CreateButton(UI("CANCEL_PENDING"),"CANCEL",x+222,y+290,98,30,RP_CARD,RP_AMBER,RP_BORDER);
   CreateButton(UI("CLOSE_PROFIT"),"CLOSE PROFIT",x+10,y+328,151,30,RP_GREEN_2,RP_WHITE,RP_GREEN_2);
   CreateButton(UI("CLOSE_LOSS"),"CLOSE LOSS",x+169,y+328,151,30,RP_RED_2,RP_WHITE,RP_RED_2);
   CreateButton(UI("REVERSE"),"REVERSE SAME LOT",x+10,y+366,151,32,RP_CARD,RP_AMBER,RP_BORDER);
   CreateButton(UI("CLOSE_ALL"),"EMERGENCY CLOSE",x+169,y+366,151,32,RP_RED,RP_WHITE,RP_RED);
   CreateLabel(UI("MANAGE_NOTE"),"Controls affect managed positions on this symbol",x+14,y+409,8,RP_MUTED);
  }
'''
new_manage = r'''void BuildManageTab(const int x,const int y)
  {
   CreateLabel(UI("AUTO_TITLE"),"RUNTIME MANAGEMENT  •  LIVE",x+14,y+91,9,RP_TEXT);

   CreateButton(UI("BE_TOGGLE"),g_use_break_even?"RISK FREE ON":"RISK FREE OFF",x+10,y+111,93,30,
                g_use_break_even?RP_GREEN_2:RP_CARD,RP_TEXT,g_use_break_even?RP_GREEN_2:RP_BORDER);
   CreateButton(UI("BE_MODE"),g_be_trigger_mode==RP_TRIGGER_RR?"R":"PIPS",x+109,y+111,48,30,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(UI("BE_TRIGGER_EDIT"),DoubleToString(g_be_trigger_mode==RP_TRIGGER_RR?g_be_at_r:g_be_at_pips,2),x+163,y+111,62,30);
   CreateLabel(UI("BE_LOCK_LABEL"),"LOCK",x+232,y+120,7,RP_MUTED);
   CreateEdit(UI("BE_LOCK_EDIT"),DoubleToString(g_be_lock_pips,1),x+268,y+111,52,30);

   CreateButton(UI("PART_TOGGLE"),g_use_partial_close?"SAVE PROFIT ON":"SAVE PROFIT OFF",x+10,y+149,93,30,
                g_use_partial_close?RP_GREEN_2:RP_CARD,RP_TEXT,g_use_partial_close?RP_GREEN_2:RP_BORDER);
   CreateButton(UI("PART_MODE"),g_partial_trigger_mode==RP_TRIGGER_RR?"R":"PIPS",x+109,y+149,48,30,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(UI("PART_TRIGGER_EDIT"),DoubleToString(g_partial_trigger_mode==RP_TRIGGER_RR?g_partial_at_r:g_partial_at_pips,2),x+163,y+149,62,30);
   CreateLabel(UI("PART_PCT_LABEL"),"%",x+236,y+158,8,RP_MUTED);
   CreateEdit(UI("PART_PCT_EDIT"),DoubleToString(g_partial_percent,0),x+268,y+149,52,30);

   CreateButton(UI("TRAIL_TOGGLE"),g_use_trailing?"TRAIL ON":"TRAIL OFF",x+10,y+187,77,30,
                g_use_trailing?RP_GREEN_2:RP_CARD,RP_TEXT,g_use_trailing?RP_GREEN_2:RP_BORDER);
   CreateButton(UI("TRAIL_MODE"),g_trailing_mode==RP_TRIGGER_RR?"R":"PIPS",x+93,y+187,45,30,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(UI("TRAIL_START_EDIT"),DoubleToString(g_trailing_mode==RP_TRIGGER_RR?g_trail_start_r:g_trail_start_pips,2),x+144,y+187,52,30);
   CreateEdit(UI("TRAIL_DIST_EDIT"),DoubleToString(g_trailing_mode==RP_TRIGGER_RR?g_trail_distance_r:g_trail_distance_pips,2),x+202,y+187,52,30);
   CreateEdit(UI("TRAIL_STEP_EDIT"),DoubleToString(g_trailing_mode==RP_TRIGGER_RR?g_trail_step_r:g_trail_step_pips,2),x+260,y+187,60,30);
   CreateLabel(UI("TRAIL_HINT"),"start / distance / step",x+146,y+220,7,RP_MUTED);

   CreateLabel(UI("GUARD_TITLE"),"ENTRY GUARDS",x+14,y+240,9,RP_TEXT);
   CreateButton(UI("NEWS_TOGGLE"),g_use_news_auto_pause?"NEWS BLOCK":"NEWS ALLOW",x+10,y+260,96,30,
                g_use_news_auto_pause?RP_RED_2:RP_GREEN_2,RP_TEXT,g_use_news_auto_pause?RP_RED_2:RP_GREEN_2);
   CreateEdit(UI("NEWS_BEFORE_EDIT"),IntegerToString(g_news_before_minutes),x+112,y+260,42,30);
   CreateLabel(UI("NEWS_SEP"),"/",x+160,y+269,8,RP_MUTED);
   CreateEdit(UI("NEWS_AFTER_EDIT"),IntegerToString(g_news_after_minutes),x+174,y+260,42,30);
   CreateButton(UI("HEDGE_TOGGLE"),"HEDGE "+HedgePolicyText(),x+222,y+260,98,30,RP_CARD,RP_TEXT,RP_BORDER);

   CreateButton(UI("MANUAL_TOGGLE"),g_manage_manual_positions?"MANUAL ON":"MANUAL OFF",x+10,y+298,96,30,
                g_manage_manual_positions?RP_GREEN_2:RP_CARD,RP_TEXT,g_manage_manual_positions?RP_GREEN_2:RP_BORDER);
   CreateButton(UI("OVER_TOGGLE"),g_overtrade_guard_enabled?"OVERTRADE ON":"OVERTRADE OFF",x+112,y+298,104,30,
                g_overtrade_guard_enabled?RP_GREEN_2:RP_CARD,RP_TEXT,g_overtrade_guard_enabled?RP_GREEN_2:RP_BORDER);
   CreateLabel(UI("MAX_LABEL"),"T / P / O",x+228,y+307,7,RP_MUTED);

   CreateEdit(UI("MAX_TRADES_EDIT"),IntegerToString(g_max_daily_trades),x+10,y+336,48,28);
   CreateEdit(UI("MAX_POS_EDIT"),IntegerToString(g_max_open_positions),x+64,y+336,48,28);
   CreateEdit(UI("MAX_PENDING_EDIT"),IntegerToString(g_max_pending_orders),x+118,y+336,48,28);
   CreateLabel(UI("GUARD_DAY"),"Day result",x+178,y+344,8,RP_MUTED);

   CreateButton(UI("BE_ALL"),"BE NOW",x+10,y+374,70,29,RP_CARD,RP_TEXT,RP_BORDER);
   CreateButton(UI("HALF_ALL"),"SAVE 50%",x+86,y+374,78,29,RP_CARD,RP_TEXT,RP_BORDER);
   CreateButton(UI("CLOSE_PROFIT"),"CLOSE +",x+170,y+374,70,29,RP_GREEN_2,RP_WHITE,RP_GREEN_2);
   CreateButton(UI("CLOSE_LOSS"),"CLOSE -",x+246,y+374,74,29,RP_RED_2,RP_WHITE,RP_RED_2);
   CreateButton(UI("REVERSE"),"REVERSE",x+10,y+411,94,30,RP_CARD,RP_AMBER,RP_BORDER);
   CreateButton(UI("CANCEL_PENDING"),"CANCEL ORDERS",x+110,y+411,100,30,RP_CARD,RP_AMBER,RP_BORDER);
   CreateButton(UI("CLOSE_ALL"),"EMERGENCY",x+216,y+411,104,30,RP_RED,RP_WHITE,RP_RED);
   CreateButton(UI("TAKE_SCREENSHOT"),"TAKE SCREENSHOT",x+10,y+449,151,30,RP_CARD,RP_BLUE,RP_BORDER);
   CreateButton(UI("JOURNAL_PATH"),"JOURNAL PATH",x+169,y+449,151,30,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(UI("MANAGE_NOTE"),"BE covers live spread + commission/fee when enabled",x+14,y+488,8,RP_MUTED);
  }

void BuildJournalTab(const int x,const int y)
  {
   CreateLabel(UI("JOURNAL_TITLE"),"TRADE JOURNAL  •  TEHRAN TIME",x+14,y+94,9,RP_TEXT);
   CreateLabel(UI("JOURNAL_PATH_TEXT"),"MQL5\\Files\\ArkoRisk\\Journal",x+14,y+116,8,RP_MUTED);
   CreateButton(UI("TAKE_SCREENSHOT"),"TAKE SCREENSHOT",x+10,y+140,145,31,RP_BLUE,RP_BG,RP_BLUE);
   CreateButton(UI("JOURNAL_PATH"),"SHOW PATH",x+163,y+140,157,31,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(UI("JOURNAL_RECENT"),"RECENT MANAGED ENTRIES",x+14,y+190,8,RP_MUTED);
   for(int i=0;i<6;i++)
     {
      int row_y=y+214+i*38;
      CreateRectangle(UI("JR_BG_"+IntegerToString(i)),x+10,row_y,310,32,RP_CARD_2,RP_BORDER);
      CreateLabel(UI("JR_ROW_"+IntegerToString(i)),"",x+18,row_y+9,8,RP_TEXT);
     }
   CreateLabel(UI("JOURNAL_NOTE"),"Screenshots are grouped by Tehran date",x+14,y+462,8,RP_MUTED);
  }
'''
replace_once(old_manage, new_manage, 'manage + journal UI')

# Five tabs and journal dispatch.
old_tabs = '''   CreateButton(UI("TAB_TRADE"),"TRADE",x+10,y+50,72,29,g_active_tab==RP_TAB_TRADE?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_TRADE?RP_BG:RP_TEXT,g_active_tab==RP_TAB_TRADE?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_MANAGE"),"MANAGE",x+88,y+50,72,29,g_active_tab==RP_TAB_MANAGE?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_MANAGE?RP_BG:RP_TEXT,g_active_tab==RP_TAB_MANAGE?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_NEWS"),"NEWS",x+166,y+50,72,29,g_active_tab==RP_TAB_NEWS?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_NEWS?RP_BG:RP_TEXT,g_active_tab==RP_TAB_NEWS?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_CHART"),"CHART",x+244,y+50,72,29,g_active_tab==RP_TAB_CHART?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_CHART?RP_BG:RP_TEXT,g_active_tab==RP_TAB_CHART?RP_BLUE:RP_BORDER);

   if(g_active_tab==RP_TAB_TRADE)
      BuildTradeTab(x,y);
   else if(g_active_tab==RP_TAB_MANAGE)
      BuildManageTab(x,y);
   else if(g_active_tab==RP_TAB_NEWS)
      BuildNewsTab(x,y);
   else
      BuildChartTab(x,y);
   CreateLabel(UI("STATUS"),g_status,x+12,y+435,8,g_status_color);'''
new_tabs = '''   CreateButton(UI("TAB_TRADE"),"TRADE",x+10,y+50,58,29,g_active_tab==RP_TAB_TRADE?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_TRADE?RP_BG:RP_TEXT,g_active_tab==RP_TAB_TRADE?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_MANAGE"),"MANAGE",x+72,y+50,58,29,g_active_tab==RP_TAB_MANAGE?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_MANAGE?RP_BG:RP_TEXT,g_active_tab==RP_TAB_MANAGE?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_NEWS"),"NEWS",x+134,y+50,58,29,g_active_tab==RP_TAB_NEWS?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_NEWS?RP_BG:RP_TEXT,g_active_tab==RP_TAB_NEWS?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_JOURNAL"),"JOURNAL",x+196,y+50,58,29,g_active_tab==RP_TAB_JOURNAL?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_JOURNAL?RP_BG:RP_TEXT,g_active_tab==RP_TAB_JOURNAL?RP_BLUE:RP_BORDER);
   CreateButton(UI("TAB_CHART"),"CHART",x+258,y+50,58,29,g_active_tab==RP_TAB_CHART?RP_BLUE:RP_CARD,
                g_active_tab==RP_TAB_CHART?RP_BG:RP_TEXT,g_active_tab==RP_TAB_CHART?RP_BLUE:RP_BORDER);

   if(g_active_tab==RP_TAB_TRADE)
      BuildTradeTab(x,y);
   else if(g_active_tab==RP_TAB_MANAGE)
      BuildManageTab(x,y);
   else if(g_active_tab==RP_TAB_NEWS)
      BuildNewsTab(x,y);
   else if(g_active_tab==RP_TAB_JOURNAL)
      BuildJournalTab(x,y);
   else
      BuildChartTab(x,y);
   CreateLabel(UI("STATUS"),g_status,x+12,y+510,8,g_status_color);'''
replace_once(old_tabs, new_tabs, 'five tabs')

# -----------------------------------------------------------------------------
# Live panel data, toggles and journal rows
# -----------------------------------------------------------------------------
replace_once(
'''string HedgePolicyText()
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      return "NETTING";
   if(g_runtime_hedge_policy==RP_HEDGE_BLOCK) return "BLOCK";
   if(g_runtime_hedge_policy==RP_HEDGE_ALLOW) return "ALLOW";
   return "WARN";
  }
''',
'''string HedgePolicyText()
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      return "NETTING";
   if(g_runtime_hedge_policy==RP_HEDGE_BLOCK) return "BLOCK";
   if(g_runtime_hedge_policy==RP_HEDGE_ALLOW) return "ALLOW";
   return "WARN";
  }

void ToggleRuntimeBool(bool &value,const string label)
  {
   value=!value;
   SaveRuntimeState();
   SetStatus(label+(value?" enabled":" disabled"),value?RP_GREEN:RP_AMBER,5);
   BuildPanel();
   UpdatePanel();
  }

void CycleHedgePolicy()
  {
   if(g_runtime_hedge_policy==RP_HEDGE_WARN) g_runtime_hedge_policy=RP_HEDGE_ALLOW;
   else if(g_runtime_hedge_policy==RP_HEDGE_ALLOW) g_runtime_hedge_policy=RP_HEDGE_BLOCK;
   else g_runtime_hedge_policy=RP_HEDGE_WARN;
   SaveRuntimeState();
   SetStatus("Hedge policy: "+HedgePolicyText(),RP_BLUE,5);
   BuildPanel(); UpdatePanel();
  }

void ToggleTriggerMode(ENUM_RP_TRIGGER_MODE &mode)
  {
   mode=(mode==RP_TRIGGER_RR?RP_TRIGGER_PIPS:RP_TRIGGER_RR);
   SaveRuntimeState();
   BuildPanel(); UpdatePanel();
  }
''',
'hedge toggles')

old_update_manage = '''void UpdateManageTab()
  {
   if(g_active_tab!=RP_TAB_MANAGE || g_collapsed)
      return;
   double realized=0.0,floating=0.0;
   int trades=0;
   GetDailyStats(realized,floating,trades);
   double day_result=realized+(InpIncludeFloatingInDailyLoss?floating:0.0);
   int lock_type=0;
   bool locked=IsDailyGuardLocked(lock_type);
   SetLabelText("GUARD_STATE",locked ? (lock_type==1?"LOCKED • DAILY LOSS":"LOCKED • PROFIT TARGET")
                                      : "UNLOCKED • LIMITS ACTIVE",locked?RP_RED:RP_GREEN);
   SetLabelText("GUARD_DAY",StringFormat("Day P/L  %+.2f  •  %d trade(s)",day_result,trades),
                day_result>=0.0?RP_GREEN:RP_RED);
   string news_reason="";
   bool news_paused=IsHighImpactNewsWindow(news_reason);
   SetLabelText("NEWS_STATE",news_paused?news_reason:"News entry pause inactive",news_paused?RP_RED:RP_MUTED);
   SetLabelText("AUTO_BE",InpUseBreakEven ? "BE  ON • "+TriggerSummary(InpBreakEvenTriggerMode,InpBreakEvenAtR,InpBreakEvenAtPips)
                                           : "BE  OFF",InpUseBreakEven?RP_GREEN:RP_MUTED);
   SetLabelText("AUTO_PARTIAL",InpUsePartialClose ? StringFormat("PART  ON • %.0f%% @ %s",InpPartialClosePercent,
                  TriggerSummary(InpPartialTriggerMode,InpPartialCloseAtR,InpPartialCloseAtPips)) : "PART  OFF",
                  InpUsePartialClose?RP_GREEN:RP_MUTED);
   SetLabelText("AUTO_TRAIL",InpUseTrailing ? "TRAIL  ON • "+TriggerSummary(InpTrailingMode,InpTrailStartAtR,InpTrailStartPips)
                                             : "TRAIL  OFF",InpUseTrailing?RP_GREEN:RP_MUTED);
   SetLabelText("HEDGE_STATE","HEDGE  "+HedgePolicyText(),g_runtime_hedge_policy==RP_HEDGE_ALLOW?RP_AMBER:RP_TEXT);
  }
'''
new_update_manage = r'''void UpdateManageTab()
  {
   if(g_active_tab!=RP_TAB_MANAGE || g_collapsed)
      return;
   double realized=0.0,floating=0.0;
   int trades=0;
   GetDailyStats(realized,floating,trades);
   double day_result=realized+(InpIncludeFloatingInDailyLoss?floating:0.0);
   SetLabelText("GUARD_DAY",StringFormat("Day %+.2f • %d trades",day_result,trades),day_result>=0?RP_GREEN:RP_RED);
  }

void UpdateJournalTab()
  {
   if(g_active_tab!=RP_TAB_JOURNAL || g_collapsed)
      return;
   datetime from=0,to=0;
   TehranDayBoundsInServerTime(from,to);
   to=ServerNow();
   int row=0;
   if(HistorySelect(from,to))
     {
      for(int i=HistoryDealsTotal()-1;i>=0 && row<6;i--)
        {
         ulong deal=HistoryDealGetTicket(i);
         if(deal==0)
            continue;
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
         ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
         long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
         if((entry!=DEAL_ENTRY_IN && entry!=DEAL_ENTRY_INOUT) || (type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL))
            continue;
         if(!(magic==(long)InpMagicNumber || (g_manage_manual_positions && magic==0)))
            continue;
         datetime server_time=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
         datetime tt=(datetime)((long)server_time-ServerUTCOffsetSeconds()+TehranOffsetSeconds());
         string symbol_name=HistoryDealGetString(deal,DEAL_SYMBOL);
         string side=(type==DEAL_TYPE_BUY?"BUY":"SELL");
         SetLabelText("JR_ROW_"+IntegerToString(row),StringFormat("%s  %-10s  %-4s  #%I64u",
                      TimeToString(tt,TIME_MINUTES),symbol_name,side,deal),type==DEAL_TYPE_BUY?RP_GREEN:RP_RED);
         row++;
        }
     }
   for(int i=row;i<6;i++)
      SetLabelText("JR_ROW_"+IntegerToString(i),i==0?"No managed entries today":"",RP_MUTED);
  }
'''
replace_once(old_update_manage, new_update_manage, 'update manage/journal')

# UpdatePanel route for journal.
replace_once(
'''   if(g_active_tab==RP_TAB_CHART)
     {
      UpdateChartTab();
      SetLabelText("STATUS",g_status,g_status_color);
      return;
     }
   if(g_active_tab==RP_TAB_MANAGE)''',
'''   if(g_active_tab==RP_TAB_CHART)
     {
      UpdateChartTab();
      SetLabelText("STATUS",g_status,g_status_color);
      return;
     }
   if(g_active_tab==RP_TAB_JOURNAL)
     {
      UpdateJournalTab();
      SetLabelText("STATUS",g_status,g_status_color);
      return;
     }
   if(g_active_tab==RP_TAB_MANAGE)''',
'journal update route')

# -----------------------------------------------------------------------------
# Edit field handler
# -----------------------------------------------------------------------------
read_edit_tail = '''   else if(object_name==UI("RR_EDIT"))
     {
      if(parsed>0.0)
         g_rr=ClampDouble(parsed,0.10,20.0);
      ObjectSetString(0,object_name,OBJPROP_TEXT,DoubleToString(g_rr,2));
      if(g_auto_tp_from_rr)
         UpdateTargetFromRR();
     }
   UpdatePanel();
  }
'''
read_edit_new = r'''   else if(object_name==UI("RR_EDIT"))
     {
      if(parsed>0.0)
         g_rr=ClampDouble(parsed,0.10,20.0);
      ObjectSetString(0,object_name,OBJPROP_TEXT,DoubleToString(g_rr,2));
      if(g_auto_tp_from_rr)
         UpdateTargetFromRR();
     }
   else if(object_name==UI("BE_TRIGGER_EDIT"))
     {
      if(parsed>0.0) { if(g_be_trigger_mode==RP_TRIGGER_RR) g_be_at_r=ClampDouble(parsed,0.05,20.0); else g_be_at_pips=ClampDouble(parsed,0.1,10000.0); }
     }
   else if(object_name==UI("BE_LOCK_EDIT")) g_be_lock_pips=ClampDouble(parsed,0.0,10000.0);
   else if(object_name==UI("PART_TRIGGER_EDIT"))
     {
      if(parsed>0.0) { if(g_partial_trigger_mode==RP_TRIGGER_RR) g_partial_at_r=ClampDouble(parsed,0.05,20.0); else g_partial_at_pips=ClampDouble(parsed,0.1,10000.0); }
     }
   else if(object_name==UI("PART_PCT_EDIT")) g_partial_percent=ClampDouble(parsed,1.0,99.0);
   else if(object_name==UI("TRAIL_START_EDIT"))
     {
      if(parsed>0.0) { if(g_trailing_mode==RP_TRIGGER_RR) g_trail_start_r=ClampDouble(parsed,0.05,20.0); else g_trail_start_pips=ClampDouble(parsed,0.1,10000.0); }
     }
   else if(object_name==UI("TRAIL_DIST_EDIT"))
     {
      if(parsed>0.0) { if(g_trailing_mode==RP_TRIGGER_RR) g_trail_distance_r=ClampDouble(parsed,0.01,20.0); else g_trail_distance_pips=ClampDouble(parsed,0.1,10000.0); }
     }
   else if(object_name==UI("TRAIL_STEP_EDIT"))
     {
      if(parsed>0.0) { if(g_trailing_mode==RP_TRIGGER_RR) g_trail_step_r=ClampDouble(parsed,0.01,20.0); else g_trail_step_pips=ClampDouble(parsed,0.1,10000.0); }
     }
   else if(object_name==UI("NEWS_BEFORE_EDIT")) g_news_before_minutes=(int)ClampDouble(parsed,0,240);
   else if(object_name==UI("NEWS_AFTER_EDIT")) g_news_after_minutes=(int)ClampDouble(parsed,0,240);
   else if(object_name==UI("MAX_TRADES_EDIT")) g_max_daily_trades=(int)ClampDouble(parsed,0,1000);
   else if(object_name==UI("MAX_POS_EDIT")) g_max_open_positions=(int)ClampDouble(parsed,0,1000);
   else if(object_name==UI("MAX_PENDING_EDIT")) g_max_pending_orders=(int)ClampDouble(parsed,0,1000);
   SaveRuntimeState();
   BuildPanel();
   UpdatePanel();
  }
'''
replace_once(read_edit_tail, read_edit_new, 'runtime edits')

# -----------------------------------------------------------------------------
# Init/deinit/timer
# -----------------------------------------------------------------------------
replace_once(
'''   g_timer_name=g_prefix+"CANDLE_TIMER";
   g_session_prefix=g_prefix+"SESSION_";
   g_collapsed=InpStartCollapsed;''',
'''   g_timer_name=g_prefix+"CANDLE_TIMER";
   g_session_prefix=g_prefix+"SESSION_";
   g_day_prefix=g_prefix+"DAY_";
   InitRuntimeState();
   g_collapsed=InpStartCollapsed;''',
'init runtime')

replace_once('''   DrawSessionMarkers(true);
   EventSetTimer(1);''', '''   DrawSessionMarkers(true);
   DrawTehranDayMarkers(true);
   EventSetTimer(1);''', 'draw day init')

replace_once('''   DeleteSessionMarkers();
   if(InpRestoreChartThemeOnRemove)''', '''   DeleteSessionMarkers();
   DeleteDayMarkers();
   SaveRuntimeState();
   if(InpRestoreChartThemeOnRemove)''', 'deinit day/runtime')

replace_once('if(InpUseNewsAutoPause)\n      RefreshEconomicNews(false,false);', 'if(g_use_news_auto_pause)\n      RefreshEconomicNews(false,false);', 'timer runtime news')
replace_once('''   DrawSessionMarkers(false);
   UpdatePanel();''', '''   DrawSessionMarkers(false);
   DrawTehranDayMarkers(false);
   UpdatePanel();''', 'timer day markers')

# -----------------------------------------------------------------------------
# Chart events: new tab, toggles, journal and edit fields
# -----------------------------------------------------------------------------
replace_once(
'''      else if(sparam==UI("TAB_NEWS")) SwitchPanelTab(RP_TAB_NEWS);
      else if(sparam==UI("TAB_CHART")) SwitchPanelTab(RP_TAB_CHART);''',
'''      else if(sparam==UI("TAB_NEWS")) SwitchPanelTab(RP_TAB_NEWS);
      else if(sparam==UI("TAB_JOURNAL")) SwitchPanelTab(RP_TAB_JOURNAL);
      else if(sparam==UI("TAB_CHART")) SwitchPanelTab(RP_TAB_CHART);''',
'tab journal event')

replace_once(
'''      else if(sparam==UI("RR_LINK")) ToggleRRLink();
      else if(sparam==UI("BE_ALL")) BreakEvenAll();''',
'''      else if(sparam==UI("RR_LINK")) ToggleRRLink();
      else if(sparam==UI("BE_TOGGLE")) ToggleRuntimeBool(g_use_break_even,"Automatic risk-free");
      else if(sparam==UI("BE_MODE")) ToggleTriggerMode(g_be_trigger_mode);
      else if(sparam==UI("PART_TOGGLE")) ToggleRuntimeBool(g_use_partial_close,"Automatic save-profit");
      else if(sparam==UI("PART_MODE")) ToggleTriggerMode(g_partial_trigger_mode);
      else if(sparam==UI("TRAIL_TOGGLE")) ToggleRuntimeBool(g_use_trailing,"Trailing stop");
      else if(sparam==UI("TRAIL_MODE")) ToggleTriggerMode(g_trailing_mode);
      else if(sparam==UI("NEWS_TOGGLE")) ToggleRuntimeBool(g_use_news_auto_pause,"News pause");
      else if(sparam==UI("MANUAL_TOGGLE")) ToggleRuntimeBool(g_manage_manual_positions,"Manual trade management");
      else if(sparam==UI("OVER_TOGGLE")) ToggleRuntimeBool(g_overtrade_guard_enabled,"Overtrading guard");
      else if(sparam==UI("HEDGE_TOGGLE")) CycleHedgePolicy();
      else if(sparam==UI("TAKE_SCREENSHOT")) CaptureManualScreenshot();
      else if(sparam==UI("JOURNAL_PATH")) SetStatus("Journal: MQL5\\Files\\"+InpScreenshotFolder,RP_BLUE,10);
      else if(sparam==UI("BE_ALL")) BreakEvenAll();''',
runtime button events')

old_endedit = '''   if(id==CHARTEVENT_OBJECT_ENDEDIT && (sparam==UI("RISK_EDIT") || sparam==UI("RR_EDIT")))
     {
      ReadEditValue(sparam);
      return;
     }'''
new_endedit = '''   if(id==CHARTEVENT_OBJECT_ENDEDIT &&
      (sparam==UI("RISK_EDIT") || sparam==UI("RR_EDIT") || sparam==UI("BE_TRIGGER_EDIT") ||
       sparam==UI("BE_LOCK_EDIT") || sparam==UI("PART_TRIGGER_EDIT") || sparam==UI("PART_PCT_EDIT") ||
       sparam==UI("TRAIL_START_EDIT") || sparam==UI("TRAIL_DIST_EDIT") || sparam==UI("TRAIL_STEP_EDIT") ||
       sparam==UI("NEWS_BEFORE_EDIT") || sparam==UI("NEWS_AFTER_EDIT") || sparam==UI("MAX_TRADES_EDIT") ||
       sparam==UI("MAX_POS_EDIT") || sparam==UI("MAX_PENDING_EDIT")))
     {
      ReadEditValue(sparam);
      return;
     }'''
replace_once(old_endedit, new_endedit, 'runtime edit events')

# -----------------------------------------------------------------------------
# Runtime hedge and overtrade display/use
# -----------------------------------------------------------------------------
replace_all('InpHedgePolicy==RP_HEDGE_BLOCK?RP_RED:RP_AMBER', 'g_runtime_hedge_policy==RP_HEDGE_BLOCK?RP_RED:RP_AMBER', 'hedge color', minimum=2)

# Cancel pending manual orders when runtime manual management is enabled.
replace_once(
'''      if(!IsPendingOrderType(type) || OrderGetString(ORDER_SYMBOL)!=_Symbol || OrderGetInteger(ORDER_MAGIC)!=(long)InpMagicNumber)
         continue;''',
'''      long magic=OrderGetInteger(ORDER_MAGIC);
      if(!IsPendingOrderType(type) || OrderGetString(ORDER_SYMBOL)!=_Symbol ||
         !(magic==(long)InpMagicNumber || (g_manage_manual_positions && magic==0)))
         continue;''',
'cancel pending manual')

# Keep journal path text accurate if custom folder was configured.
replace_once('CreateLabel(UI("JOURNAL_PATH_TEXT"),"MQL5\\\\Files\\\\ArkoRisk\\\\Journal",x+14,y+116,8,RP_MUTED);',
             'CreateLabel(UI("JOURNAL_PATH_TEXT"),"MQL5\\\\Files\\\\"+InpScreenshotFolder,x+14,y+116,8,RP_MUTED);',
             'journal custom path')

# -----------------------------------------------------------------------------
# Sanity checks for accidental static-management leftovers in critical paths.
# -----------------------------------------------------------------------------
for forbidden, label in [
    ('if(InpUseBreakEven &&', 'static BE condition'),
    ('if(InpUsePartialClose &&', 'static partial condition'),
    ('if(InpUseTrailing &&', 'static trailing condition'),
]:
    if forbidden in text:
        raise SystemExit(f'{label} still present')

PATH.write_text(text, encoding='utf-8')
print('ArkoRisk.mq5 upgraded to v1.50')
