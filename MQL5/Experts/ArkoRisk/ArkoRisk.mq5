#property copyright "Shayan Namayandeh (SudoShayanNA) — ArkoRisk"
#property link      "https://github.com/ArkoRisk"
#property version   "1.40"
#property strict
#property icon      "\\Images\\ArkoRisk\\ArkoRisk.ico"
#property description "ArkoRisk MT5 — open-source risk, position and prop-firm manager with smart orders, news guard and sessions"

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| ArkoRisk MT5                                                     |
//| Author: Shayan Namayandeh (SudoShayanNA)                         |
//| GitHub: ArkoRisk  |  Telegram: @SudoShayanNA                     |
//| Email: namayandeshayan@gmail.com                                 |
//|                                                                  |
//| This EA is an execution and money-management tool. It does not   |
//| generate trading signals. Test it on a demo account first.       |
//|                                                                  |
//| Quick start                                                      |
//| 1) Attach the EA to the symbol chart and enable Algo Trading.    |
//| 2) Set Risk and RR in the panel.                                 |
//| 3) For a pending trade, select Buy/Sell Limit, drag the three    |
//|    lines, verify the calculated lot and press PLACE LIMIT.       |
//| 4) BUY NOW / SELL NOW execute immediately. When valid designer   |
//|    lines surround the market, those SL/TP levels are respected;  |
//|    otherwise a fresh ATR-based SL/TP is used.                    |
//| 5) Position-management buttons affect this symbol and positions  |
//|    opened with InpMagicNumber (plus manual trades when enabled). |
//+------------------------------------------------------------------+

enum ENUM_RP_RISK_MODE
  {
   RP_BALANCE_PERCENT = 0, // Percent of balance
   RP_EQUITY_PERCENT  = 1, // Percent of equity
   RP_FIXED_MONEY     = 2, // Fixed account-currency amount
   RP_FIXED_LOT       = 3  // Fixed lot
  };

enum ENUM_RP_DAILY_SCOPE
  {
   RP_SCOPE_EA_SYMBOL = 0, // This EA and current symbol
   RP_SCOPE_EA_ALL    = 1, // This EA on all symbols
   RP_SCOPE_ACCOUNT   = 2  // Whole account
  };

enum ENUM_RP_START_THEME
  {
   RP_THEME_KEEP  = 0, // Keep current chart colors
   RP_THEME_DARK  = 1, // ArkoRisk dark theme
   RP_THEME_LIGHT = 2  // ArkoRisk light theme
  };

enum ENUM_RP_PANEL_TAB
  {
   RP_TAB_TRADE = 0,
   RP_TAB_MANAGE= 1,
   RP_TAB_NEWS  = 2,
   RP_TAB_CHART = 3
  };

enum ENUM_RP_TRIGGER_MODE
  {
   RP_TRIGGER_RR   = 0, // Trigger by R multiple
   RP_TRIGGER_PIPS = 1  // Trigger by profit in pips
  };

enum ENUM_RP_GUARD_VALUE_MODE
  {
   RP_GUARD_PERCENT = 0, // Percentage of start-of-day balance
   RP_GUARD_MONEY   = 1  // Fixed account-currency amount
  };

enum ENUM_RP_HEDGE_POLICY
  {
   RP_HEDGE_WARN  = 0, // Require a second click to confirm
   RP_HEDGE_BLOCK = 1, // Block possible hedges
   RP_HEDGE_ALLOW = 2  // Allow without warning
  };

input group "--- Core risk settings ---"
input ulong              InpMagicNumber                 = 260803;
input ENUM_RP_RISK_MODE  InpRiskMode                    = RP_EQUITY_PERCENT;
input double             InpDefaultRiskPercent          = 0.50;
input double             InpFixedRiskMoney              = 10.00;
input double             InpFixedLot                    = 0.01;
input double             InpDefaultRR                   = 2.00;
input bool               InpAllowMinimumLotRiskOverflow = false;
input double             InpMaxOpenRiskPercent          = 2.00;
input bool               InpBlockForPositionWithoutSL   = true;

input group "--- Fast order designer ---"
input int                InpATRPeriod                   = 14;
input double             InpDefaultSL_ATR               = 0.80;
input double             InpLimitGap_ATR                = 0.35;
input int                InpMinimumSLPoints             = 20;
input bool               InpAutoTPFromRR                = true;
input bool               InpKeepLimitLinesSelected      = true;  // one-motion drag; lines are paused only while panel moves
input bool               InpLockDesignerLinesOnStart    = false;
input bool               InpShowTradePreviewLabels      = true;
input int                InpMaxSpreadPoints             = 0;     // 0 = disabled
input int                InpDeviationPoints             = 20;
input bool               InpEnableHotkeys               = false; // B/S = market, 1/2 = limit
input bool               InpShowDesignerOnStart         = true;

input group "--- Trading guards ---"
input ENUM_RP_DAILY_SCOPE InpDailyGuardScope             = RP_SCOPE_EA_ALL;
input bool                InpUseDailyLossGuard           = true;
input ENUM_RP_GUARD_VALUE_MODE InpDailyLossMode          = RP_GUARD_PERCENT;
input double              InpMaxDailyLossPercent         = 3.00;  // 0 = disabled
input double              InpMaxDailyLossMoney           = 100.0;
input bool                InpClosePositionsAtDailyLoss   = true;
input bool                InpCancelPendingAtDailyLoss    = true;
input bool                InpUseDailyProfitTarget        = false;
input ENUM_RP_GUARD_VALUE_MODE InpDailyProfitMode        = RP_GUARD_PERCENT;
input double              InpDailyProfitTargetPercent    = 2.00;
input double              InpDailyProfitTargetMoney      = 100.0;
input bool                InpClosePositionsAtProfitTarget= false;
input bool                InpCancelPendingAtProfitTarget = true;
input bool                InpIncludeFloatingInDailyLoss  = true;
input int                 InpMaxDailyTrades              = 20;    // 0 = disabled
input int                 InpMaxOpenPositions            = 5;     // 0 = disabled
input int                 InpMaxPendingOrders            = 10;    // 0 = disabled
input bool                InpOnePositionPerSymbol        = false;
input int                 InpCancelPendingAfterMinutes   = 30;    // 0 = disabled

input group "--- Automatic management ---"
input bool               InpManageManualPositions       = false;
input bool               InpUseBreakEven                = true;
input ENUM_RP_TRIGGER_MODE InpBreakEvenTriggerMode      = RP_TRIGGER_RR;
input double             InpBreakEvenAtR                = 1.00;
input double             InpBreakEvenAtPips             = 10.0;
input double             InpBreakEvenLockPips           = 0.0;
input int                InpBreakEvenPlusPoints         = 2;
input bool               InpUsePartialClose             = true;
input ENUM_RP_TRIGGER_MODE InpPartialTriggerMode        = RP_TRIGGER_RR;
input double             InpPartialCloseAtR             = 1.00;
input double             InpPartialCloseAtPips          = 10.0;
input double             InpPartialClosePercent         = 50.00;
input bool               InpUseTrailing                 = false;
input ENUM_RP_TRIGGER_MODE InpTrailingMode              = RP_TRIGGER_PIPS;
input double             InpTrailStartAtR               = 1.50;
input double             InpTrailDistanceR              = 0.50;
input double             InpTrailStepR                  = 0.10;
input double             InpTrailStartPips              = 15.0;
input double             InpTrailDistancePips           = 8.0;
input double             InpTrailStepPips               = 2.0;

input group "--- News auto-pause and hedge protection ---"
input bool               InpUseNewsAutoPause            = true;
input int                InpNewsPauseMinutesBefore      = 15;
input int                InpNewsPauseMinutesAfter       = 15;
input bool               InpNewsPauseCurrentSymbolOnly  = true;
input bool               InpBlockIfCalendarUnavailable  = false;
input ENUM_RP_HEDGE_POLICY InpHedgePolicy               = RP_HEDGE_WARN;
input bool               InpHedgeCheckAllAccountTrades  = true;
input int                InpHedgeConfirmationSeconds    = 6;

input group "--- Trade journal screenshots ---"
input bool               InpTakeEntryScreenshot         = true;
input string             InpScreenshotFolder            = "ArkoRisk\\Journal";
input int                InpScreenshotWidth             = 1920;
input int                InpScreenshotHeight            = 1080;

input group "--- Panel ---"
input bool               InpStartCollapsed              = false;
input string             InpPanelFont                   = "Segoe UI";
input bool               InpRememberPanelPosition       = true;

input group "--- Candle close timer ---"
input bool               InpShowCandleCloseTimer        = true;
input bool               InpTimerShowTimeframe          = true;
input int                InpTimerFontSize               = 10;
input double             InpTimerOffsetATR              = 0.08;
input color              InpTimerColor                  = C'125,211,252';
input color              InpTimerWarningColor           = C'245,158,11';
input color              InpTimerUrgentColor            = C'244,63,94';

input group "--- Economic calendar ---"
input bool               InpEnableEconomicCalendar      = true;
input int                InpTehranUTCOffsetMinutes      = 210; // UTC+03:30
input int                InpNewsRefreshSeconds          = 60;

input group "--- Chart themes and Forex sessions ---"
input ENUM_RP_START_THEME InpChartThemeOnStart           = RP_THEME_DARK;
input bool               InpRestoreChartThemeOnRemove   = false;
input bool               InpShowForexSessions           = true;
input int                InpSessionLookbackDays         = 5;
input bool               InpAutoSessionDST              = true;
input color              InpSydneySessionColor          = C'192,132,252';
input color              InpTokyoSessionColor           = C'56,189,248';
input color              InpLondonSessionColor          = C'52,211,153';
input color              InpNewYorkSessionColor         = C'251,146,60';

//--- visual theme
#define RP_BG       C'15,23,42'
#define RP_CARD     C'30,41,59'
#define RP_CARD_2   C'24,33,48'
#define RP_BORDER   C'51,65,85'
#define RP_TEXT     C'241,245,249'
#define RP_MUTED    C'148,163,184'
#define RP_BLUE     C'56,189,248'
#define RP_GREEN    C'16,185,129'
#define RP_GREEN_2  C'5,120,87'
#define RP_RED      C'244,63,94'
#define RP_RED_2    C'159,18,57'
#define RP_AMBER    C'245,158,11'
#define RP_WHITE    C'255,255,255'

CTrade trade;

struct ArkoNewsItem
  {
   datetime tehran_time;
   string   currency;
   string   title;
   ENUM_CALENDAR_EVENT_IMPORTANCE importance;
   ENUM_CALENDAR_EVENT_TIMEMODE time_mode;
  };

struct ArkoChartThemeSnapshot
  {
   bool captured;
   long background;
   long foreground;
   long grid;
   long chart_up;
   long chart_down;
   long candle_bull;
   long candle_bear;
   long bid;
   long ask;
   long last;
   long stop_level;
   long show_grid;
   long chart_mode;
  };

string g_prefix     = "";
string g_ui_prefix  = "";
string g_line_prefix= "";
string g_timer_name = "";
string g_session_prefix = "";
string g_ui_objects[];
ulong  g_screenshot_queue[];
bool   g_collapsed  = false;
bool   g_is_buy     = true;
bool   g_auto_tp_from_rr = true;
bool   g_panel_position_initialized = false;
bool   g_panel_dragging = false;
bool   g_designer_lines_locked = false;
bool   g_previous_mouse_events = false;
bool   g_previous_mouse_scroll = true;
bool   g_sessions_visible = true;
bool   g_news_high_only = false;
bool   g_timer_visible = true;
int    g_panel_drag_offset_x = 0;
int    g_panel_drag_offset_y = 0;
int    g_news_page = 0;
int    g_hedge_confirm_side = 0;
ENUM_RP_PANEL_TAB g_active_tab = RP_TAB_TRADE;
ENUM_RP_START_THEME g_chart_theme = RP_THEME_KEEP;
ArkoNewsItem g_news_items[];
ArkoChartThemeSnapshot g_original_theme;
double g_risk_value = 0.50;
double g_rr         = 2.00;
int    g_panel_x    = 10;
int    g_panel_y    = 18;
int    g_panel_w    = 330;
int    g_panel_h    = 455;
string g_status     = "Ready";
color  g_status_color = RP_MUTED;
datetime g_status_until = 0;
datetime g_last_pending_scan = 0;
datetime g_news_last_refresh = 0;
datetime g_last_session_refresh = 0;
datetime g_daily_stats_cache_time = 0;
datetime g_guard_last_action_day = 0;
datetime g_last_guard_retry = 0;
datetime g_hedge_confirm_until = 0;
double g_cached_realized = 0.0;
double g_cached_floating = 0.0;
int    g_cached_trade_count = 0;
ulong  g_last_manage_ms = 0;
ulong  g_last_panel_redraw_ms = 0;
ulong  g_last_panel_drag_event_ms = 0;

#define RP_NEWS_ROWS 6

//--- object suffixes
string UI(const string suffix)   { return g_ui_prefix+suffix;   }
string LINE(const string suffix) { return g_line_prefix+suffix; }

//+------------------------------------------------------------------+
//| Utility                                                          |
//+------------------------------------------------------------------+
double ClampDouble(const double value,const double min_value,const double max_value)
  {
   return MathMax(min_value,MathMin(max_value,value));
  }

double PipSize()
  {
   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   return((digits==3 || digits==5) ? _Point*10.0 : _Point);
  }

bool TriggerReached(const ENUM_RP_TRIGGER_MODE mode,const double current_r,
                    const double progress,const double at_r,const double at_pips)
  {
   if(mode==RP_TRIGGER_PIPS)
      return(progress>=MathMax(0.0,at_pips)*PipSize());
   return(current_r>=MathMax(0.0,at_r));
  }

datetime ServerNow()
  {
   datetime now=TimeTradeServer();
   if(now<=0)
      now=TimeCurrent();
   return now;
  }

datetime StartOfServerDay()
  {
   MqlDateTime tm={};
   TimeToStruct(ServerNow(),tm);
   tm.hour=0;
   tm.min=0;
   tm.sec=0;
   return StructToTime(tm);
  }

datetime CurrentBarCloseTime()
  {
   datetime bar_open=iTime(_Symbol,PERIOD_CURRENT,0);
   if(bar_open<=0)
      return 0;

   if(_Period==PERIOD_MN1)
     {
      MqlDateTime tm={};
      TimeToStruct(bar_open,tm);
      tm.day=1;
      tm.hour=0;
      tm.min=0;
      tm.sec=0;
      tm.mon++;
      if(tm.mon>12)
        {
         tm.mon=1;
         tm.year++;
        }
      return StructToTime(tm);
     }

   int period_seconds=PeriodSeconds(PERIOD_CURRENT);
   if(period_seconds<=0)
     {
      datetime previous=iTime(_Symbol,PERIOD_CURRENT,1);
      if(previous>0 && bar_open>previous)
         period_seconds=(int)(bar_open-previous);
     }
   if(period_seconds<=0)
      return 0;
   return bar_open+period_seconds;
  }

string ShortTimeframeName()
  {
   string value=EnumToString((ENUM_TIMEFRAMES)_Period);
   StringReplace(value,"PERIOD_","");
   return value;
  }

string FormatCountdown(long seconds_left)
  {
   if(seconds_left<0)
      seconds_left=0;
   int days=(int)(seconds_left/86400);
   int hours=(int)((seconds_left%86400)/3600);
   int minutes=(int)((seconds_left%3600)/60);
   int seconds=(int)(seconds_left%60);
   if(days>0)
      return StringFormat("%dd %02d:%02d:%02d",days,hours,minutes,seconds);
   if(hours>0)
      return StringFormat("%02d:%02d:%02d",hours,minutes,seconds);
   return StringFormat("%02d:%02d",minutes,seconds);
  }

void DeleteCandleTimer()
  {
   if(g_timer_name!="" && ObjectFind(0,g_timer_name)>=0)
      ObjectDelete(0,g_timer_name);
  }

void UpdateCandleTimer()
  {
   if(!g_timer_visible)
     {
      DeleteCandleTimer();
      return;
     }

   datetime bar_open=iTime(_Symbol,PERIOD_CURRENT,0);
   datetime bar_close=CurrentBarCloseTime();
   if(bar_open<=0 || bar_close<=0)
     {
      DeleteCandleTimer();
      return;
     }

   long remaining=(long)(bar_close-ServerNow());
   if(remaining<0)
      remaining=0;
   double bar_high=iHigh(_Symbol,PERIOD_CURRENT,0);
   double bar_low=iLow(_Symbol,PERIOD_CURRENT,0);
   MqlTick tick={};
   SymbolInfoTick(_Symbol,tick);
   if(bar_high<=0.0)
      bar_high=MathMax(tick.ask,tick.bid);
   double offset=MathMax(MathMax((bar_high-bar_low)*0.12,
                                 CurrentATR()*MathMax(0.0,InpTimerOffsetATR)),
                         _Point*5.0);
   double anchor_price=NormalizePrice(bar_high+offset);

   if(ObjectFind(0,g_timer_name)<0)
     {
      if(!ObjectCreate(0,g_timer_name,OBJ_TEXT,0,bar_open,anchor_price))
         return;
      ObjectSetInteger(0,g_timer_name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,g_timer_name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,g_timer_name,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,g_timer_name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,g_timer_name,OBJPROP_BACK,false);
      ObjectSetInteger(0,g_timer_name,OBJPROP_ZORDER,50);
      ObjectSetString(0,g_timer_name,OBJPROP_FONT,InpPanelFont);
     }
   else
      ObjectMove(0,g_timer_name,0,bar_open,anchor_price);

   color timer_color=InpTimerColor;
   if(remaining<=10)
      timer_color=InpTimerUrgentColor;
   else if(remaining<=30)
      timer_color=InpTimerWarningColor;
   string countdown=FormatCountdown(remaining);
   string label=(InpTimerShowTimeframe ? ShortTimeframeName()+"  "+countdown : countdown);
   ObjectSetString(0,g_timer_name,OBJPROP_TEXT,label);
   ObjectSetString(0,g_timer_name,OBJPROP_TOOLTIP,"Time remaining until the current candle closes");
   ObjectSetInteger(0,g_timer_name,OBJPROP_COLOR,timer_color);
   ObjectSetInteger(0,g_timer_name,OBJPROP_FONTSIZE,MathMax(7,MathMin(24,InpTimerFontSize)));
  }

//+------------------------------------------------------------------+
//| Tehran time and MetaTrader economic calendar                     |
//+------------------------------------------------------------------+
long TehranOffsetSeconds()
  {
   return (long)InpTehranUTCOffsetMinutes*60;
  }

long ServerUTCOffsetSeconds()
  {
   datetime server=TimeTradeServer();
   datetime utc=TimeGMT();
   if(server<=0 || utc<=0)
      return 0;
   return (long)(server-utc);
  }

datetime TehranNow()
  {
   return (datetime)((long)TimeGMT()+TehranOffsetSeconds());
  }

datetime TehranDayStart()
  {
   MqlDateTime tm={};
   TimeToStruct(TehranNow(),tm);
   tm.hour=0;
   tm.min=0;
   tm.sec=0;
   return StructToTime(tm);
  }

void TehranDayBoundsInServerTime(datetime &date_from,datetime &date_to)
  {
   datetime tehran_midnight=TehranDayStart();
   datetime utc_midnight=(datetime)((long)tehran_midnight-TehranOffsetSeconds());
   long server_offset=ServerUTCOffsetSeconds();
   date_from=(datetime)((long)utc_midnight+server_offset);
   date_to=(datetime)((long)date_from+86400-1);
  }

string TruncateText(const string value,const int max_chars)
  {
   if(StringLen(value)<=max_chars)
      return value;
   if(max_chars<=3)
      return StringSubstr(value,0,max_chars);
   return StringSubstr(value,0,max_chars-3)+"...";
  }

string NewsImportanceText(const ENUM_CALENDAR_EVENT_IMPORTANCE importance)
  {
   if(importance==CALENDAR_IMPORTANCE_HIGH)
      return "HIGH";
   if(importance==CALENDAR_IMPORTANCE_MODERATE)
      return "MED";
   if(importance==CALENDAR_IMPORTANCE_LOW)
      return "LOW";
   return "INFO";
  }

color NewsImportanceColor(const ENUM_CALENDAR_EVENT_IMPORTANCE importance)
  {
   if(importance==CALENDAR_IMPORTANCE_HIGH)
      return RP_RED;
   if(importance==CALENDAR_IMPORTANCE_MODERATE)
      return RP_AMBER;
   if(importance==CALENDAR_IMPORTANCE_LOW)
      return RP_BLUE;
   return RP_MUTED;
  }

bool NewsItemPassesFilter(const int index)
  {
   if(index<0 || index>=ArraySize(g_news_items))
      return false;
   datetime day_start=TehranDayStart();
   if(g_news_items[index].tehran_time<day_start || g_news_items[index].tehran_time>=day_start+86400)
      return false;
   if(g_news_high_only && g_news_items[index].importance!=CALENDAR_IMPORTANCE_HIGH)
      return false;
   return true;
  }

int FilteredNewsCount()
  {
   int count=0;
   for(int i=0;i<ArraySize(g_news_items);i++)
      if(NewsItemPassesFilter(i))
         count++;
   return count;
  }

int ActualNewsIndex(const int filtered_index)
  {
   int current=0;
   for(int i=0;i<ArraySize(g_news_items);i++)
     {
      if(!NewsItemPassesFilter(i))
         continue;
      if(current==filtered_index)
         return i;
      current++;
     }
   return -1;
  }

void SortNewsItems()
  {
   int total=ArraySize(g_news_items);
   for(int i=0;i<total-1;i++)
     {
      int smallest=i;
      for(int j=i+1;j<total;j++)
         if(g_news_items[j].tehran_time<g_news_items[smallest].tehran_time)
            smallest=j;
      if(smallest!=i)
        {
         ArkoNewsItem temp=g_news_items[i];
         g_news_items[i]=g_news_items[smallest];
         g_news_items[smallest]=temp;
        }
     }
  }

void JumpNewsToUpcoming()
  {
   const int rows_per_page=RP_NEWS_ROWS;
   datetime now=TehranNow();
   int filtered_position=0;
   for(int i=0;i<ArraySize(g_news_items);i++)
     {
      if(!NewsItemPassesFilter(i))
         continue;
      if(g_news_items[i].tehran_time>=now-60)
        {
         g_news_page=filtered_position/rows_per_page;
         return;
        }
      filtered_position++;
     }
   int total=FilteredNewsCount();
   g_news_page=(total>0 ? (total-1)/rows_per_page : 0);
  }

bool RefreshEconomicNews(const bool force,const bool jump_to_upcoming=false)
  {
   if(!InpEnableEconomicCalendar)
     {
      ArrayResize(g_news_items,0);
      g_news_last_refresh=ServerNow();
      return false;
     }
   int refresh_seconds=MathMax(15,InpNewsRefreshSeconds);
   if(!force && g_news_last_refresh>0 && ServerNow()-g_news_last_refresh<refresh_seconds)
      return true;
   g_news_last_refresh=ServerNow();

   datetime date_from=0,date_to=0;
   TehranDayBoundsInServerTime(date_from,date_to);
   int news_margin=MathMax(InpNewsPauseMinutesBefore,InpNewsPauseMinutesAfter)*60+3600;
   date_from-=news_margin;
   date_to+=news_margin;
   MqlCalendarValue values[];
   ResetLastError();
   int received=CalendarValueHistory(values,date_from,date_to);
   if(received<0)
     {
      ArrayResize(g_news_items,0);
      SetStatus(StringFormat("Economic calendar unavailable (%d)",GetLastError()),RP_AMBER,8);
      return false;
     }

   ArrayResize(g_news_items,0);
   long server_offset=ServerUTCOffsetSeconds();
   for(int i=0;i<received;i++)
     {
      MqlCalendarEvent event={};
      MqlCalendarCountry country={};
      if(!CalendarEventById(values[i].event_id,event))
         continue;
      if(!CalendarCountryById(event.country_id,country))
         continue;
      if(country.currency=="" || event.name=="")
         continue;
      int size=ArraySize(g_news_items);
      ArrayResize(g_news_items,size+1);
      g_news_items[size].tehran_time=(datetime)((long)values[i].time-server_offset+TehranOffsetSeconds());
      g_news_items[size].currency=country.currency;
      g_news_items[size].title=event.name;
      g_news_items[size].importance=event.importance;
      g_news_items[size].time_mode=event.time_mode;
     }
   SortNewsItems();
   if(jump_to_upcoming)
      JumpNewsToUpcoming();
   return true;
  }

bool NewsCurrencyRelevant(const string currency)
  {
   if(!InpNewsPauseCurrentSymbolOnly)
      return true;
   string base=SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE);
   string profit=SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT);
   return(currency==base || currency==profit);
  }

bool IsHighImpactNewsWindow(string &reason)
  {
   reason="";
   if(!InpUseNewsAutoPause)
      return false;
   bool refreshed=RefreshEconomicNews(false,false);
   if(!refreshed && InpBlockIfCalendarUnavailable)
     {
      reason="News guard: economic calendar unavailable";
      return true;
     }
   datetime now=TehranNow();
   int before=MathMax(0,InpNewsPauseMinutesBefore)*60;
   int after=MathMax(0,InpNewsPauseMinutesAfter)*60;
   for(int i=0;i<ArraySize(g_news_items);i++)
     {
      ArkoNewsItem item=g_news_items[i];
      if(item.importance!=CALENDAR_IMPORTANCE_HIGH ||
         item.time_mode!=CALENDAR_TIMEMODE_DATETIME || !NewsCurrencyRelevant(item.currency))
         continue;
      if(now>=item.tehran_time-before && now<=item.tehran_time+after)
        {
         reason=StringFormat("NEWS PAUSE  %s %s  %s",TimeToString(item.tehran_time,TIME_MINUTES),
                             item.currency,TruncateText(item.title,28));
         return true;
        }
     }
   return false;
  }

string NextHighImpactNewsText()
  {
   datetime now=TehranNow();
   for(int i=0;i<ArraySize(g_news_items);i++)
     {
      ArkoNewsItem item=g_news_items[i];
      if(item.tehran_time>=now && item.importance==CALENDAR_IMPORTANCE_HIGH &&
         item.time_mode==CALENDAR_TIMEMODE_DATETIME && NewsCurrencyRelevant(item.currency))
         return StringFormat("Next high  %s  %s  %s",TimeToString(item.tehran_time,TIME_MINUTES),
                             item.currency,TruncateText(item.title,22));
     }
   return "No upcoming relevant high-impact news today";
  }

string NewsTimeText(const ArkoNewsItem &item)
  {
   if(item.time_mode==CALENDAR_TIMEMODE_DATE)
      return "ALL DAY";
   if(item.time_mode==CALENDAR_TIMEMODE_NOTIME || item.time_mode==CALENDAR_TIMEMODE_TENTATIVE)
      return "TENTATIVE";
   return TimeToString(item.tehran_time,TIME_MINUTES);
  }

//+------------------------------------------------------------------+
//| Chart themes                                                     |
//+------------------------------------------------------------------+
long ReadChartInteger(const ENUM_CHART_PROPERTY_INTEGER property)
  {
   long value=0;
   ChartGetInteger(0,property,0,value);
   return value;
  }

void CaptureOriginalChartTheme()
  {
   if(g_original_theme.captured)
      return;
   g_original_theme.background=ReadChartInteger(CHART_COLOR_BACKGROUND);
   g_original_theme.foreground=ReadChartInteger(CHART_COLOR_FOREGROUND);
   g_original_theme.grid=ReadChartInteger(CHART_COLOR_GRID);
   g_original_theme.chart_up=ReadChartInteger(CHART_COLOR_CHART_UP);
   g_original_theme.chart_down=ReadChartInteger(CHART_COLOR_CHART_DOWN);
   g_original_theme.candle_bull=ReadChartInteger(CHART_COLOR_CANDLE_BULL);
   g_original_theme.candle_bear=ReadChartInteger(CHART_COLOR_CANDLE_BEAR);
   g_original_theme.bid=ReadChartInteger(CHART_COLOR_BID);
   g_original_theme.ask=ReadChartInteger(CHART_COLOR_ASK);
   g_original_theme.last=ReadChartInteger(CHART_COLOR_LAST);
   g_original_theme.stop_level=ReadChartInteger(CHART_COLOR_STOP_LEVEL);
   g_original_theme.show_grid=ReadChartInteger(CHART_SHOW_GRID);
   g_original_theme.chart_mode=ReadChartInteger(CHART_MODE);
   g_original_theme.captured=true;
  }

void SetChartColors(const color background,const color foreground,const color grid,
                    const color bull,const color bear,const color bid,const color ask,
                    const color last,const color stop_level,const bool show_grid)
  {
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,background);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,foreground);
   ChartSetInteger(0,CHART_COLOR_GRID,grid);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,bull);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,bear);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,bull);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,bear);
   ChartSetInteger(0,CHART_COLOR_BID,bid);
   ChartSetInteger(0,CHART_COLOR_ASK,ask);
   ChartSetInteger(0,CHART_COLOR_LAST,last);
   ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,stop_level);
   ChartSetInteger(0,CHART_SHOW_GRID,show_grid);
   ChartSetInteger(0,CHART_MODE,CHART_CANDLES);
  }

void RestoreOriginalChartTheme()
  {
   if(!g_original_theme.captured)
      return;
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,g_original_theme.background);
   ChartSetInteger(0,CHART_COLOR_FOREGROUND,g_original_theme.foreground);
   ChartSetInteger(0,CHART_COLOR_GRID,g_original_theme.grid);
   ChartSetInteger(0,CHART_COLOR_CHART_UP,g_original_theme.chart_up);
   ChartSetInteger(0,CHART_COLOR_CHART_DOWN,g_original_theme.chart_down);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,g_original_theme.candle_bull);
   ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,g_original_theme.candle_bear);
   ChartSetInteger(0,CHART_COLOR_BID,g_original_theme.bid);
   ChartSetInteger(0,CHART_COLOR_ASK,g_original_theme.ask);
   ChartSetInteger(0,CHART_COLOR_LAST,g_original_theme.last);
   ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,g_original_theme.stop_level);
   ChartSetInteger(0,CHART_SHOW_GRID,g_original_theme.show_grid);
   ChartSetInteger(0,CHART_MODE,g_original_theme.chart_mode);
   g_chart_theme=RP_THEME_KEEP;
   ChartRedraw();
  }

void ApplyChartTheme(const ENUM_RP_START_THEME theme)
  {
   CaptureOriginalChartTheme();
   if(theme==RP_THEME_DARK)
     {
      SetChartColors(C'8,15,28',C'148,163,184',C'30,41,59',
                     C'45,212,191',C'251,113,133',C'56,189,248',
                     C'245,158,11',C'167,139,250',C'100,116,139',false);
      g_chart_theme=RP_THEME_DARK;
      SetStatus("ArkoRisk Dark chart theme applied",RP_BLUE,4);
     }
   else if(theme==RP_THEME_LIGHT)
     {
      SetChartColors(C'248,250,252',C'51,65,85',C'226,232,240',
                     C'5,150,105',C'225,29,72',C'2,132,199',
                     C'217,119,6',C'124,58,237',C'100,116,139',true);
      g_chart_theme=RP_THEME_LIGHT;
      SetStatus("ArkoRisk Light chart theme applied",RP_BLUE,4);
     }
   else
      RestoreOriginalChartTheme();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Forex session markers with automatic London/NY/Sydney DST        |
//+------------------------------------------------------------------+
datetime MakeDate(const int year,const int month,const int day,const int hour=0,
                  const int minute=0,const int second=0)
  {
   MqlDateTime tm={};
   tm.year=year;
   tm.mon=month;
   tm.day=day;
   tm.hour=hour;
   tm.min=minute;
   tm.sec=second;
   return StructToTime(tm);
  }

datetime NthSunday(const int year,const int month,const int occurrence)
  {
   datetime first=MakeDate(year,month,1);
   MqlDateTime tm={};
   TimeToStruct(first,tm);
   int day=1+((7-tm.day_of_week)%7)+(occurrence-1)*7;
   return MakeDate(year,month,day);
  }

datetime LastSunday(const int year,const int month)
  {
   int next_year=year;
   int next_month=month+1;
   if(next_month>12)
     {
      next_month=1;
      next_year++;
     }
   datetime last_day=MakeDate(next_year,next_month,1)-86400;
   MqlDateTime tm={};
   TimeToStruct(last_day,tm);
   return last_day-(datetime)tm.day_of_week*86400;
  }

bool IsLondonDST(const datetime utc_time)
  {
   if(!InpAutoSessionDST)
      return false;
   MqlDateTime tm={};
   TimeToStruct(utc_time,tm);
   datetime start=LastSunday(tm.year,3)+3600;
   datetime finish=LastSunday(tm.year,10)+3600;
   return(utc_time>=start && utc_time<finish);
  }

bool IsNewYorkDST(const datetime utc_time)
  {
   if(!InpAutoSessionDST)
      return false;
   MqlDateTime tm={};
   TimeToStruct(utc_time,tm);
   datetime start=NthSunday(tm.year,3,2)+7*3600;
   datetime finish=NthSunday(tm.year,11,1)+6*3600;
   return(utc_time>=start && utc_time<finish);
  }

bool IsSydneyDST(const datetime utc_time)
  {
   if(!InpAutoSessionDST)
      return false;
   MqlDateTime tm={};
   TimeToStruct(utc_time,tm);
   int start_year=(tm.mon<4 ? tm.year-1 : tm.year);
   datetime start=NthSunday(start_year,10,1)+2*3600-10*3600;
   datetime finish=NthSunday(start_year+1,4,1)+3*3600-11*3600;
   return(utc_time>=start && utc_time<finish);
  }

datetime UTCMidnight(const datetime utc_time)
  {
   MqlDateTime tm={};
   TimeToStruct(utc_time,tm);
   return MakeDate(tm.year,tm.mon,tm.day);
  }

datetime SessionStartUTC(const int session,const datetime utc_day)
  {
   datetime noon=utc_day+12*3600;
   if(session==0) // Sydney: 08:00 local
      return utc_day+(IsSydneyDST(noon)?21:22)*3600;
   if(session==1) // Tokyo: 09:00 JST
      return utc_day;
   if(session==2) // London: 08:00 local
      return utc_day+(IsLondonDST(noon)?7:8)*3600;
   // New York: 08:00 local
   return utc_day+(IsNewYorkDST(noon)?12:13)*3600;
  }

string SessionName(const int session)
  {
   if(session==0) return "SYDNEY";
   if(session==1) return "TOKYO";
   if(session==2) return "LONDON";
   return "NEW YORK";
  }

color SessionColor(const int session)
  {
   if(session==0) return InpSydneySessionColor;
   if(session==1) return InpTokyoSessionColor;
   if(session==2) return InpLondonSessionColor;
   return InpNewYorkSessionColor;
  }

bool SessionTradesOnUTCDay(const int session,const int day_of_week)
  {
   if(session==0)
      return(day_of_week>=0 && day_of_week<=4); // Sun-Thu UTC starts
   return(day_of_week>=1 && day_of_week<=5);   // Mon-Fri
  }

void DeleteSessionMarkers()
  {
   if(g_session_prefix!="")
      ObjectsDeleteAll(0,g_session_prefix);
  }

void CreateSessionMarker(const int session,const datetime start_utc,const double label_price)
  {
   datetime server_time=(datetime)((long)start_utc+ServerUTCOffsetSeconds());
   datetime tehran_time=(datetime)((long)start_utc+TehranOffsetSeconds());
   string id=IntegerToString(session)+"_"+IntegerToString((int)start_utc);
   string line_name=g_session_prefix+id+"_LINE";
   string text_name=g_session_prefix+id+"_TEXT";
   color marker_color=SessionColor(session);
   string text=SessionName(session)+"  "+TimeToString(tehran_time,TIME_MINUTES)+" Tehran";

   if(ObjectCreate(0,line_name,OBJ_VLINE,0,server_time,0.0))
     {
      ObjectSetInteger(0,line_name,OBJPROP_COLOR,marker_color);
      ObjectSetInteger(0,line_name,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,line_name,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,line_name,OBJPROP_BACK,true);
      ObjectSetInteger(0,line_name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,line_name,OBJPROP_HIDDEN,true);
      ObjectSetString(0,line_name,OBJPROP_TEXT,text);
      ObjectSetString(0,line_name,OBJPROP_TOOLTIP,text);
     }
   if(ObjectCreate(0,text_name,OBJ_TEXT,0,server_time,label_price))
     {
      ObjectSetString(0,text_name,OBJPROP_TEXT,text);
      ObjectSetString(0,text_name,OBJPROP_FONT,InpPanelFont);
      ObjectSetInteger(0,text_name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,text_name,OBJPROP_COLOR,marker_color);
      ObjectSetInteger(0,text_name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetDouble(0,text_name,OBJPROP_ANGLE,90.0);
      ObjectSetInteger(0,text_name,OBJPROP_BACK,false);
      ObjectSetInteger(0,text_name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,text_name,OBJPROP_HIDDEN,true);
     }
  }

void DrawSessionMarkers(const bool force=false)
  {
   if(!g_sessions_visible)
     {
      DeleteSessionMarkers();
      return;
     }
   datetime now=ServerNow();
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
   g_last_session_refresh=now;
   DeleteSessionMarkers();

   double price_max=0.0,price_min=0.0;
   ChartGetDouble(0,CHART_PRICE_MAX,0,price_max);
   ChartGetDouble(0,CHART_PRICE_MIN,0,price_min);
   double label_price=price_max-(price_max-price_min)*0.03;
   datetime today_utc=UTCMidnight(TimeGMT());
   int lookback=MathMax(1,MathMin(20,InpSessionLookbackDays));
   for(int day_offset=0;day_offset<lookback+4;day_offset++)
     {
      datetime utc_day=(datetime)((long)today_utc-(long)day_offset*86400);
      MqlDateTime tm={};
      TimeToStruct(utc_day,tm);
      for(int session=0;session<4;session++)
        {
         if(!SessionTradesOnUTCDay(session,tm.day_of_week))
            continue;
         CreateSessionMarker(session,SessionStartUTC(session,utc_day),label_price);
        }
     }
   ChartRedraw();
  }

string TodaySessionTehranTime(const int session)
  {
   datetime start=SessionStartUTC(session,UTCMidnight(TimeGMT()));
   return TimeToString((datetime)((long)start+TehranOffsetSeconds()),TIME_MINUTES);
  }

int VolumeDigits(double step)
  {
   int digits=0;
   while(digits<8 && MathAbs(step-MathRound(step))>1e-9)
     {
      step*=10.0;
      digits++;
     }
   return digits;
  }

double NormalizeVolumeFloor(const double requested,const bool allow_minimum)
  {
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0 || minimum<=0.0 || maximum<=0.0)
      return 0.0;

   if(requested<minimum-1e-12)
     {
      if(!allow_minimum)
         return 0.0;
      return NormalizeDouble(minimum,VolumeDigits(step));
     }

   double volume=MathFloor((requested+1e-12)/step)*step;
   volume=MathMax(minimum,MathMin(maximum,volume));
   return NormalizeDouble(volume,VolumeDigits(step));
  }

double NormalizePrice(const double price)
  {
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0)
      tick_size=_Point;
   return NormalizeDouble(MathRound(price/tick_size)*tick_size,_Digits);
  }

double NormalizePriceDown(const double price)
  {
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0)
      tick_size=_Point;
   return NormalizeDouble(MathFloor(price/tick_size+1e-10)*tick_size,_Digits);
  }

double NormalizePriceUp(const double price)
  {
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0)
      tick_size=_Point;
   return NormalizeDouble(MathCeil(price/tick_size-1e-10)*tick_size,_Digits);
  }

double MinimumStopDistance()
  {
   long stops_level=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double distance=(double)stops_level*_Point;
   return MathMax(distance,SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE));
  }

double MarketStopSafetyDistance(const MqlTick &tick,const double multiplier=1.0)
  {
   long stops_level=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   long freeze_level=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0)
      tick_size=_Point;
   double broker_distance=(double)MathMax(stops_level,freeze_level)*_Point;
   double spread=(tick.ask>tick.bid ? tick.ask-tick.bid : 0.0);
   double rounding_buffer=MathMax(2.0*tick_size,2.0*_Point);
   double base=MathMax(broker_distance,tick_size)+rounding_buffer;
   // A small spread-aware cushion protects symbols whose effective stop level
   // is dynamic even when SYMBOL_TRADE_STOPS_LEVEL reports zero.
   base=MathMax(base,spread*0.25+rounding_buffer);
   return base*MathMax(1.0,multiplier);
  }

double CurrentATR()
  {
   // Calculate ATR locally from closed bars. This avoids indicator-handle
   // error 4805 on broker symbols with suffixes or temporarily unsynced data.
   int period=MathMax(2,InpATRPeriod);
   MqlRates rates[];
   ArraySetAsSeries(rates,false);
   int copied=CopyRates(_Symbol,PERIOD_CURRENT,1,period+1,rates);
   if(copied>=period+1)
     {
      double total=0.0;
      int count=0;
      for(int i=1;i<copied;i++)
        {
         double range=rates[i].high-rates[i].low;
         double high_gap=MathAbs(rates[i].high-rates[i-1].close);
         double low_gap=MathAbs(rates[i].low-rates[i-1].close);
         total+=MathMax(range,MathMax(high_gap,low_gap));
         count++;
        }
      if(count>0 && total>0.0)
         return total/(double)count;
     }

   MqlTick tick={};
   SymbolInfoTick(_Symbol,tick);
   double fallback=MathMax(100.0*_Point,MinimumStopDistance()*2.0);
   if(tick.bid>0.0)
      fallback=MathMin(fallback,tick.bid*0.01);
   return fallback;
  }

double DefaultRiskDistance()
  {
   return MathMax(MathMax(CurrentATR()*MathMax(0.10,InpDefaultSL_ATR),
                           (double)MathMax(1,InpMinimumSLPoints)*_Point),
                  MinimumStopDistance()*1.25);
  }

bool IsBuyOrderType(const ENUM_ORDER_TYPE type)
  {
   return(type==ORDER_TYPE_BUY || type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_BUY_STOP_LIMIT);
  }

bool IsPendingOrderType(const ENUM_ORDER_TYPE type)
  {
   return(type==ORDER_TYPE_BUY_LIMIT || type==ORDER_TYPE_SELL_LIMIT ||
          type==ORDER_TYPE_BUY_STOP || type==ORDER_TYPE_SELL_STOP ||
          type==ORDER_TYPE_BUY_STOP_LIMIT || type==ORDER_TYPE_SELL_STOP_LIMIT);
  }

bool TradeRetcodeOK()
  {
   uint code=trade.ResultRetcode();
   return(code==TRADE_RETCODE_DONE || code==TRADE_RETCODE_PLACED || code==TRADE_RETCODE_DONE_PARTIAL);
  }

string RiskUnit()
  {
   if(InpRiskMode==RP_BALANCE_PERCENT || InpRiskMode==RP_EQUITY_PERCENT)
      return "%";
   if(InpRiskMode==RP_FIXED_LOT)
      return "lot";
   return AccountInfoString(ACCOUNT_CURRENCY);
  }

string PriceText(const double price)
  {
   return DoubleToString(price,_Digits);
  }

string MoneyText(const double value)
  {
   return StringFormat("%.2f %s",value,AccountInfoString(ACCOUNT_CURRENCY));
  }

void SetStatus(const string text_value,const color text_color=RP_MUTED,const int seconds=5)
  {
   g_status=text_value;
   g_status_color=text_color;
   g_status_until=(seconds>0 ? ServerNow()+seconds : 0);
   if(ObjectFind(0,UI("STATUS"))>=0)
     {
      ObjectSetString(0,UI("STATUS"),OBJPROP_TEXT,g_status);
      ObjectSetInteger(0,UI("STATUS"),OBJPROP_COLOR,g_status_color);
     }
  }

void RegisterUIObject(const string name)
  {
   int size=ArraySize(g_ui_objects);
   ArrayResize(g_ui_objects,size+1);
   g_ui_objects[size]=name;
  }

void SetObjectTextIfChanged(const string name,const string value)
  {
   if(ObjectFind(0,name)<0 || ObjectGetString(0,name,OBJPROP_TEXT)==value)
      return;
   ObjectSetString(0,name,OBJPROP_TEXT,value);
  }

void SetObjectIntegerIfChanged(const string name,const ENUM_OBJECT_PROPERTY_INTEGER property,const long value)
  {
   if(ObjectFind(0,name)<0 || ObjectGetInteger(0,name,property)==value)
      return;
   ObjectSetInteger(0,name,property,value);
  }

//+------------------------------------------------------------------+
//| Chart object helpers                                             |
//+------------------------------------------------------------------+
void CommonObjectProps(const string name)
  {
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
  }

bool CreateRectangle(const string name,const int x,const int y,const int width,const int height,
                     const color background,const color border)
  {
   if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0))
      return false;
   RegisterUIObject(name);
   CommonObjectProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,100);
   return true;
  }

bool CreateLabel(const string name,const string text_value,const int x,const int y,const int size,
                 const color text_color,const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
  {
   if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0))
      return false;
   RegisterUIObject(name);
   CommonObjectProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
   ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont);
   ObjectSetString(0,name,OBJPROP_TEXT,text_value);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,110);
   return true;
  }

bool CreateButton(const string name,const string text_value,const int x,const int y,const int width,
                  const int height,const color background,const color text_color,const color border)
  {
   if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0))
      return false;
   RegisterUIObject(name);
   CommonObjectProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,background);
   ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont);
   ObjectSetString(0,name,OBJPROP_TEXT,text_value);
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,120);
   return true;
  }

bool CreateEdit(const string name,const string text_value,const int x,const int y,const int width,const int height)
  {
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return false;
   RegisterUIObject(name);
   CommonObjectProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,RP_BG);
   ObjectSetInteger(0,name,OBJPROP_COLOR,RP_TEXT);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,RP_BORDER);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,name,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont);
   ObjectSetString(0,name,OBJPROP_TEXT,text_value);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,125);
   return true;
  }

void DeleteUI()
  {
   ObjectsDeleteAll(0,g_ui_prefix);
   ArrayResize(g_ui_objects,0);
  }

void DeleteDesignerLines()
  {
   ObjectsDeleteAll(0,g_line_prefix);
  }

string PanelPositionKey(const string suffix)
  {
   return StringFormat("ARKO_PANEL_%I64d_%s",ChartID(),suffix);
  }

void ClampPanelPosition()
  {
   long chart_width=1000;
   long chart_height=700;
   ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,chart_width);
   ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,chart_height);
   int visible_height=(g_collapsed ? 48 : g_panel_h);
   int max_x=MathMax(0,(int)chart_width-g_panel_w);
   int max_y=MathMax(0,(int)chart_height-visible_height);
   g_panel_x=MathMax(0,MathMin(max_x,g_panel_x));
   g_panel_y=MathMax(0,MathMin(max_y,g_panel_y));
  }

void EnsurePanelPosition()
  {
   if(!g_panel_position_initialized)
     {
      if(InpRememberPanelPosition &&
         GlobalVariableCheck(PanelPositionKey("X")) &&
         GlobalVariableCheck(PanelPositionKey("Y")))
        {
         g_panel_x=(int)GlobalVariableGet(PanelPositionKey("X"));
         g_panel_y=(int)GlobalVariableGet(PanelPositionKey("Y"));
        }
      else
        {
         long chart_width=1000;
         ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,chart_width);
         g_panel_x=MathMax(8,(int)chart_width-g_panel_w-18);
         g_panel_y=18;
        }
      g_panel_position_initialized=true;
     }
   ClampPanelPosition();
  }

void SavePanelPosition()
  {
   if(!InpRememberPanelPosition)
      return;
   GlobalVariableSet(PanelPositionKey("X"),(double)g_panel_x);
   GlobalVariableSet(PanelPositionKey("Y"),(double)g_panel_y);
  }

bool PointIsInPanelHeader(const int mouse_x,const int mouse_y)
  {
   // Keep the collapse button area clickable instead of treating it as a drag.
   return(mouse_x>=g_panel_x && mouse_x<=g_panel_x+280 &&
          mouse_y>=g_panel_y && mouse_y<=g_panel_y+48);
  }

void MovePanelObjects(const int target_x,const int target_y)
  {
   int old_x=g_panel_x;
   int old_y=g_panel_y;
   g_panel_x=target_x;
   g_panel_y=target_y;
   ClampPanelPosition();
   int delta_x=g_panel_x-old_x;
   int delta_y=g_panel_y-old_y;
   if(delta_x==0 && delta_y==0)
      return;

   int total=ArraySize(g_ui_objects);
   for(int i=0;i<total;i++)
     {
      string name=g_ui_objects[i];
      if(ObjectFind(0,name)<0)
         continue;
      long x=ObjectGetInteger(0,name,OBJPROP_XDISTANCE);
      long y=ObjectGetInteger(0,name,OBJPROP_YDISTANCE);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x+delta_x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y+delta_y);
     }
   ulong now=GetTickCount64();
   if(now-g_last_panel_redraw_ms>=16)
     {
      ChartRedraw();
      g_last_panel_redraw_ms=now;
     }
  }

void FinishPanelDrag(const bool save_position=true)
  {
   if(!g_panel_dragging)
      return;
   g_panel_dragging=false;
   ChartSetInteger(0,CHART_MOUSE_SCROLL,g_previous_mouse_scroll);
   SetDesignerLinesInteraction(true,InpKeepLimitLinesSelected);
   if(save_position)
      SavePanelPosition();
  }

void CreateSectionTitle(const string name,const string title,const int y)
  {
   CreateLabel(UI(name),title,g_panel_x+14,y,8,RP_MUTED);
  }

void BuildCollapsedPanel()
  {
   EnsurePanelPosition();
   int x=g_panel_x;
   int y=g_panel_y;
   CreateRectangle(UI("BG"),x,y,g_panel_w,46,RP_BG,RP_BORDER);
   CreateLabel(UI("TITLE"),"ARKORISK MT5",x+14,y+8,11,RP_TEXT);
   CreateLabel(UI("MINI_STATS"),"Drag header to move",x+14,y+28,8,RP_MUTED);
   CreateButton(UI("COLLAPSE"),"+",x+292,y+9,26,26,RP_CARD,RP_TEXT,RP_BORDER);
  }

void BuildTradeTab(const int x,const int y)
  {
   CreateRectangle(UI("ACCOUNT_CARD"),x+10,y+88,310,53,RP_CARD_2,RP_BORDER);
   CreateLabel(UI("BALANCE"),"Balance",x+20,y+98,8,RP_TEXT);
   CreateLabel(UI("EQUITY"),"Equity",x+172,y+98,8,RP_TEXT);
   CreateLabel(UI("DAY_PL"),"Day P/L",x+20,y+120,8,RP_TEXT);
   CreateLabel(UI("SPREAD"),"Spread",x+172,y+120,8,RP_TEXT);

   CreateRectangle(UI("RISK_CARD"),x+10,y+148,310,70,RP_CARD_2,RP_BORDER);
   CreateLabel(UI("RISK_LABEL"),"Risk",x+18,y+160,8,RP_TEXT);
   CreateButton(UI("RISK_MINUS"),"-",x+49,y+155,23,26,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(UI("RISK_EDIT"),DoubleToString(g_risk_value,2),x+76,y+155,50,26);
   CreateButton(UI("RISK_PLUS"),"+",x+130,y+155,23,26,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(UI("RISK_UNIT"),RiskUnit(),x+157,y+162,7,RP_MUTED);
   CreateLabel(UI("RR_LABEL"),"RR",x+204,y+160,8,RP_TEXT);
   CreateButton(UI("RR_MINUS"),"-",x+224,y+155,23,26,RP_CARD,RP_TEXT,RP_BORDER);
   CreateEdit(UI("RR_EDIT"),DoubleToString(g_rr,2),x+251,y+155,43,26);
   CreateButton(UI("RR_PLUS"),"+",x+298,y+155,23,26,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(UI("PREVIEW"),"Calculating volume...",x+18,y+193,8,RP_BLUE);

   CreateButton(UI("BUY_NOW"),"BUY NOW",x+10,y+226,151,34,RP_GREEN,RP_WHITE,RP_GREEN);
   CreateButton(UI("SELL_NOW"),"SELL NOW",x+169,y+226,151,34,RP_RED,RP_WHITE,RP_RED);
   CreateButton(UI("BUY_LIMIT"),"BUY LIMIT",x+10,y+267,151,31,RP_GREEN_2,RP_WHITE,RP_GREEN_2);
   CreateButton(UI("SELL_LIMIT"),"SELL LIMIT",x+169,y+267,151,31,RP_RED_2,RP_WHITE,RP_RED_2);
   CreateButton(UI("PLACE"),"PLACE LIMIT",x+10,y+305,150,33,RP_BLUE,RP_BG,RP_BLUE);
   CreateButton(UI("RESET"),"RESET",x+166,y+305,62,33,RP_CARD,RP_TEXT,RP_BORDER);
   CreateButton(UI("RR_LINK"),g_auto_tp_from_rr?"RR LINK":"FREE LINES",x+234,y+305,86,33,
                g_auto_tp_from_rr?RP_GREEN_2:RP_CARD,RP_TEXT,g_auto_tp_from_rr?RP_GREEN_2:RP_BORDER);

   CreateButton(UI("LINES_LOCK"),g_designer_lines_locked?"UNLOCK":"LINES FREE",x+10,y+345,92,30,
                g_designer_lines_locked?RP_AMBER:RP_GREEN_2,RP_TEXT,g_designer_lines_locked?RP_AMBER:RP_GREEN_2);
   CreateButton(UI("DELETE_LINES"),"DELETE",x+108,y+345,92,30,RP_CARD,RP_AMBER,RP_BORDER);
   CreateButton(UI("CANCEL_PENDING"),"CANCEL",x+206,y+345,114,30,RP_CARD,RP_AMBER,RP_BORDER);
   CreateLabel(UI("LEVELS"),"Drag ENTRY / SL / TP lines directly on chart",x+14,y+388,8,RP_MUTED);
  }

void BuildManageTab(const int x,const int y)
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

void BuildNewsTab(const int x,const int y)
  {
   CreateLabel(UI("NEWS_TITLE"),"TODAY'S FOREX NEWS  •  TEHRAN",x+14,y+92,9,RP_TEXT);
   CreateButton(UI("NEWS_REFRESH"),"REFRESH",x+10,y+112,72,29,RP_CARD,RP_TEXT,RP_BORDER);
   CreateButton(UI("NEWS_FILTER"),g_news_high_only?"HIGH ONLY":"ALL IMPACT",x+87,y+112,85,29,
                g_news_high_only?RP_RED_2:RP_CARD,RP_TEXT,g_news_high_only?RP_RED_2:RP_BORDER);
   CreateButton(UI("NEWS_PREV"),"<",x+207,y+112,27,29,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(UI("NEWS_PAGE"),"1 / 1",x+239,y+120,8,RP_MUTED);
   CreateButton(UI("NEWS_NEXT"),">",x+293,y+112,27,29,RP_CARD,RP_TEXT,RP_BORDER);
   CreateLabel(UI("NEWS_COLUMNS"),"TIME       FX     IMPACT     EVENT",x+17,y+151,7,RP_MUTED);
   for(int i=0;i<RP_NEWS_ROWS;i++)
     {
      int row_y=y+168+i*37;
      CreateRectangle(UI("NEWS_BG_"+IntegerToString(i)),x+10,row_y,310,32,RP_CARD_2,RP_BORDER);
      CreateLabel(UI("NEWS_TIME_"+IntegerToString(i)),"--:--",x+17,row_y+9,8,RP_MUTED);
      CreateLabel(UI("NEWS_CUR_"+IntegerToString(i)),"---",x+70,row_y+9,8,RP_TEXT);
      CreateLabel(UI("NEWS_IMP_"+IntegerToString(i)),"----",x+105,row_y+9,8,RP_MUTED);
      CreateLabel(UI("NEWS_EVENT_"+IntegerToString(i)),"Loading...",x+158,row_y+9,8,RP_TEXT);
     }
   CreateLabel(UI("NEWS_GUARD_INFO"),"News guard checking high-impact events...",x+14,y+398,8,RP_MUTED);
  }

void BuildChartTab(const int x,const int y)
  {
   CreateLabel(UI("THEME_TITLE"),"CHART THEME",x+14,y+95,9,RP_TEXT);
   CreateButton(UI("THEME_DARK"),"DARK",x+10,y+116,98,33,
                g_chart_theme==RP_THEME_DARK?RP_BLUE:RP_CARD,RP_TEXT,g_chart_theme==RP_THEME_DARK?RP_BLUE:RP_BORDER);
   CreateButton(UI("THEME_LIGHT"),"LIGHT",x+116,y+116,98,33,
                g_chart_theme==RP_THEME_LIGHT?RP_BLUE:RP_CARD,RP_TEXT,g_chart_theme==RP_THEME_LIGHT?RP_BLUE:RP_BORDER);
   CreateButton(UI("THEME_ORIGINAL"),"ORIGINAL",x+222,y+116,98,33,
                g_chart_theme==RP_THEME_KEEP?RP_BLUE:RP_CARD,RP_TEXT,g_chart_theme==RP_THEME_KEEP?RP_BLUE:RP_BORDER);

   CreateLabel(UI("SESSION_TITLE"),"FOREX SESSION MARKERS",x+14,y+170,9,RP_TEXT);
   CreateButton(UI("SESSIONS_TOGGLE"),g_sessions_visible?"SESSIONS ON":"SESSIONS OFF",x+10,y+191,151,32,
                g_sessions_visible?RP_GREEN_2:RP_CARD,RP_TEXT,g_sessions_visible?RP_GREEN_2:RP_BORDER);
   CreateButton(UI("SESSIONS_REDRAW"),"REDRAW",x+169,y+191,151,32,RP_CARD,RP_TEXT,RP_BORDER);

   CreateLabel(UI("TIMER_TITLE"),"CANDLE COUNTDOWN",x+14,y+244,9,RP_TEXT);
   CreateButton(UI("TIMER_TOGGLE"),g_timer_visible?"TIMER ON":"TIMER OFF",x+10,y+265,310,32,
                g_timer_visible?RP_GREEN_2:RP_CARD,RP_TEXT,g_timer_visible?RP_GREEN_2:RP_BORDER);

   CreateRectangle(UI("SESSION_CARD"),x+10,y+316,310,96,RP_CARD_2,RP_BORDER);
   for(int session=0;session<4;session++)
     {
      int row_y=y+327+session*21;
      CreateLabel(UI("SESSION_DOT_"+IntegerToString(session)),"●",x+20,row_y,9,SessionColor(session));
      CreateLabel(UI("SESSION_INFO_"+IntegerToString(session)),SessionName(session),x+40,row_y,8,RP_TEXT);
     }
  }

void BuildFullPanel()
  {
   EnsurePanelPosition();
   int x=g_panel_x;
   int y=g_panel_y;
   CreateRectangle(UI("BG"),x,y,g_panel_w,g_panel_h,RP_BG,RP_BORDER);
   CreateLabel(UI("TITLE"),"ARKORISK MT5",x+14,y+8,11,RP_TEXT);
   CreateLabel(UI("SUBTITLE"),"drag to move",x+14,y+29,8,RP_MUTED);
   CreateButton(UI("COLLAPSE"),"-",x+292,y+9,26,26,RP_CARD,RP_TEXT,RP_BORDER);

   CreateButton(UI("TAB_TRADE"),"TRADE",x+10,y+50,72,29,g_active_tab==RP_TAB_TRADE?RP_BLUE:RP_CARD,
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
   CreateLabel(UI("STATUS"),g_status,x+12,y+435,8,g_status_color);
  }

void BuildPanel()
  {
   DeleteUI();
   if(g_collapsed)
      BuildCollapsedPanel();
   else
      BuildFullPanel();
   ChartRedraw();
  }

void SetLabelText(const string suffix,const string value,const color text_color=clrNONE)
  {
   string name=UI(suffix);
   if(ObjectFind(0,name)<0)
      return;
   SetObjectTextIfChanged(name,value);
   if(text_color!=clrNONE)
      SetObjectIntegerIfChanged(name,OBJPROP_COLOR,text_color);
  }

void ReleaseButton(const string object_name)
  {
   if(ObjectFind(0,object_name)>=0)
      ObjectSetInteger(0,object_name,OBJPROP_STATE,false);
  }

//+------------------------------------------------------------------+
//| Designer lines                                                   |
//+------------------------------------------------------------------+
bool CreateOrMoveLine(const string name,const double price,const color line_color,const ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,NormalizePrice(price)))
         return false;
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,!g_designer_lines_locked);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,!g_designer_lines_locked && InpKeepLimitLinesSelected);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,5);
     }
   ObjectSetDouble(0,name,OBJPROP_PRICE,NormalizePrice(price));
   ObjectSetInteger(0,name,OBJPROP_COLOR,line_color);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,!g_designer_lines_locked);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,!g_designer_lines_locked && InpKeepLimitLinesSelected);
   return true;
  }

bool IsDesignerLine(const string name)
  {
   return(name==LINE("ENTRY") || name==LINE("SL") || name==LINE("TP"));
  }

double LinePrice(const string suffix)
  {
   string name=LINE(suffix);
   if(ObjectFind(0,name)<0)
      return 0.0;
   return ObjectGetDouble(0,name,OBJPROP_PRICE);
  }

bool DesignerExists()
  {
   return(ObjectFind(0,LINE("ENTRY"))>=0 && ObjectFind(0,LINE("SL"))>=0 && ObjectFind(0,LINE("TP"))>=0);
  }

void SetDesignerLinesInteraction(const bool enabled,const bool select_lines=false)
  {
   string names[3];
   names[0]=LINE("ENTRY");
   names[1]=LINE("SL");
   names[2]=LINE("TP");
   for(int i=0;i<3;i++)
     {
      if(ObjectFind(0,names[i])<0)
         continue;
      bool interactive=(enabled && !g_designer_lines_locked);
      ObjectSetInteger(0,names[i],OBJPROP_SELECTED,interactive && select_lines);
      ObjectSetInteger(0,names[i],OBJPROP_SELECTABLE,interactive);
     }
  }

void ToggleDesignerLinesLock()
  {
   g_designer_lines_locked=!g_designer_lines_locked;
   SetDesignerLinesInteraction(true,InpKeepLimitLinesSelected);
   SetStatus(g_designer_lines_locked ? "Designer lines locked" : "Designer lines unlocked — drag directly",
             g_designer_lines_locked?RP_AMBER:RP_GREEN,5);
   UpdatePanel();
   ChartRedraw();
  }

void RemoveDesignerLines()
  {
   DeleteDesignerLines();
   SetStatus("Limit designer lines removed",RP_AMBER,4);
   UpdatePanel();
   ChartRedraw();
  }

void UpdateLineTooltips()
  {
   if(!DesignerExists())
      return;
   ObjectSetString(0,LINE("ENTRY"),OBJPROP_TOOLTIP,StringFormat("ENTRY  %s",PriceText(LinePrice("ENTRY"))));
   ObjectSetString(0,LINE("SL"),OBJPROP_TOOLTIP,StringFormat("STOP LOSS  %s",PriceText(LinePrice("SL"))));
   ObjectSetString(0,LINE("TP"),OBJPROP_TOOLTIP,StringFormat("TAKE PROFIT  %s",PriceText(LinePrice("TP"))));
   ObjectSetString(0,LINE("ENTRY"),OBJPROP_TEXT,"ENTRY");
   ObjectSetString(0,LINE("SL"),OBJPROP_TEXT,"STOP LOSS");
   ObjectSetString(0,LINE("TP"),OBJPROP_TEXT,"TAKE PROFIT");
  }

void ResetDesigner(const bool buy_side)
  {
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0)
     {
      SetStatus("No live quote for this symbol",RP_RED,5);
      return;
     }

   g_is_buy=buy_side;
   double min_stop=MinimumStopDistance();
   double gap=MathMax(CurrentATR()*MathMax(0.05,InpLimitGap_ATR),min_stop*1.25);
   double risk_distance=DefaultRiskDistance();
   double entry=(buy_side ? tick.bid-gap : tick.ask+gap);
   double stop=(buy_side ? entry-risk_distance : entry+risk_distance);
   double target=(buy_side ? entry+risk_distance*g_rr : entry-risk_distance*g_rr);

   CreateOrMoveLine(LINE("ENTRY"),entry,RP_BLUE,STYLE_SOLID);
   CreateOrMoveLine(LINE("SL"),stop,RP_RED,STYLE_DASH);
   CreateOrMoveLine(LINE("TP"),target,RP_GREEN,STYLE_DASH);
   UpdateLineTooltips();
   UpdateTradePreviewLabels();
   SetStatus(buy_side ? "Buy Limit designer selected" : "Sell Limit designer selected",RP_BLUE,3);
   UpdatePanel();
   ChartRedraw();
  }

bool ValidateDesigner(string &reason)
  {
   if(!DesignerExists())
     {
      reason="Designer lines are missing";
      return false;
     }
   double entry=LinePrice("ENTRY");
   double sl=LinePrice("SL");
   double tp=LinePrice("TP");
   if(entry<=0.0 || sl<=0.0 || tp<=0.0)
     {
      reason="Invalid line price";
      return false;
     }
   if(g_is_buy && !(sl<entry && tp>entry))
     {
      reason="BUY setup needs SL below and TP above entry";
      return false;
     }
   if(!g_is_buy && !(sl>entry && tp<entry))
     {
      reason="SELL setup needs SL above and TP below entry";
      return false;
     }
   if(MathAbs(entry-sl)<MinimumStopDistance())
     {
      reason="SL distance is below broker minimum";
      return false;
     }
   return true;
  }

void SyncDesignerAfterDrag(const string dragged_name)
  {
   if(!DesignerExists())
      return;
   double entry=NormalizePrice(LinePrice("ENTRY"));
   double sl=NormalizePrice(LinePrice("SL"));
   double tp=NormalizePrice(LinePrice("TP"));
   double fallback=DefaultRiskDistance();

   if(g_is_buy)
     {
      if(sl>=entry)
         sl=NormalizePrice(entry-fallback);
      if(dragged_name==LINE("TP"))
        {
         if(tp<=entry)
            tp=NormalizePrice(entry+MathAbs(entry-sl)*g_rr);
         else
            g_rr=ClampDouble((tp-entry)/(entry-sl),0.10,20.0);
        }
      else if(g_auto_tp_from_rr)
         tp=NormalizePrice(entry+(entry-sl)*g_rr);
     }
   else
     {
      if(sl<=entry)
         sl=NormalizePrice(entry+fallback);
      if(dragged_name==LINE("TP"))
        {
         if(tp>=entry)
            tp=NormalizePrice(entry-MathAbs(sl-entry)*g_rr);
         else
            g_rr=ClampDouble((entry-tp)/(sl-entry),0.10,20.0);
        }
      else if(g_auto_tp_from_rr)
         tp=NormalizePrice(entry-(sl-entry)*g_rr);
     }

   ObjectSetDouble(0,LINE("ENTRY"),OBJPROP_PRICE,entry);
   ObjectSetDouble(0,LINE("SL"),OBJPROP_PRICE,sl);
   ObjectSetDouble(0,LINE("TP"),OBJPROP_PRICE,tp);
   if(ObjectFind(0,UI("RR_EDIT"))>=0)
      ObjectSetString(0,UI("RR_EDIT"),OBJPROP_TEXT,DoubleToString(g_rr,2));
   UpdateLineTooltips();
   UpdateTradePreviewLabels();
   UpdatePanel();
   ChartRedraw();
  }

void UpdateTargetFromRR()
  {
   if(!DesignerExists())
      return;
   double entry=LinePrice("ENTRY");
   double sl=LinePrice("SL");
   if(g_is_buy && sl<entry)
      ObjectSetDouble(0,LINE("TP"),OBJPROP_PRICE,NormalizePrice(entry+(entry-sl)*g_rr));
   if(!g_is_buy && sl>entry)
      ObjectSetDouble(0,LINE("TP"),OBJPROP_PRICE,NormalizePrice(entry-(sl-entry)*g_rr));
   UpdateLineTooltips();
   UpdateTradePreviewLabels();
  }

void ToggleRRLink()
  {
   g_auto_tp_from_rr=!g_auto_tp_from_rr;
   if(g_auto_tp_from_rr)
      UpdateTargetFromRR();
   SetStatus(g_auto_tp_from_rr ? "RR Link enabled: TP follows Entry/SL" :
                                 "RR Link disabled: all lines move independently",
             g_auto_tp_from_rr?RP_GREEN:RP_AMBER,5);
   UpdatePanel();
  }

//+------------------------------------------------------------------+
//| Risk sizing                                                      |
//+------------------------------------------------------------------+
bool ProfitForOneLotSymbol(const string symbol_name,const bool buy_side,const double open_price,
                           const double close_price,double &profit)
  {
   ENUM_ORDER_TYPE calc_type=(buy_side ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcProfit(calc_type,symbol_name,1.0,open_price,close_price,profit))
      return true;

   double tick_size=SymbolInfoDouble(symbol_name,SYMBOL_TRADE_TICK_SIZE);
   double tick_value=SymbolInfoDouble(symbol_name,SYMBOL_TRADE_TICK_VALUE);
   if(tick_size<=0.0 || tick_value<=0.0)
      return false;
   double ticks=MathAbs(close_price-open_price)/tick_size;
   profit=(close_price==open_price ? 0.0 : ticks*tick_value);
   if((buy_side && close_price<open_price) || (!buy_side && close_price>open_price))
      profit=-profit;
   return true;
  }

bool ProfitForOneLot(const bool buy_side,const double open_price,const double close_price,double &profit)
  {
   return ProfitForOneLotSymbol(_Symbol,buy_side,open_price,close_price,profit);
  }

bool CalculateVolume(const bool buy_side,const double entry,const double sl,double &volume,
                     double &risk_money,string &reason)
  {
   volume=0.0;
   risk_money=0.0;
   if(entry<=0.0 || sl<=0.0 || MathAbs(entry-sl)<SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE))
     {
      reason="Entry/SL distance is invalid";
      return false;
     }

   double loss_one_lot=0.0;
   if(!ProfitForOneLot(buy_side,entry,sl,loss_one_lot) || MathAbs(loss_one_lot)<1e-9)
     {
      reason="Broker did not provide tick-value data";
      return false;
     }
   loss_one_lot=MathAbs(loss_one_lot);

   double requested=0.0;
   if(InpRiskMode==RP_FIXED_LOT)
     {
      requested=g_risk_value;
      volume=NormalizeVolumeFloor(requested,InpAllowMinimumLotRiskOverflow);
      risk_money=loss_one_lot*volume;
     }
   else
     {
      if(InpRiskMode==RP_BALANCE_PERCENT)
         risk_money=AccountInfoDouble(ACCOUNT_BALANCE)*g_risk_value/100.0;
      else if(InpRiskMode==RP_EQUITY_PERCENT)
         risk_money=AccountInfoDouble(ACCOUNT_EQUITY)*g_risk_value/100.0;
      else
         risk_money=g_risk_value;

      if(risk_money<=0.0)
        {
         reason="Risk value must be greater than zero";
         return false;
        }
      requested=risk_money/loss_one_lot;
      volume=NormalizeVolumeFloor(requested,InpAllowMinimumLotRiskOverflow);
      if(volume>0.0)
         risk_money=loss_one_lot*volume; // actual normalized risk
     }

   if(volume<=0.0)
     {
      double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
      reason=StringFormat("Calculated lot is below broker minimum (%s)",DoubleToString(minimum,VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP))));
      return false;
     }

   double margin=0.0;
   ENUM_ORDER_TYPE calc_type=(buy_side ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   if(OrderCalcMargin(calc_type,_Symbol,volume,entry,margin) && margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)*0.98)
     {
      double free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE)*0.98;
      double reduced=(margin>0.0 ? volume*free_margin/margin : 0.0);
      volume=NormalizeVolumeFloor(reduced,false);
      if(volume<=0.0)
        {
         reason="Not enough free margin for minimum volume";
         return false;
        }
      risk_money=loss_one_lot*volume;
     }
   return true;
  }

void DeleteTradePreviewLabels()
  {
   ObjectDelete(0,LINE("PREVIEW_ENTRY"));
   ObjectDelete(0,LINE("PREVIEW_SL"));
   ObjectDelete(0,LINE("PREVIEW_TP"));
  }

void CreateOrUpdatePreviewText(const string name,const datetime label_time,const double price,
                               const string text_value,const color text_color)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_TEXT,0,label_time,price))
         return;
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,6);
      ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont);
     }
   else
     {
      datetime old_time=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
      double old_price=ObjectGetDouble(0,name,OBJPROP_PRICE,0);
      if(old_time!=label_time || MathAbs(old_price-price)>_Point*0.1)
         ObjectMove(0,name,0,label_time,price);
     }
   SetObjectTextIfChanged(name,text_value);
   SetObjectIntegerIfChanged(name,OBJPROP_COLOR,text_color);
  }

void UpdateTradePreviewLabels()
  {
   if(!InpShowTradePreviewLabels || !DesignerExists())
     {
      DeleteTradePreviewLabels();
      return;
     }
   double entry=LinePrice("ENTRY");
   double sl=LinePrice("SL");
   double tp=LinePrice("TP");
   double volume=0.0,risk_money=0.0,reward_one=0.0;
   string reason="";
   if(!CalculateVolume(g_is_buy,entry,sl,volume,risk_money,reason) ||
      !ProfitForOneLot(g_is_buy,entry,tp,reward_one))
     {
      DeleteTradePreviewLabels();
      return;
     }
   double reward_money=MathAbs(reward_one)*volume;
   double rr=(risk_money>0.0 ? reward_money/risk_money : 0.0);
   double pip=PipSize();
   double stop_pips=(pip>0.0 ? MathAbs(entry-sl)/pip : 0.0);
   double target_pips=(pip>0.0 ? MathAbs(tp-entry)/pip : 0.0);
   int volume_digits=VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP));
   datetime label_time=iTime(_Symbol,PERIOD_CURRENT,0);
   if(label_time<=0)
      label_time=ServerNow();
   CreateOrUpdatePreviewText(LINE("PREVIEW_ENTRY"),label_time,entry,
      StringFormat("  ENTRY  %s lot",DoubleToString(volume,volume_digits)),RP_BLUE);
   CreateOrUpdatePreviewText(LINE("PREVIEW_SL"),label_time,sl,
      StringFormat("  SL  -%s  |  %.1f pips",MoneyText(risk_money),stop_pips),RP_RED);
   CreateOrUpdatePreviewText(LINE("PREVIEW_TP"),label_time,tp,
      StringFormat("  TP  +%s  |  %.1f pips  |  RR 1:%.2f",MoneyText(reward_money),target_pips,rr),RP_GREEN);
  }

//+------------------------------------------------------------------+
//| Daily statistics and risk guards                                 |
//+------------------------------------------------------------------+
bool ScopeMatches(const string symbol_name,const long magic)
  {
   if(InpDailyGuardScope==RP_SCOPE_ACCOUNT)
      return true;
   if(magic!=(long)InpMagicNumber)
      return false;
   if(InpDailyGuardScope==RP_SCOPE_EA_SYMBOL && symbol_name!=_Symbol)
      return false;
   return true;
  }

void GetDailyStats(double &realized,double &floating,int &trade_count)
  {
   datetime cache_now=ServerNow();
   if(g_daily_stats_cache_time==cache_now && cache_now>0)
     {
      realized=g_cached_realized;
      floating=g_cached_floating;
      trade_count=g_cached_trade_count;
      return;
     }
   realized=0.0;
   floating=0.0;
   trade_count=0;
   datetime from=StartOfServerDay();
   datetime to=ServerNow();
   if(HistorySelect(from,to))
     {
      int total=HistoryDealsTotal();
      for(int i=0;i<total;i++)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
            continue;
         ENUM_DEAL_TYPE deal_type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(deal_type!=DEAL_TYPE_BUY && deal_type!=DEAL_TYPE_SELL)
            continue;
         string symbol_name=HistoryDealGetString(ticket,DEAL_SYMBOL);
         long magic=HistoryDealGetInteger(ticket,DEAL_MAGIC);
         if(!ScopeMatches(symbol_name,magic))
            continue;

         realized+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         realized+=HistoryDealGetDouble(ticket,DEAL_SWAP);
         realized+=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         realized+=HistoryDealGetDouble(ticket,DEAL_FEE);
         ENUM_DEAL_ENTRY entry_type=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry_type==DEAL_ENTRY_IN || entry_type==DEAL_ENTRY_INOUT)
            trade_count++;
        }
     }

   int positions=PositionsTotal();
   for(int i=0;i<positions;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(!ScopeMatches(symbol_name,magic))
         continue;
      floating+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
     }
   g_cached_realized=realized;
   g_cached_floating=floating;
   g_cached_trade_count=trade_count;
   g_daily_stats_cache_time=cache_now;
  }

string GuardStateKey(const string suffix)
  {
   string symbol_part=(InpDailyGuardScope==RP_SCOPE_EA_SYMBOL ? _Symbol : "ALL");
   return StringFormat("ARKO_GUARD_%I64d_%I64u_%d_%s_%s",AccountInfoInteger(ACCOUNT_LOGIN),
                       InpMagicNumber,(int)InpDailyGuardScope,symbol_part,suffix);
  }

bool IsDailyGuardLocked(int &lock_type)
  {
   lock_type=0;
   string day_key=GuardStateKey("DAY");
   string type_key=GuardStateKey("TYPE");
   datetime today=StartOfServerDay();
   if(!GlobalVariableCheck(day_key) || (datetime)GlobalVariableGet(day_key)!=today)
      return false;
   lock_type=(GlobalVariableCheck(type_key) ? (int)GlobalVariableGet(type_key) : 1);
   if((lock_type==1 && !InpUseDailyLossGuard) || (lock_type==2 && !InpUseDailyProfitTarget))
      return false;
   return true;
  }

void LockDailyGuard(const int lock_type)
  {
   GlobalVariableSet(GuardStateKey("DAY"),(double)StartOfServerDay());
   GlobalVariableSet(GuardStateKey("TYPE"),(double)lock_type);
   g_guard_last_action_day=StartOfServerDay();
  }

int DailyGuardThresholdReached(double &day_result,double &limit_value)
  {
   double realized=0.0,floating=0.0;
   int trades=0;
   GetDailyStats(realized,floating,trades);
   day_result=realized+(InpIncludeFloatingInDailyLoss ? floating : 0.0);
   double start_balance=MathMax(0.01,AccountInfoDouble(ACCOUNT_BALANCE)-realized);

   if(InpUseDailyLossGuard)
     {
      limit_value=(InpDailyLossMode==RP_GUARD_MONEY ? InpMaxDailyLossMoney
                   : start_balance*InpMaxDailyLossPercent/100.0);
      if(limit_value>0.0 && day_result<=-limit_value)
         return 1;
     }
   if(InpUseDailyProfitTarget)
     {
      limit_value=(InpDailyProfitMode==RP_GUARD_MONEY ? InpDailyProfitTargetMoney
                   : start_balance*InpDailyProfitTargetPercent/100.0);
      if(limit_value>0.0 && day_result>=limit_value)
         return 2;
     }
   limit_value=0.0;
   return 0;
  }

int CloseGuardScopePositions()
  {
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(!ScopeMatches(symbol_name,magic))
         continue;
      trade.SetTypeFillingBySymbol(symbol_name);
      if(trade.PositionClose(ticket,InpDeviationPoints) && TradeRetcodeOK())
         closed++;
     }
   trade.SetTypeFillingBySymbol(_Symbol);
   return closed;
  }

int CancelGuardScopePending()
  {
   int deleted=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) ||
         !ScopeMatches(OrderGetString(ORDER_SYMBOL),OrderGetInteger(ORDER_MAGIC)))
         continue;
      if(trade.OrderDelete(ticket) && TradeRetcodeOK())
         deleted++;
     }
   return deleted;
  }

void EnforceDailyGuard()
  {
   datetime today=StartOfServerDay();
   if(g_guard_last_action_day>0 && g_guard_last_action_day!=today)
     {
      g_guard_last_action_day=0;
      SetStatus("New trading day • Prop Guard unlocked",RP_GREEN,5);
     }
   int existing_type=0;
   if(IsDailyGuardLocked(existing_type))
     {
      datetime now=ServerNow();
      if(now-g_last_guard_retry>=5)
        {
         g_last_guard_retry=now;
         bool close_positions=(existing_type==1 ? InpClosePositionsAtDailyLoss : InpClosePositionsAtProfitTarget);
         bool cancel_pending=(existing_type==1 ? InpCancelPendingAtDailyLoss : InpCancelPendingAtProfitTarget);
         if(close_positions)
            CloseGuardScopePositions();
         if(cancel_pending)
            CancelGuardScopePending();
        }
      return;
     }
   double day_result=0.0,limit_value=0.0;
   int reached=DailyGuardThresholdReached(day_result,limit_value);
   if(reached==0)
      return;

   string reason=(reached==1 ? StringFormat("DAILY LOSS LOCK  %.2f / -%.2f",day_result,limit_value)
                              : StringFormat("DAILY PROFIT LOCK  +%.2f / %.2f",day_result,limit_value));
   LockDailyGuard(reached);
   int closed=0,deleted=0;
   bool close_positions=(reached==1 ? InpClosePositionsAtDailyLoss : InpClosePositionsAtProfitTarget);
   bool cancel_pending=(reached==1 ? InpCancelPendingAtDailyLoss : InpCancelPendingAtProfitTarget);
   if(close_positions)
      closed=CloseGuardScopePositions();
   if(cancel_pending)
      deleted=CancelGuardScopePending();
   SetStatus(StringFormat("%s  |  closed %d, cancelled %d",reason,closed,deleted),RP_RED,0);
   Print("ArkoRisk Prop Guard: ",reason," | positions closed=",closed," | pending cancelled=",deleted);
  }

bool IsManagedPositionSelected()
  {
   string symbol_name=PositionGetString(POSITION_SYMBOL);
   long magic=PositionGetInteger(POSITION_MAGIC);
   if(symbol_name!=_Symbol)
      return false;
   if(magic==(long)InpMagicNumber)
      return true;
   return(InpManageManualPositions && magic==0);
  }

int ManagedPositionCount(const bool current_symbol_only=true)
  {
   int count=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      long magic=PositionGetInteger(POSITION_MAGIC);
      bool managed=(magic==(long)InpMagicNumber || (InpManageManualPositions && magic==0));
      if(managed && (!current_symbol_only || symbol_name==_Symbol))
         count++;
     }
   return count;
  }

int ManagedPendingCount(const bool current_symbol_only=true)
  {
   int count=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type))
         continue;
      string symbol_name=OrderGetString(ORDER_SYMBOL);
      long magic=OrderGetInteger(ORDER_MAGIC);
      if(magic==(long)InpMagicNumber && (!current_symbol_only || symbol_name==_Symbol))
         count++;
     }
   return count;
  }

double OpenRiskMoney(bool &has_unprotected)
  {
   double total_risk=0.0;
   has_unprotected=false;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      string symbol_name=PositionGetString(POSITION_SYMBOL);
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(!(magic==(long)InpMagicNumber || (InpManageManualPositions && magic==0)))
         continue;
      bool buy_side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double volume=PositionGetDouble(POSITION_VOLUME);
      if(sl<=0.0)
        {
         has_unprotected=true;
         continue;
        }
      if((buy_side && sl>=entry) || (!buy_side && sl<=entry))
         continue;
      double loss=0.0;
      if(ProfitForOneLotSymbol(symbol_name,buy_side,entry,sl,loss))
         total_risk+=MathAbs(loss)*volume;
      else
         has_unprotected=true;
     }

   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type))
         continue;
      string symbol_name=OrderGetString(ORDER_SYMBOL);
      if(OrderGetInteger(ORDER_MAGIC)!=(long)InpMagicNumber)
         continue;
      bool buy_side=IsBuyOrderType(type);
      double entry=OrderGetDouble(ORDER_PRICE_OPEN);
      double sl=OrderGetDouble(ORDER_SL);
      double volume=OrderGetDouble(ORDER_VOLUME_CURRENT);
      if(sl<=0.0)
        {
         has_unprotected=true;
         continue;
        }
      double loss=0.0;
      if(ProfitForOneLotSymbol(symbol_name,buy_side,entry,sl,loss))
         total_risk+=MathAbs(loss)*volume;
      else
         has_unprotected=true;
     }
   return total_risk;
  }

bool CheckBasicTradingGuards(string &reason,const bool ignore_position_limits=false)
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      reason="AutoTrading or account trading is disabled";
      return false;
     }
   ENUM_SYMBOL_TRADE_MODE trade_mode=(ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(trade_mode==SYMBOL_TRADE_MODE_DISABLED || trade_mode==SYMBOL_TRADE_MODE_CLOSEONLY)
     {
      reason="Symbol is not open for new trades";
      return false;
     }

   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0)
     {
      reason="No live quote";
      return false;
     }
   double spread=(tick.ask-tick.bid)/_Point;
   if(InpMaxSpreadPoints>0 && spread>(double)InpMaxSpreadPoints)
     {
      reason=StringFormat("Spread %.0f exceeds limit %d",spread,InpMaxSpreadPoints);
      return false;
     }

   int lock_type=0;
   if(IsDailyGuardLocked(lock_type))
     {
      reason=(lock_type==1 ? "Prop Guard locked trading after daily loss"
                           : "Daily profit target reached; trading locked");
      return false;
     }
   double day_result_check=0.0,guard_limit=0.0;
   int threshold=DailyGuardThresholdReached(day_result_check,guard_limit);
   if(threshold>0)
     {
      reason=(threshold==1 ? "Daily loss threshold reached"
                           : "Daily profit target reached");
      return false;
     }
   string news_reason="";
   if(IsHighImpactNewsWindow(news_reason))
     {
      reason=news_reason;
      return false;
     }

   double realized=0.0,floating=0.0;
   int trades=0;
   GetDailyStats(realized,floating,trades);
   if(InpMaxDailyTrades>0 && trades>=InpMaxDailyTrades)
     {
      reason=StringFormat("Daily trade limit reached (%d)",InpMaxDailyTrades);
      return false;
     }
   if(!ignore_position_limits && InpMaxOpenPositions>0 && ManagedPositionCount(false)>=InpMaxOpenPositions)
     {
      reason=StringFormat("Open-position limit reached (%d)",InpMaxOpenPositions);
      return false;
     }
   if(!ignore_position_limits && InpOnePositionPerSymbol && ManagedPositionCount(true)>0)
     {
      reason="A managed position already exists on this symbol";
      return false;
     }
   return true;
  }

bool CheckDirectionAllowed(const bool buy_side,string &reason)
  {
   ENUM_SYMBOL_TRADE_MODE trade_mode=(ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(buy_side && trade_mode==SYMBOL_TRADE_MODE_SHORTONLY)
     {
      reason="Broker allows short positions only on this symbol";
      return false;
     }
   if(!buy_side && trade_mode==SYMBOL_TRADE_MODE_LONGONLY)
     {
      reason="Broker allows long positions only on this symbol";
      return false;
     }
   return true;
  }

bool HedgeExposureIsInScope(const long magic)
  {
   if(InpHedgeCheckAllAccountTrades)
      return true;
   return(magic==(long)InpMagicNumber || (InpManageManualPositions && magic==0));
  }

bool HasOppositeExposure(const bool intended_buy,string &details,const bool include_positions=true)
  {
   details="";
   if(include_positions)
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || PositionGetString(POSITION_SYMBOL)!=_Symbol ||
            !HedgeExposureIsInScope(PositionGetInteger(POSITION_MAGIC)))
            continue;
         bool position_buy=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
         if(position_buy!=intended_buy)
           {
            details=StringFormat("opposite position #%I64u",ticket);
            return true;
           }
        }
   for(int i=0;i<OrdersTotal();i++)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0 || OrderGetString(ORDER_SYMBOL)!=_Symbol ||
         !HedgeExposureIsInScope(OrderGetInteger(ORDER_MAGIC)))
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type))
         continue;
      if(IsBuyOrderType(type)!=intended_buy)
        {
         details=StringFormat("opposite pending #%I64u",ticket);
         return true;
        }
     }
   return false;
  }

bool ConfirmHedgeIfNeeded(const bool intended_buy,string &reason,const bool include_positions=true)
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      return true;
   if(InpHedgePolicy==RP_HEDGE_ALLOW)
      return true;
   string details="";
   if(!HasOppositeExposure(intended_buy,details,include_positions))
     {
      g_hedge_confirm_side=0;
      g_hedge_confirm_until=0;
      return true;
     }
   if(InpHedgePolicy==RP_HEDGE_BLOCK)
     {
      reason="HEDGE BLOCKED • "+details;
      return false;
     }

   int side=(intended_buy ? 1 : -1);
   datetime now=ServerNow();
   if(g_hedge_confirm_side==side && now<=g_hedge_confirm_until)
     {
      g_hedge_confirm_side=0;
      g_hedge_confirm_until=0;
      return true;
     }
   g_hedge_confirm_side=side;
   int confirm_seconds=(int)MathMax(3,InpHedgeConfirmationSeconds);
   g_hedge_confirm_until=now+confirm_seconds;
   reason=StringFormat("HEDGE WARNING • %s • click again within %ds",details,
                       confirm_seconds);
   return false;
  }

bool CheckOpenRiskGuard(const double new_risk,string &reason)
  {
   if(InpMaxOpenRiskPercent<=0.0)
      return true;
   bool unprotected=false;
   double current=OpenRiskMoney(unprotected);
   if(unprotected && InpBlockForPositionWithoutSL)
     {
      reason="Managed position/order without SL detected";
      return false;
     }
   double allowed=AccountInfoDouble(ACCOUNT_EQUITY)*InpMaxOpenRiskPercent/100.0;
   if(current+new_risk>allowed+0.01)
     {
      reason=StringFormat("Open risk %.2f would exceed %.2f",current+new_risk,allowed);
      return false;
     }
   return true;
  }

bool ValidateMarketStops(const bool buy_side,double &sl,double &tp,string &reason)
  {
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0)
     {
      reason="No live quote";
      return false;
     }
   sl=(buy_side ? NormalizePriceDown(sl) : NormalizePriceUp(sl));
   tp=(buy_side ? NormalizePriceUp(tp) : NormalizePriceDown(tp));
   double min_stop=MarketStopSafetyDistance(tick);
   if(buy_side)
     {
      // Buy SL is checked from Bid while Buy TP is checked from Ask.
      if(sl>tick.bid-min_stop || tp<tick.ask+min_stop)
        {
         reason="SL/TP is too close or on the wrong side";
         return false;
        }
     }
   else
     {
      // Sell SL is checked from Ask while Sell TP is checked from Bid.
      if(sl<tick.ask+min_stop || tp>tick.bid-min_stop)
        {
         reason="SL/TP is too close or on the wrong side";
         return false;
        }
     }
   return true;
  }

bool PrepareMarketStops(const bool buy_side,const MqlTick &tick,double &sl,double &tp,
                        const double safety_multiplier,string &reason)
  {
   if(tick.ask<=0.0 || tick.bid<=0.0)
     {
      reason="No live quote";
      return false;
     }
   double min_stop=MarketStopSafetyDistance(tick,safety_multiplier);
   if(buy_side)
     {
      sl=NormalizePriceDown(MathMin(sl,tick.bid-min_stop));
      tp=NormalizePriceUp(MathMax(tp,tick.ask+min_stop));
     }
   else
     {
      sl=NormalizePriceUp(MathMax(sl,tick.ask+min_stop));
      tp=NormalizePriceDown(MathMin(tp,tick.bid-min_stop));
     }
   return ValidateMarketStops(buy_side,sl,tp,reason);
  }

bool ValidatePendingPrices(const bool buy_side,const double entry,const double sl,const double tp,string &reason)
  {
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick))
     {
      reason="No live quote";
      return false;
     }
   double min_stop=MarketStopSafetyDistance(tick);
   if(buy_side)
     {
      if(entry>tick.ask-min_stop)
        {
         reason="Buy Limit entry must be farther below current Ask";
         return false;
        }
      if(sl>=entry-min_stop || tp<=entry+min_stop)
        {
         reason="Pending SL/TP violates broker minimum distance";
         return false;
        }
     }
   else
     {
      if(entry<tick.bid+min_stop)
        {
         reason="Sell Limit entry must be farther above current Bid";
         return false;
        }
      if(sl<=entry+min_stop || tp>=entry-min_stop)
        {
         reason="Pending SL/TP violates broker minimum distance";
         return false;
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Order execution                                                  |
//+------------------------------------------------------------------+
void DefaultMarketStops(const bool buy_side,const double entry,double &sl,double &tp)
  {
   double distance=DefaultRiskDistance();
   sl=(buy_side ? NormalizePriceDown(entry-distance) : NormalizePriceUp(entry+distance));
   tp=(buy_side ? NormalizePriceUp(entry+distance*g_rr) : NormalizePriceDown(entry-distance*g_rr));

   if(DesignerExists() && g_is_buy==buy_side)
     {
      double line_sl=LinePrice("SL");
      double line_tp=LinePrice("TP");
      if((buy_side && line_sl<entry && line_tp>entry) || (!buy_side && line_sl>entry && line_tp<entry))
        {
         sl=(buy_side ? NormalizePriceDown(line_sl) : NormalizePriceUp(line_sl));
         tp=(buy_side ? NormalizePriceUp(line_tp) : NormalizePriceDown(line_tp));
        }
     }
  }

void PlaceMarketOrder(const bool buy_side)
  {
   string reason="";
   if(!CheckBasicTradingGuards(reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   if(!CheckDirectionAllowed(buy_side,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   if(!ConfirmHedgeIfNeeded(buy_side,reason))
     {
      SetStatus(reason,InpHedgePolicy==RP_HEDGE_BLOCK?RP_RED:RP_AMBER,8);
      return;
     }
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0)
     {
      SetStatus("No live quote",RP_RED,7);
      return;
     }
   double entry=(buy_side ? tick.ask : tick.bid);
   double sl=0.0,tp=0.0;
   DefaultMarketStops(buy_side,entry,sl,tp);
   if(!PrepareMarketStops(buy_side,tick,sl,tp,1.0,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }

   double volume=0.0,risk_money=0.0;
   if(!CalculateVolume(buy_side,entry,sl,volume,risk_money,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   if(!CheckOpenRiskGuard(risk_money,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   bool sent=(buy_side ? trade.Buy(volume,_Symbol,0.0,sl,tp,"ArkoRisk BUY")
                       : trade.Sell(volume,_Symbol,0.0,sl,tp,"ArkoRisk SELL"));
   // Some brokers apply a dynamic stop level that is wider than the published
   // symbol property. Retry once only, with fresh prices and a wider cushion.
   if((!sent || !TradeRetcodeOK()) && trade.ResultRetcode()==TRADE_RETCODE_INVALID_STOPS)
     {
      if(SymbolInfoTick(_Symbol,tick) && tick.ask>0.0 && tick.bid>0.0)
        {
         entry=(buy_side ? tick.ask : tick.bid);
         double retry_distance=MathMax(DefaultRiskDistance(),MarketStopSafetyDistance(tick,2.0));
         sl=(buy_side ? tick.bid-retry_distance : tick.ask+retry_distance);
         tp=(buy_side ? tick.ask+retry_distance*g_rr : tick.bid-retry_distance*g_rr);
         if(PrepareMarketStops(buy_side,tick,sl,tp,2.0,reason) &&
            CalculateVolume(buy_side,entry,sl,volume,risk_money,reason) &&
            CheckOpenRiskGuard(risk_money,reason))
            sent=(buy_side ? trade.Buy(volume,_Symbol,0.0,sl,tp,"ArkoRisk BUY RETRY")
                           : trade.Sell(volume,_Symbol,0.0,sl,tp,"ArkoRisk SELL RETRY"));
         else
            sent=false;
        }
     }
   if(sent && TradeRetcodeOK())
      SetStatus(StringFormat("%s opened | %s lots | risk %s",buy_side?"BUY":"SELL",
                             DoubleToString(volume,VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP))),
                             MoneyText(risk_money)),RP_GREEN,8);
   else
     {
      string rejection=trade.ResultRetcodeDescription();
      if(reason!="")
         rejection=reason+" | "+rejection;
      SetStatus("Order rejected: "+rejection,RP_RED,9);
     }
   UpdatePanel();
  }

void PlaceLimitOrder()
  {
   string reason="";
   if(!CheckBasicTradingGuards(reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   if(!CheckDirectionAllowed(g_is_buy,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   if(!ConfirmHedgeIfNeeded(g_is_buy,reason))
     {
      SetStatus(reason,InpHedgePolicy==RP_HEDGE_BLOCK?RP_RED:RP_AMBER,8);
      return;
     }
   if(InpMaxPendingOrders>0 && ManagedPendingCount(false)>=InpMaxPendingOrders)
     {
      SetStatus(StringFormat("Pending-order limit reached (%d)",InpMaxPendingOrders),RP_RED,7);
      return;
     }
   if(!ValidateDesigner(reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }

   double entry=(g_is_buy ? NormalizePriceDown(LinePrice("ENTRY")) : NormalizePriceUp(LinePrice("ENTRY")));
   double sl=(g_is_buy ? NormalizePriceDown(LinePrice("SL")) : NormalizePriceUp(LinePrice("SL")));
   double tp=(g_is_buy ? NormalizePriceUp(LinePrice("TP")) : NormalizePriceDown(LinePrice("TP")));
   if(!ValidatePendingPrices(g_is_buy,entry,sl,tp,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   double volume=0.0,risk_money=0.0;
   if(!CalculateVolume(g_is_buy,entry,sl,volume,risk_money,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }
   if(!CheckOpenRiskGuard(risk_money,reason))
     {
      SetStatus(reason,RP_RED,7);
      return;
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   bool sent=(g_is_buy ? trade.BuyLimit(volume,entry,_Symbol,sl,tp,ORDER_TIME_GTC,0,"ArkoRisk BuyLimit")
                       : trade.SellLimit(volume,entry,_Symbol,sl,tp,ORDER_TIME_GTC,0,"ArkoRisk SellLimit"));
   if(sent && TradeRetcodeOK())
      SetStatus(StringFormat("%s placed | %s lots | risk %s",g_is_buy?"BUY LIMIT":"SELL LIMIT",
                             DoubleToString(volume,VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP))),
                             MoneyText(risk_money)),RP_GREEN,8);
   else
      SetStatus(StringFormat("Limit rejected: %s",trade.ResultRetcodeDescription()),RP_RED,9);
   UpdatePanel();
  }

//+------------------------------------------------------------------+
//| Position management                                              |
//+------------------------------------------------------------------+
string StateKey(const long identifier,const string suffix)
  {
   return StringFormat("DRP_%I64d_%I64d_%s",AccountInfoInteger(ACCOUNT_LOGIN),identifier,suffix);
  }

double StateGetOrCreate(const string key,const double initial)
  {
   if(GlobalVariableCheck(key))
      return GlobalVariableGet(key);
   GlobalVariableSet(key,initial);
   return initial;
  }

ENUM_ORDER_TYPE_FILLING SymbolFillingMode()
  {
   long filling=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   if((filling & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   ENUM_SYMBOL_TRADE_EXECUTION execution=(ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_EXEMODE);
   if(execution!=SYMBOL_TRADE_EXECUTION_MARKET)
      return ORDER_FILLING_RETURN;
   return ORDER_FILLING_FOK;
  }

bool ClosePositionVolume(const ulong position_ticket,const double requested_volume,string &error_text)
  {
   if(!PositionSelectByTicket(position_ticket))
     {
      error_text="Position no longer exists";
      return false;
     }
   double current_volume=PositionGetDouble(POSITION_VOLUME);
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double close_volume=NormalizeVolumeFloor(MathMin(requested_volume,current_volume),false);
   if(close_volume<=0.0)
     {
      error_text="Partial volume is below broker minimum";
      return false;
     }
   double remainder=NormalizeDouble(current_volume-close_volume,VolumeDigits(step));
   if(remainder>0.0 && remainder<minimum-1e-12)
      close_volume=current_volume;

   ENUM_POSITION_TYPE pos_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   MqlTick tick={};
   SymbolInfoTick(_Symbol,tick);
   MqlTradeRequest request={};
   MqlTradeResult result={};
   request.action=TRADE_ACTION_DEAL;
   request.position=position_ticket;
   request.symbol=_Symbol;
   request.magic=InpMagicNumber;
   request.volume=close_volume;
   request.deviation=InpDeviationPoints;
   request.type=(pos_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
   request.price=(request.type==ORDER_TYPE_BUY ? tick.ask : tick.bid);
   request.type_filling=SymbolFillingMode();
   request.comment="ArkoRisk partial";
   if(!OrderSend(request,result))
     {
      error_text=StringFormat("OrderSend error %d",GetLastError());
      return false;
     }
   if(result.retcode!=TRADE_RETCODE_DONE && result.retcode!=TRADE_RETCODE_DONE_PARTIAL)
     {
      error_text=StringFormat("Broker retcode %u: %s",result.retcode,result.comment);
      return false;
     }
   return true;
  }

void ManageOpenPositions()
  {
   ulong now_ms=GetTickCount64();
   if(now_ms-g_last_manage_ms<200)
      return;
   g_last_manage_ms=now_ms;

   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick))
      return;
   double min_stop=MinimumStopDistance();

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !IsManagedPositionSelected())
         continue;

      bool buy_side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double current_volume=PositionGetDouble(POSITION_VOLUME);
      long identifier=PositionGetInteger(POSITION_IDENTIFIER);
      if(entry<=0.0 || sl<=0.0)
         continue;

      string risk_key=StateKey(identifier,"R");
      string volume_key=StateKey(identifier,"V");
      string partial_key=StateKey(identifier,"P");
      double inferred_risk=MathAbs(entry-sl);
      double initial_risk=StateGetOrCreate(risk_key,inferred_risk);
      double initial_volume=StateGetOrCreate(volume_key,current_volume);
      double partial_done=StateGetOrCreate(partial_key,0.0);
      if(initial_risk<=0.0)
         continue;

      double current_price=(buy_side ? tick.bid : tick.ask);
      double progress=(buy_side ? current_price-entry : entry-current_price);
      double current_r=progress/initial_risk;

      if(InpUsePartialClose && partial_done<0.5 &&
         TriggerReached(InpPartialTriggerMode,current_r,progress,InpPartialCloseAtR,InpPartialCloseAtPips))
        {
         double close_volume=NormalizeVolumeFloor(initial_volume*ClampDouble(InpPartialClosePercent,1.0,99.0)/100.0,false);
         double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
         if(close_volume>0.0 && current_volume-close_volume>=minimum-1e-12)
           {
            string error_text="";
            if(ClosePositionVolume(ticket,close_volume,error_text))
              {
               GlobalVariableSet(partial_key,1.0);
               partial_done=1.0;
               SetStatus("Automatic partial close completed",RP_GREEN,5);
              }
            else
               Print("ArkoRisk partial close failed: ",error_text);
           }
         else
           {
            // Mark as handled when broker volume granularity makes it impossible.
            GlobalVariableSet(partial_key,1.0);
            partial_done=1.0;
           }
        }

      if(!PositionSelectByTicket(ticket))
         continue;
      sl=PositionGetDouble(POSITION_SL);
      tp=PositionGetDouble(POSITION_TP);
      double desired_sl=sl;
      bool should_modify=false;

      if(InpUseBreakEven &&
         TriggerReached(InpBreakEvenTriggerMode,current_r,progress,InpBreakEvenAtR,InpBreakEvenAtPips))
        {
         double be_offset=(InpBreakEvenLockPips>0.0 ? InpBreakEvenLockPips*PipSize()
                                                     : InpBreakEvenPlusPoints*_Point);
         double be=NormalizePrice(buy_side ? entry+be_offset : entry-be_offset);
         bool valid=(buy_side ? be<=tick.bid-min_stop : be>=tick.ask+min_stop);
         bool improves=(buy_side ? (sl==0.0 || be>sl+_Point*0.5) : (sl==0.0 || be<sl-_Point*0.5));
         if(valid && improves)
           {
            desired_sl=be;
            should_modify=true;
           }
        }

      if(InpUseTrailing &&
         TriggerReached(InpTrailingMode,current_r,progress,InpTrailStartAtR,InpTrailStartPips))
        {
         double trail_distance=(InpTrailingMode==RP_TRIGGER_PIPS
                                ? MathMax(0.1,InpTrailDistancePips)*PipSize()
                                : initial_risk*MathMax(0.05,InpTrailDistanceR));
         double candidate=NormalizePrice(buy_side ? tick.bid-trail_distance : tick.ask+trail_distance);
         bool valid=(buy_side ? candidate<=tick.bid-min_stop : candidate>=tick.ask+min_stop);
         double step_distance=(InpTrailingMode==RP_TRIGGER_PIPS
                               ? MathMax(0.1,InpTrailStepPips)*PipSize()
                               : initial_risk*MathMax(0.01,InpTrailStepR));
         bool improves=(buy_side ? candidate>desired_sl+step_distance : candidate<desired_sl-step_distance);
         if(valid && improves)
           {
            desired_sl=candidate;
            should_modify=true;
           }
        }

      if(should_modify)
        {
         trade.SetExpertMagicNumber(InpMagicNumber);
         if(!trade.PositionModify(ticket,desired_sl,tp) || !TradeRetcodeOK())
            Print("ArkoRisk SL modification failed for #",ticket,": ",trade.ResultRetcodeDescription());
        }
     }
  }

void BreakEvenAll()
  {
   MqlTick tick={};
   SymbolInfoTick(_Symbol,tick);
   int changed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !IsManagedPositionSelected())
         continue;
      bool buy_side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double be_offset=(InpBreakEvenLockPips>0.0 ? InpBreakEvenLockPips*PipSize()
                                                  : InpBreakEvenPlusPoints*_Point);
      double new_sl=NormalizePrice(buy_side ? entry+be_offset : entry-be_offset);
      bool valid=(buy_side ? new_sl<tick.bid-MinimumStopDistance() : new_sl>tick.ask+MinimumStopDistance());
      bool improves=(buy_side ? (sl==0.0 || new_sl>sl) : (sl==0.0 || new_sl<sl));
      if(valid && improves && trade.PositionModify(ticket,new_sl,tp) && TradeRetcodeOK())
         changed++;
     }
   SetStatus(StringFormat("Break-even applied to %d position(s)",changed),changed>0?RP_GREEN:RP_AMBER,5);
  }

void CloseHalfAll()
  {
   int changed=0;
   string last_error="";
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !IsManagedPositionSelected())
         continue;
      double volume=PositionGetDouble(POSITION_VOLUME);
      long identifier=PositionGetInteger(POSITION_IDENTIFIER);
      double half=NormalizeVolumeFloor(volume*0.5,false);
      double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
      if(half<=0.0 || volume-half<minimum-1e-12)
        {
         last_error="Volume is too small to close 50%";
         continue;
        }
      if(ClosePositionVolume(ticket,half,last_error))
        {
         GlobalVariableSet(StateKey(identifier,"P"),1.0);
         changed++;
        }
     }
   SetStatus(changed>0 ? StringFormat("Closed 50%% of %d position(s)",changed) : last_error,
             changed>0?RP_GREEN:RP_AMBER,6);
  }

void ClosePositionsByProfit(const bool close_profitable)
  {
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !IsManagedPositionSelected())
         continue;
      double pnl=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
      if((close_profitable && pnl<=0.0) || (!close_profitable && pnl>=0.0))
         continue;
      if(trade.PositionClose(ticket,InpDeviationPoints) && TradeRetcodeOK())
         closed++;
     }
   SetStatus(StringFormat("Closed %d %s position(s)",closed,close_profitable?"profitable":"losing"),
             closed>0?RP_GREEN:RP_AMBER,6);
  }

bool OpenFixedVolumeMarket(const bool buy_side,const double requested_volume,string &reason)
  {
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick))
     {
      reason="No live quote for reverse";
      return false;
     }
   double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(requested_volume>maximum+1e-12)
     {
      reason="Combined reverse volume exceeds broker maximum";
      return false;
     }
   double volume=NormalizeVolumeFloor(requested_volume,true);
   if(volume<=0.0)
     {
      reason="Reverse volume is invalid";
      return false;
     }
   double entry=(buy_side?tick.ask:tick.bid);
   double distance=DefaultRiskDistance()+MinimumStopDistance();
   double sl=(buy_side?tick.bid-distance:tick.ask+distance);
   double tp=(buy_side?tick.ask+distance*g_rr:tick.bid-distance*g_rr);
   if(!PrepareMarketStops(buy_side,tick,sl,tp,1.0,reason))
      return false;
   double loss_one=0.0;
   if(!ProfitForOneLot(buy_side,entry,sl,loss_one))
     {
      reason="Cannot calculate reverse risk";
      return false;
     }
   if(!CheckOpenRiskGuard(MathAbs(loss_one)*volume,reason))
      return false;
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   bool sent=(buy_side ? trade.Buy(volume,_Symbol,0.0,sl,tp,"ArkoRisk REVERSE BUY")
                       : trade.Sell(volume,_Symbol,0.0,sl,tp,"ArkoRisk REVERSE SELL"));
   if(!sent || !TradeRetcodeOK())
     {
      reason="Reverse rejected: "+trade.ResultRetcodeDescription();
      return false;
     }
   return true;
  }

void ReverseManagedPosition()
  {
   string reason="";
   if(!CheckBasicTradingGuards(reason,true))
     {
      SetStatus(reason,RP_RED,8);
      return;
     }
   int count=0;
   int direction=0;
   double total_volume=0.0;
   ulong tickets[];
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !IsManagedPositionSelected())
         continue;
      int side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? 1 : -1);
      if(direction!=0 && side!=direction)
        {
         SetStatus("Reverse refused: mixed BUY and SELL positions",RP_RED,8);
         return;
        }
      direction=side;
      total_volume+=PositionGetDouble(POSITION_VOLUME);
      ArrayResize(tickets,count+1);
      tickets[count++]=ticket;
     }
   if(count==0 || total_volume<=0.0)
     {
      SetStatus("No managed position to reverse",RP_AMBER,6);
      return;
     }
   if(total_volume>SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX)+1e-12)
     {
      SetStatus("Reverse refused: combined volume exceeds broker maximum",RP_RED,8);
      return;
     }
   bool reverse_buy=(direction<0);
   if(!ConfirmHedgeIfNeeded(reverse_buy,reason,false))
     {
      SetStatus(reason,InpHedgePolicy==RP_HEDGE_BLOCK?RP_RED:RP_AMBER,8);
      return;
     }
   int closed=0;
   for(int i=count-1;i>=0;i--)
      if(trade.PositionClose(tickets[i],InpDeviationPoints) && TradeRetcodeOK())
         closed++;
   if(closed!=count)
     {
      SetStatus(StringFormat("Reverse stopped: closed %d of %d positions",closed,count),RP_RED,9);
      return;
     }
   if(OpenFixedVolumeMarket(reverse_buy,total_volume,reason))
      SetStatus(StringFormat("REVERSED to %s • %s lots",reverse_buy?"BUY":"SELL",
                             DoubleToString(total_volume,VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)))),RP_GREEN,8);
   else
      SetStatus(reason,RP_RED,9);
  }

void CloseAllManagedPositions()
  {
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !IsManagedPositionSelected())
         continue;
      if(trade.PositionClose(ticket,InpDeviationPoints) && TradeRetcodeOK())
         closed++;
     }
   SetStatus(StringFormat("Closed %d managed position(s)",closed),closed>0?RP_GREEN:RP_AMBER,6);
  }

void CancelAllPending()
  {
   int deleted=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) || OrderGetString(ORDER_SYMBOL)!=_Symbol || OrderGetInteger(ORDER_MAGIC)!=(long)InpMagicNumber)
         continue;
      if(trade.OrderDelete(ticket) && TradeRetcodeOK())
         deleted++;
     }
   SetStatus(StringFormat("Cancelled %d pending order(s)",deleted),deleted>0?RP_GREEN:RP_AMBER,6);
  }

void CancelStalePending()
  {
   if(InpCancelPendingAfterMinutes<=0)
      return;
   datetime now=ServerNow();
   if(now-g_last_pending_scan<30)
      return;
   g_last_pending_scan=now;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(ticket==0)
         continue;
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(!IsPendingOrderType(type) || OrderGetInteger(ORDER_MAGIC)!=(long)InpMagicNumber)
         continue;
      datetime setup=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(setup>0 && now-setup>=InpCancelPendingAfterMinutes*60)
        {
         if(trade.OrderDelete(ticket) && TradeRetcodeOK())
            Print("ArkoRisk cancelled stale pending #",ticket);
        }
     }
  }

string SafeFileToken(string value)
  {
   StringReplace(value,"/","_");
   StringReplace(value,"\\","_");
   StringReplace(value,":","_");
   StringReplace(value,"*","_");
   StringReplace(value,"?","_");
   StringReplace(value,"\"","_");
   StringReplace(value,"<","_");
   StringReplace(value,">","_");
   StringReplace(value,"|","_");
   return value;
  }

void CaptureEntryScreenshot(const ulong deal_ticket)
  {
   if(!InpTakeEntryScreenshot || deal_ticket==0 || !HistoryDealSelect(deal_ticket))
      return;
   long magic=HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
   ENUM_DEAL_ENTRY entry_type=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
   ENUM_DEAL_TYPE deal_type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
   string symbol_name=HistoryDealGetString(deal_ticket,DEAL_SYMBOL);
   if(magic!=(long)InpMagicNumber || symbol_name!=_Symbol ||
      (entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_INOUT) ||
      (deal_type!=DEAL_TYPE_BUY && deal_type!=DEAL_TYPE_SELL))
      return;

   FolderCreate("ArkoRisk");
   FolderCreate(InpScreenshotFolder);
   datetime deal_time=(datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
   MqlDateTime tm={};
   TimeToStruct(deal_time,tm);
   string side=(deal_type==DEAL_TYPE_BUY ? "BUY" : "SELL");
   string safe_symbol=StringSubstr(SafeFileToken(symbol_name),0,10);
   uint short_ticket=(uint)(deal_ticket%100000);
   string filename=StringFormat("%s\\%04d%02d%02d_%02d%02d%02d_%s_%s_%05u.png",
      InpScreenshotFolder,tm.year,tm.mon,tm.day,tm.hour,tm.min,tm.sec,
      safe_symbol,side,short_ticket);
   if(StringLen(filename)>63)
     {
      Print("ArkoRisk screenshot path exceeds MetaTrader's 63-character limit: ",filename);
      return;
     }
   ChartRedraw();
   int width=MathMax(640,InpScreenshotWidth);
   int height=MathMax(360,InpScreenshotHeight);
   ResetLastError();
   if(ChartScreenShot(0,filename,width,height,ALIGN_RIGHT))
      Print("ArkoRisk journal screenshot saved: MQL5\\Files\\",filename);
   else
      Print("ArkoRisk screenshot failed: ",GetLastError()," | ",filename);
  }

void QueueEntryScreenshot(const ulong deal_ticket)
  {
   if(!InpTakeEntryScreenshot || deal_ticket==0 || !HistoryDealSelect(deal_ticket))
      return;
   long magic=HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
   ENUM_DEAL_ENTRY entry_type=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
   if(magic!=(long)InpMagicNumber ||
      (entry_type!=DEAL_ENTRY_IN && entry_type!=DEAL_ENTRY_INOUT))
      return;
   int size=ArraySize(g_screenshot_queue);
   if(size>=32)
     {
      Print("ArkoRisk screenshot queue is full; skipped deal #",deal_ticket);
      return;
     }
   ArrayResize(g_screenshot_queue,size+1);
   g_screenshot_queue[size]=deal_ticket;
  }

void ProcessScreenshotQueue()
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

//+------------------------------------------------------------------+
//| Panel live data                                                  |
//+------------------------------------------------------------------+
void UpdateNewsTab()
  {
   if(g_active_tab!=RP_TAB_NEWS || g_collapsed)
      return;
   RefreshEconomicNews(false,false);
   const int rows_per_page=RP_NEWS_ROWS;
   int total=FilteredNewsCount();
   int pages=MathMax(1,(total+rows_per_page-1)/rows_per_page);
   g_news_page=MathMax(0,MathMin(pages-1,g_news_page));
   SetLabelText("NEWS_TITLE",StringFormat("FOREX NEWS  •  %s  •  TEHRAN",
                TimeToString(TehranNow(),TIME_DATE)),RP_TEXT);
   SetLabelText("NEWS_PAGE",StringFormat("%d / %d",g_news_page+1,pages),RP_MUTED);
   if(ObjectFind(0,UI("NEWS_FILTER"))>=0)
     {
      SetObjectTextIfChanged(UI("NEWS_FILTER"),g_news_high_only?"HIGH ONLY":"ALL IMPACT");
      SetObjectIntegerIfChanged(UI("NEWS_FILTER"),OBJPROP_BGCOLOR,g_news_high_only?RP_RED_2:RP_CARD);
      SetObjectIntegerIfChanged(UI("NEWS_FILTER"),OBJPROP_BORDER_COLOR,g_news_high_only?RP_RED_2:RP_BORDER);
     }

   datetime now=TehranNow();
   for(int row=0;row<rows_per_page;row++)
     {
      int filtered_index=g_news_page*rows_per_page+row;
      int actual=ActualNewsIndex(filtered_index);
      string bg_name=UI("NEWS_BG_"+IntegerToString(row));
      string time_name="NEWS_TIME_"+IntegerToString(row);
      string cur_name="NEWS_CUR_"+IntegerToString(row);
      string imp_name="NEWS_IMP_"+IntegerToString(row);
      string event_name="NEWS_EVENT_"+IntegerToString(row);
      if(actual<0)
        {
         SetLabelText(time_name,"",RP_MUTED);
         SetLabelText(cur_name,"",RP_MUTED);
         SetLabelText(imp_name,"",RP_MUTED);
         SetLabelText(event_name,(row==0 && total==0)?"No Forex events found today":"",RP_MUTED);
         if(ObjectFind(0,bg_name)>=0)
            SetObjectIntegerIfChanged(bg_name,OBJPROP_BGCOLOR,RP_CARD_2);
         continue;
        }
      ArkoNewsItem item=g_news_items[actual];
      string time_text=NewsTimeText(item);
      string importance=NewsImportanceText(item.importance);
      string title=TruncateText(item.title,24);
      color text_color=NewsImportanceColor(item.importance);
      SetLabelText(time_name,time_text,RP_TEXT);
      SetLabelText(cur_name,item.currency,RP_BLUE);
      SetLabelText(imp_name,importance,text_color);
      SetLabelText(event_name,title,RP_TEXT);
      bool upcoming=(item.tehran_time>=now && item.tehran_time-now<=3600);
      if(ObjectFind(0,bg_name)>=0)
         SetObjectIntegerIfChanged(bg_name,OBJPROP_BGCOLOR,upcoming?C'35,50,68':RP_CARD_2);
     }
   string pause_reason="";
   bool paused=IsHighImpactNewsWindow(pause_reason);
   SetLabelText("NEWS_GUARD_INFO",paused?pause_reason:NextHighImpactNewsText(),paused?RP_RED:RP_MUTED);
  }

string TriggerSummary(const ENUM_RP_TRIGGER_MODE mode,const double at_r,const double at_pips)
  {
   return(mode==RP_TRIGGER_PIPS ? StringFormat("%.1f pips",at_pips) : StringFormat("%.2fR",at_r));
  }

string HedgePolicyText()
  {
   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      return "NETTING";
   if(InpHedgePolicy==RP_HEDGE_BLOCK) return "BLOCK";
   if(InpHedgePolicy==RP_HEDGE_ALLOW) return "ALLOW";
   return "WARN";
  }

void UpdateManageTab()
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
   SetLabelText("HEDGE_STATE","HEDGE  "+HedgePolicyText(),InpHedgePolicy==RP_HEDGE_ALLOW?RP_AMBER:RP_TEXT);
  }

void SetButtonPalette(const string suffix,const color background,const color text_color,const color border)
  {
   string name=UI(suffix);
   SetObjectIntegerIfChanged(name,OBJPROP_BGCOLOR,background);
   SetObjectIntegerIfChanged(name,OBJPROP_COLOR,text_color);
   SetObjectIntegerIfChanged(name,OBJPROP_BORDER_COLOR,border);
  }

void UpdateEntryButtonsState()
  {
   if(g_active_tab!=RP_TAB_TRADE || g_collapsed)
      return;
   string reason="";
   bool enabled=CheckBasicTradingGuards(reason);
   if(enabled)
     {
      SetButtonPalette("BUY_NOW",RP_GREEN,RP_WHITE,RP_GREEN);
      SetButtonPalette("SELL_NOW",RP_RED,RP_WHITE,RP_RED);
      SetButtonPalette("BUY_LIMIT",RP_GREEN_2,RP_WHITE,g_is_buy?RP_WHITE:RP_GREEN_2);
      SetButtonPalette("SELL_LIMIT",RP_RED_2,RP_WHITE,g_is_buy?RP_RED_2:RP_WHITE);
      SetButtonPalette("PLACE",RP_BLUE,RP_BG,RP_BLUE);
     }
   else
     {
      SetButtonPalette("BUY_NOW",RP_CARD,RP_MUTED,RP_BORDER);
      SetButtonPalette("SELL_NOW",RP_CARD,RP_MUTED,RP_BORDER);
      SetButtonPalette("BUY_LIMIT",RP_GREEN_2,RP_WHITE,g_is_buy?RP_WHITE:RP_GREEN_2);
      SetButtonPalette("SELL_LIMIT",RP_RED_2,RP_WHITE,g_is_buy?RP_RED_2:RP_WHITE);
      SetButtonPalette("PLACE",RP_CARD,RP_MUTED,RP_BORDER);
     }
  }

void UpdateChartTab()
  {
   if(g_active_tab!=RP_TAB_CHART || g_collapsed)
      return;
   for(int session=0;session<4;session++)
      SetLabelText("SESSION_INFO_"+IntegerToString(session),
                   StringFormat("%-9s  %s Tehran",SessionName(session),TodaySessionTehranTime(session)),RP_TEXT);
   if(ObjectFind(0,UI("SESSIONS_TOGGLE"))>=0)
     {
      SetObjectTextIfChanged(UI("SESSIONS_TOGGLE"),g_sessions_visible?"SESSIONS ON":"SESSIONS OFF");
      SetObjectIntegerIfChanged(UI("SESSIONS_TOGGLE"),OBJPROP_BGCOLOR,g_sessions_visible?RP_GREEN_2:RP_CARD);
      SetObjectIntegerIfChanged(UI("SESSIONS_TOGGLE"),OBJPROP_BORDER_COLOR,g_sessions_visible?RP_GREEN_2:RP_BORDER);
     }
   if(ObjectFind(0,UI("TIMER_TOGGLE"))>=0)
     {
      SetObjectTextIfChanged(UI("TIMER_TOGGLE"),g_timer_visible?"TIMER ON":"TIMER OFF");
      SetObjectIntegerIfChanged(UI("TIMER_TOGGLE"),OBJPROP_BGCOLOR,g_timer_visible?RP_GREEN_2:RP_CARD);
      SetObjectIntegerIfChanged(UI("TIMER_TOGGLE"),OBJPROP_BORDER_COLOR,g_timer_visible?RP_GREEN_2:RP_BORDER);
     }
   string theme_names[3];
   theme_names[0]=UI("THEME_ORIGINAL");
   theme_names[1]=UI("THEME_DARK");
   theme_names[2]=UI("THEME_LIGHT");
   ENUM_RP_START_THEME themes[3];
   themes[0]=RP_THEME_KEEP;
   themes[1]=RP_THEME_DARK;
   themes[2]=RP_THEME_LIGHT;
   for(int i=0;i<3;i++)
     {
      bool active=(g_chart_theme==themes[i]);
      SetObjectIntegerIfChanged(theme_names[i],OBJPROP_BGCOLOR,active?RP_BLUE:RP_CARD);
      SetObjectIntegerIfChanged(theme_names[i],OBJPROP_BORDER_COLOR,active?RP_BLUE:RP_BORDER);
     }
  }

void SwitchPanelTab(const ENUM_RP_PANEL_TAB tab)
  {
   g_active_tab=tab;
   if(tab==RP_TAB_NEWS)
      RefreshEconomicNews(true,true);
   BuildPanel();
   UpdatePanel();
  }

void ChangeNewsPage(const int direction)
  {
   int pages=MathMax(1,(FilteredNewsCount()+RP_NEWS_ROWS-1)/RP_NEWS_ROWS);
   g_news_page=MathMax(0,MathMin(pages-1,g_news_page+direction));
   UpdateNewsTab();
   ChartRedraw();
  }

void ToggleNewsFilter()
  {
   g_news_high_only=!g_news_high_only;
   JumpNewsToUpcoming();
   UpdateNewsTab();
   ChartRedraw();
  }

void ToggleSessions()
  {
   g_sessions_visible=!g_sessions_visible;
   DrawSessionMarkers(true);
   UpdateChartTab();
   ChartRedraw();
  }

void ToggleCandleTimer()
  {
   g_timer_visible=!g_timer_visible;
   UpdateCandleTimer();
   UpdateChartTab();
   ChartRedraw();
  }

void UpdatePanel()
  {
   if(g_panel_dragging)
      return;
   ProcessScreenshotQueue();
   if(g_status_until>0 && ServerNow()>g_status_until)
     {
      g_status="Ready  •  ArkoRisk protections active";
      g_status_color=RP_MUTED;
      g_status_until=0;
     }
   if(g_collapsed)
     {
      double realized=0.0,floating=0.0;
      int trades=0;
      GetDailyStats(realized,floating,trades);
      SetLabelText("MINI_STATS",StringFormat("Day %+.2f  |  Risk %.2f%s",realized+(InpIncludeFloatingInDailyLoss?floating:0.0),g_risk_value,RiskUnit()),RP_MUTED);
      return;
     }

   if(g_active_tab==RP_TAB_NEWS)
     {
      UpdateNewsTab();
      SetLabelText("STATUS",g_status,g_status_color);
      return;
     }
   if(g_active_tab==RP_TAB_CHART)
     {
      UpdateChartTab();
      SetLabelText("STATUS",g_status,g_status_color);
      return;
     }
   if(g_active_tab==RP_TAB_MANAGE)
     {
      UpdateManageTab();
      SetLabelText("STATUS",g_status,g_status_color);
      return;
     }

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double realized=0.0,floating=0.0;
   int trades=0;
   GetDailyStats(realized,floating,trades);
   double day_result=realized+(InpIncludeFloatingInDailyLoss?floating:0.0);
   MqlTick tick={};
   SymbolInfoTick(_Symbol,tick);
   double spread=(tick.ask>0.0 && tick.bid>0.0 ? (tick.ask-tick.bid)/_Point : 0.0);

   SetLabelText("BALANCE",StringFormat("Balance  %.2f",balance),RP_TEXT);
   SetLabelText("EQUITY",StringFormat("Equity  %.2f",equity),RP_TEXT);
   SetLabelText("DAY_PL",StringFormat("Day P/L  %+.2f  (%d)",day_result,trades),day_result>=0?RP_GREEN:RP_RED);
   SetLabelText("SPREAD",StringFormat("Spread  %.0f pts",spread),(InpMaxSpreadPoints>0 && spread>InpMaxSpreadPoints)?RP_RED:RP_TEXT);
   SetLabelText("RISK_UNIT",RiskUnit(),RP_MUTED);
   if(ObjectFind(0,UI("BUY_LIMIT"))>=0 && ObjectFind(0,UI("SELL_LIMIT"))>=0)
     {
      SetObjectIntegerIfChanged(UI("BUY_LIMIT"),OBJPROP_BORDER_COLOR,g_is_buy?RP_WHITE:RP_GREEN_2);
      SetObjectIntegerIfChanged(UI("SELL_LIMIT"),OBJPROP_BORDER_COLOR,g_is_buy?RP_RED_2:RP_WHITE);
      SetObjectTextIfChanged(UI("PLACE"),g_is_buy?"PLACE BUY LIMIT":"PLACE SELL LIMIT");
     }
   if(ObjectFind(0,UI("RR_LINK"))>=0)
     {
      SetObjectTextIfChanged(UI("RR_LINK"),g_auto_tp_from_rr?"RR LINK":"FREE LINES");
      SetObjectIntegerIfChanged(UI("RR_LINK"),OBJPROP_BGCOLOR,g_auto_tp_from_rr?RP_GREEN_2:RP_CARD);
      SetObjectIntegerIfChanged(UI("RR_LINK"),OBJPROP_BORDER_COLOR,g_auto_tp_from_rr?RP_GREEN_2:RP_BORDER);
     }
   if(ObjectFind(0,UI("LINES_LOCK"))>=0)
     {
      SetObjectTextIfChanged(UI("LINES_LOCK"),g_designer_lines_locked?"UNLOCK":"LINES FREE");
      SetObjectIntegerIfChanged(UI("LINES_LOCK"),OBJPROP_BGCOLOR,g_designer_lines_locked?RP_AMBER:RP_GREEN_2);
      SetObjectIntegerIfChanged(UI("LINES_LOCK"),OBJPROP_BORDER_COLOR,g_designer_lines_locked?RP_AMBER:RP_GREEN_2);
     }

   if(DesignerExists())
     {
      double entry=LinePrice("ENTRY");
      double sl=LinePrice("SL");
      double tp=LinePrice("TP");
      double volume=0.0,risk_money=0.0;
      string reason="";
      if(CalculateVolume(g_is_buy,entry,sl,volume,risk_money,reason))
        {
         double reward_one=0.0;
         ProfitForOneLot(g_is_buy,entry,tp,reward_one);
         double reward_money=MathAbs(reward_one)*volume;
         int vd=VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP));
         SetLabelText("PREVIEW",StringFormat("Lot %s   |   Risk %.2f   |   Target %.2f",
                                             DoubleToString(volume,vd),risk_money,reward_money),RP_BLUE);
         SetLabelText("LEVELS",StringFormat("%s  E %s  /  SL %s  /  TP %s",
                                            g_is_buy?"BUY LIMIT":"SELL LIMIT",PriceText(entry),PriceText(sl),PriceText(tp)),RP_MUTED);
         UpdateTradePreviewLabels();
        }
      else
        {
         DeleteTradePreviewLabels();
         SetLabelText("PREVIEW",reason,RP_AMBER);
         SetLabelText("LEVELS","Drag ENTRY / STOP / TARGET lines",RP_MUTED);
        }
     }
   else
     {
      DeleteTradePreviewLabels();
      SetLabelText("PREVIEW","Create a Limit setup to preview lot size",RP_MUTED);
      SetLabelText("LEVELS","Designer lines are hidden",RP_MUTED);
     }

   UpdateEntryButtonsState();
   SetLabelText("STATUS",g_status,g_status_color);
  }

double RiskIncrement()
  {
   if(InpRiskMode==RP_FIXED_LOT)
      return MathMax(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP),0.01);
   if(InpRiskMode==RP_FIXED_MONEY)
      return 1.0;
   return 0.10;
  }

void ChangeRisk(const int direction)
  {
   double step=RiskIncrement();
   double maximum=(InpRiskMode==RP_FIXED_LOT ? SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX) :
                   (InpRiskMode==RP_FIXED_MONEY ? 100000000.0 : 50.0));
   g_risk_value=ClampDouble(g_risk_value+direction*step,step,maximum);
   int digits=(InpRiskMode==RP_FIXED_LOT ? VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)) : 2);
   if(ObjectFind(0,UI("RISK_EDIT"))>=0)
      ObjectSetString(0,UI("RISK_EDIT"),OBJPROP_TEXT,DoubleToString(g_risk_value,digits));
   UpdatePanel();
  }

void ChangeRR(const int direction)
  {
   g_rr=ClampDouble(g_rr+direction*0.25,0.10,20.0);
   if(ObjectFind(0,UI("RR_EDIT"))>=0)
      ObjectSetString(0,UI("RR_EDIT"),OBJPROP_TEXT,DoubleToString(g_rr,2));
   if(g_auto_tp_from_rr)
      UpdateTargetFromRR();
   UpdatePanel();
  }

void ReadEditValue(const string object_name)
  {
   string value=ObjectGetString(0,object_name,OBJPROP_TEXT);
   double parsed=StringToDouble(value);
   if(object_name==UI("RISK_EDIT"))
     {
      double maximum=(InpRiskMode==RP_FIXED_LOT ? SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX) :
                      (InpRiskMode==RP_FIXED_MONEY ? 100000000.0 : 50.0));
      if(parsed>0.0)
         g_risk_value=ClampDouble(parsed,RiskIncrement(),maximum);
      int digits=(InpRiskMode==RP_FIXED_LOT ? VolumeDigits(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)) : 2);
      ObjectSetString(0,object_name,OBJPROP_TEXT,DoubleToString(g_risk_value,digits));
     }
   else if(object_name==UI("RR_EDIT"))
     {
      if(parsed>0.0)
         g_rr=ClampDouble(parsed,0.10,20.0);
      ObjectSetString(0,object_name,OBJPROP_TEXT,DoubleToString(g_rr,2));
      if(g_auto_tp_from_rr)
         UpdateTargetFromRR();
     }
   UpdatePanel();
  }

//+------------------------------------------------------------------+
//| Standard event handlers                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpDefaultRR<=0.0 || InpDefaultSL_ATR<=0.0 || InpATRPeriod<2)
     {
      Print("ArkoRisk: invalid input parameters");
      return INIT_PARAMETERS_INCORRECT;
     }

   g_prefix=StringFormat("ARKO_%I64d_",ChartID());
   g_ui_prefix=g_prefix+"UI_";
   g_line_prefix=g_prefix+"LINE_";
   g_timer_name=g_prefix+"CANDLE_TIMER";
   g_session_prefix=g_prefix+"SESSION_";
   g_collapsed=InpStartCollapsed;
   g_auto_tp_from_rr=InpAutoTPFromRR;
   g_designer_lines_locked=InpLockDesignerLinesOnStart;
   g_sessions_visible=InpShowForexSessions;
   g_timer_visible=InpShowCandleCloseTimer;
   g_rr=ClampDouble(InpDefaultRR,0.10,20.0);
   if(InpRiskMode==RP_FIXED_MONEY)
      g_risk_value=MathMax(0.01,InpFixedRiskMoney);
   else if(InpRiskMode==RP_FIXED_LOT)
      g_risk_value=MathMax(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),InpFixedLot);
   else
      g_risk_value=ClampDouble(InpDefaultRiskPercent,0.01,50.0);

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetMarginMode();
   trade.SetAsyncMode(false);

   long previous_mouse_events=0;
   long previous_mouse_scroll=1;
   ChartGetInteger(0,CHART_EVENT_MOUSE_MOVE,0,previous_mouse_events);
   ChartGetInteger(0,CHART_MOUSE_SCROLL,0,previous_mouse_scroll);
   g_previous_mouse_events=(previous_mouse_events!=0);
   g_previous_mouse_scroll=(previous_mouse_scroll!=0);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);

   CaptureOriginalChartTheme();
   if(InpChartThemeOnStart!=RP_THEME_KEEP)
      ApplyChartTheme(InpChartThemeOnStart);

   BuildPanel();
   if(InpShowDesignerOnStart)
      ResetDesigner(true);
   if(InpTakeEntryScreenshot)
     {
      FolderCreate("ArkoRisk");
      FolderCreate(InpScreenshotFolder);
     }
   DrawSessionMarkers(true);
   EventSetTimer(1);
   UpdateCandleTimer();
   SetStatus("ArkoRisk ready  •  Demo test recommended",RP_BLUE,6);
   UpdatePanel();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   SavePanelPosition();
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,g_previous_mouse_events);
   ChartSetInteger(0,CHART_MOUSE_SCROLL,g_previous_mouse_scroll);
   DeleteUI();
   DeleteDesignerLines();
   DeleteCandleTimer();
   DeleteSessionMarkers();
   if(InpRestoreChartThemeOnRemove)
      RestoreOriginalChartTheme();
   ChartRedraw();
  }

void OnTick()
  {
   ManageOpenPositions();
  }

void OnTimer()
  {
   EnforceDailyGuard();
   if(InpUseNewsAutoPause)
      RefreshEconomicNews(false,false);
   if(g_panel_dragging && GetTickCount64()-g_last_panel_drag_event_ms>2000)
      FinishPanelDrag(true);
   if(g_panel_dragging)
      return;
   CancelStalePending();
   UpdateCandleTimer();
   DrawSessionMarkers(false);
   UpdatePanel();
   ChartRedraw();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   g_daily_stats_cache_time=0;
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD && trans.deal>0)
      QueueEntryScreenshot(trans.deal);
   if(!g_panel_dragging)
      UpdatePanel();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      int mouse_x=(int)lparam;
      int mouse_y=(int)dparam;
      long mouse_flags=StringToInteger(sparam);
      bool left_button=((mouse_flags & 1)==1);
      if(left_button)
        {
         if(!g_panel_dragging && PointIsInPanelHeader(mouse_x,mouse_y))
           {
            g_panel_dragging=true;
            g_last_panel_drag_event_ms=GetTickCount64();
            g_panel_drag_offset_x=mouse_x-g_panel_x;
            g_panel_drag_offset_y=mouse_y-g_panel_y;
            ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
            SetDesignerLinesInteraction(false,false);
           }
         if(g_panel_dragging)
           {
            g_last_panel_drag_event_ms=GetTickCount64();
            MovePanelObjects(mouse_x-g_panel_drag_offset_x,mouse_y-g_panel_drag_offset_y);
           }
        }
      else if(g_panel_dragging)
        {
         FinishPanelDrag(true);
         SetStatus("Panel position saved",RP_BLUE,3);
         ChartRedraw();
        }
      return;
     }

   // A click event is also a reliable mouse-release signal. It prevents a
   // missed release outside the panel from leaving chart lines disabled.
   if(g_panel_dragging)
      FinishPanelDrag(true);

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(IsDesignerLine(sparam))
        {
         if(!g_designer_lines_locked)
           {
            ObjectSetInteger(0,sparam,OBJPROP_SELECTABLE,true);
            ObjectSetInteger(0,sparam,OBJPROP_SELECTED,true);
            SetStatus("Line selected — drag it to the desired price",RP_BLUE,3);
           }
         return;
        }
      ReleaseButton(sparam);
      if(sparam==UI("COLLAPSE"))
        {
         g_collapsed=!g_collapsed;
         BuildPanel();
         UpdatePanel();
         return;
        }
      if(sparam==UI("TAB_TRADE")) SwitchPanelTab(RP_TAB_TRADE);
      else if(sparam==UI("TAB_MANAGE")) SwitchPanelTab(RP_TAB_MANAGE);
      else if(sparam==UI("TAB_NEWS")) SwitchPanelTab(RP_TAB_NEWS);
      else if(sparam==UI("TAB_CHART")) SwitchPanelTab(RP_TAB_CHART);
      else if(sparam==UI("NEWS_REFRESH"))
        {
         RefreshEconomicNews(true,true);
         UpdateNewsTab();
        }
      else if(sparam==UI("NEWS_FILTER")) ToggleNewsFilter();
      else if(sparam==UI("NEWS_PREV")) ChangeNewsPage(-1);
      else if(sparam==UI("NEWS_NEXT")) ChangeNewsPage(+1);
      else if(sparam==UI("THEME_DARK"))
        {
         ApplyChartTheme(RP_THEME_DARK);
         UpdateChartTab();
        }
      else if(sparam==UI("THEME_LIGHT"))
        {
         ApplyChartTheme(RP_THEME_LIGHT);
         UpdateChartTab();
        }
      else if(sparam==UI("THEME_ORIGINAL"))
        {
         RestoreOriginalChartTheme();
         UpdateChartTab();
        }
      else if(sparam==UI("SESSIONS_TOGGLE")) ToggleSessions();
      else if(sparam==UI("SESSIONS_REDRAW")) DrawSessionMarkers(true);
      else if(sparam==UI("TIMER_TOGGLE")) ToggleCandleTimer();
      else if(sparam==UI("RISK_MINUS")) ChangeRisk(-1);
      else if(sparam==UI("RISK_PLUS")) ChangeRisk(+1);
      else if(sparam==UI("RR_MINUS")) ChangeRR(-1);
      else if(sparam==UI("RR_PLUS")) ChangeRR(+1);
      else if(sparam==UI("BUY_NOW")) PlaceMarketOrder(true);
      else if(sparam==UI("SELL_NOW")) PlaceMarketOrder(false);
      else if(sparam==UI("BUY_LIMIT")) ResetDesigner(true);
      else if(sparam==UI("SELL_LIMIT")) ResetDesigner(false);
      else if(sparam==UI("PLACE")) PlaceLimitOrder();
      else if(sparam==UI("RESET")) ResetDesigner(g_is_buy);
      else if(sparam==UI("LINES_LOCK")) ToggleDesignerLinesLock();
      else if(sparam==UI("DELETE_LINES")) RemoveDesignerLines();
      else if(sparam==UI("RR_LINK")) ToggleRRLink();
      else if(sparam==UI("BE_ALL")) BreakEvenAll();
      else if(sparam==UI("HALF_ALL")) CloseHalfAll();
      else if(sparam==UI("CLOSE_PROFIT")) ClosePositionsByProfit(true);
      else if(sparam==UI("CLOSE_LOSS")) ClosePositionsByProfit(false);
      else if(sparam==UI("REVERSE")) ReverseManagedPosition();
      else if(sparam==UI("CLOSE_ALL")) CloseAllManagedPositions();
      else if(sparam==UI("CANCEL_PENDING")) CancelAllPending();
      ChartRedraw();
      return;
     }

   if(id==CHARTEVENT_OBJECT_DRAG && IsDesignerLine(sparam))
     {
      SyncDesignerAfterDrag(sparam);
      if(!g_designer_lines_locked)
         ObjectSetInteger(0,sparam,OBJPROP_SELECTED,true);
      return;
     }

   if(id==CHARTEVENT_OBJECT_ENDEDIT && (sparam==UI("RISK_EDIT") || sparam==UI("RR_EDIT")))
     {
      ReadEditValue(sparam);
      return;
     }

   if(id==CHARTEVENT_CHART_CHANGE)
     {
      if(g_panel_dragging)
         return;
      int old_x=g_panel_x;
      int old_y=g_panel_y;
      ClampPanelPosition();
      int delta_x=g_panel_x-old_x;
      int delta_y=g_panel_y-old_y;
      if(delta_x!=0 || delta_y!=0)
        {
         for(int i=0;i<ArraySize(g_ui_objects);i++)
           {
            string name=g_ui_objects[i];
            if(ObjectFind(0,name)<0)
               continue;
            ObjectSetInteger(0,name,OBJPROP_XDISTANCE,ObjectGetInteger(0,name,OBJPROP_XDISTANCE)+delta_x);
            ObjectSetInteger(0,name,OBJPROP_YDISTANCE,ObjectGetInteger(0,name,OBJPROP_YDISTANCE)+delta_y);
           }
        }
      UpdateCandleTimer();
      UpdateTradePreviewLabels();
      UpdatePanel();
      return;
     }

   if(id==CHARTEVENT_KEYDOWN && InpEnableHotkeys)
     {
      int key=(int)lparam;
      if(key==66) PlaceMarketOrder(true);       // B
      else if(key==83) PlaceMarketOrder(false);// S
      else if(key==49) ResetDesigner(true);    // 1
      else if(key==50) ResetDesigner(false);   // 2
      else if(key==13) PlaceLimitOrder();      // Enter
     }
  }
