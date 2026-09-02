#property copyright "Shayan Namayandeh (SudoShayanNA) — ArkoRisk"
#property link      "https://github.com/roseshayan/ArkoRisk"
#property version   "1.50"
#property strict
#property description "ArkoRisk MT4 — risk manager with runtime controls, smart break-even, Tehran guard and journal"

//+------------------------------------------------------------------+
//| ArkoRisk MT4 v1.50                                               |
//|                                                                  |
//| MT4 has no built-in Economic Calendar equivalent to MT5.         |
//| News Guard therefore reads an optional local CSV in Tehran time. |
//| This is intentional: calendar parity is not faked.               |
//+------------------------------------------------------------------+

enum ARKO4_RISK_MODE
  {
   ARKO4_BALANCE_PERCENT=0,
   ARKO4_EQUITY_PERCENT=1,
   ARKO4_FIXED_MONEY=2,
   ARKO4_FIXED_LOT=3
  };

enum ARKO4_TRIGGER_MODE
  {
   ARKO4_TRIGGER_R=0,
   ARKO4_TRIGGER_PIPS=1
  };

enum ARKO4_HEDGE_POLICY
  {
   ARKO4_HEDGE_WARN=0,
   ARKO4_HEDGE_BLOCK=1,
   ARKO4_HEDGE_ALLOW=2
  };

enum ARKO4_DAILY_SCOPE
  {
   ARKO4_SCOPE_EA_SYMBOL=0,
   ARKO4_SCOPE_EA_ALL=1,
   ARKO4_SCOPE_ACCOUNT=2
  };

enum ARKO4_GUARD_MODE
  {
   ARKO4_GUARD_PERCENT=0,
   ARKO4_GUARD_MONEY=1
  };

enum ARKO4_TAB
  {
   ARKO4_TAB_TRADE=0,
   ARKO4_TAB_MANAGE=1,
   ARKO4_TAB_JOURNAL=2,
   ARKO4_TAB_CHART=3
  };

//--- Core/risk
input int                 InpMagicNumber                    = 260803;
input ARKO4_RISK_MODE     InpRiskMode                       = ARKO4_EQUITY_PERCENT;
input double              InpDefaultRisk                    = 0.50;
input double              InpDefaultRR                      = 2.00;
input double              InpFixedRiskMoney                 = 10.0;
input double              InpFixedLot                       = 0.01;
input int                 InpATRPeriod                      = 14;
input double              InpDefaultSL_ATR                  = 0.80;
input int                 InpMinimumSLPoints                = 20;
input int                 InpMaxSpreadPoints                = 0;
input int                 InpSlippagePoints                 = 20;
input double              InpMaxOpenRiskPercent             = 2.0;
input bool                InpBlockForTradeWithoutSL         = true;

//--- Defaults copied into mutable runtime panel state
input bool                InpManageManualTrades             = false;
input bool                InpUseBreakEven                   = true;
input ARKO4_TRIGGER_MODE  InpBreakEvenMode                  = ARKO4_TRIGGER_R;
input double              InpBreakEvenAtR                   = 1.0;
input double              InpBreakEvenAtPips                = 10.0;
input double              InpBreakEvenLockPips              = 0.0;
input bool                InpUsePartialClose                = true;
input ARKO4_TRIGGER_MODE  InpPartialMode                    = ARKO4_TRIGGER_R;
input double              InpPartialAtR                     = 1.0;
input double              InpPartialAtPips                  = 10.0;
input double              InpPartialPercent                 = 50.0;
input bool                InpUseTrailing                    = false;
input ARKO4_TRIGGER_MODE  InpTrailingMode                   = ARKO4_TRIGGER_PIPS;
input double              InpTrailStartR                    = 1.5;
input double              InpTrailStartPips                 = 15.0;
input double              InpTrailDistanceR                 = 0.5;
input double              InpTrailDistancePips              = 8.0;
input double              InpTrailStepR                     = 0.1;
input double              InpTrailStepPips                  = 2.0;

//--- Smart break-even costs
input bool                InpBreakEvenCoverLiveSpread       = true;
input bool                InpBreakEvenCoverCommission       = true;
input double              InpCommissionPerLotRoundTurn      = 0.0; // account currency per 1 lot; 0 = estimate from history
input double              InpBreakEvenExtraBufferPips       = 0.20;

//--- Daily/overtrading guard
input ARKO4_DAILY_SCOPE   InpDailyScope                     = ARKO4_SCOPE_EA_ALL;
input bool                InpUseDailyLossGuard              = true;
input ARKO4_GUARD_MODE    InpDailyLossMode                  = ARKO4_GUARD_PERCENT;
input double              InpDailyLossPercent               = 3.0;
input double              InpDailyLossMoney                 = 100.0;
input bool                InpCloseAtDailyLoss               = true;
input bool                InpCancelPendingAtDailyLoss       = true;
input bool                InpUseDailyProfitTarget           = false;
input ARKO4_GUARD_MODE    InpDailyProfitMode                = ARKO4_GUARD_PERCENT;
input double              InpDailyProfitPercent             = 2.0;
input double              InpDailyProfitMoney               = 100.0;
input bool                InpCloseAtDailyProfit             = false;
input bool                InpCancelPendingAtDailyProfit     = true;
input bool                InpIncludeFloatingInDailyGuard    = true;
input int                 InpMaxDailyTrades                 = 20;
input int                 InpMaxOpenPositions               = 5;
input int                 InpMaxPendingOrders               = 10;
input bool                InpOnePositionPerSymbol           = false;
input int                 InpCancelPendingAfterMinutes      = 30;

//--- News: local CSV, Tehran wall-clock time
input bool                InpUseNewsGuard                   = true;
input string              InpNewsCsvFile                    = "ArkoRisk\\news.csv";
input int                 InpNewsBeforeMinutes              = 15;
input int                 InpNewsAfterMinutes               = 15;
input bool                InpNewsCurrentSymbolOnly          = true;
input bool                InpBlockIfNewsFileMissing         = false;

//--- Hedge
input ARKO4_HEDGE_POLICY  InpHedgePolicy                    = ARKO4_HEDGE_WARN;
input bool                InpHedgeCheckAllAccountTrades     = true;
input int                 InpHedgeConfirmationSeconds       = 6;

//--- Journal
input bool                InpTakeEntryScreenshot            = true;
input string              InpScreenshotFolder               = "ArkoRisk\\Journal";
input int                 InpScreenshotWidth                = 1920;
input int                 InpScreenshotHeight               = 1080;

//--- Tehran/chart
input int                 InpTehranUTCOffsetMinutes         = 210;
input bool                InpShowTehranDays                 = true;
input bool                InpShowForexSessions              = true;
input int                 InpMarkerLookbackDays             = 5;
input bool                InpShowCandleTimer                = true;
input color               InpTokyoColor                     = C'56,189,248';
input color               InpLondonColor                    = C'52,211,153';
input color               InpNewYorkColor                   = C'251,146,60';
input color               InpSydneyColor                    = C'192,132,252';

//--- Panel
input bool                InpRememberRuntimeControls        = true;
input int                 InpPanelX                         = 12;
input int                 InpPanelY                         = 18;
input string              InpPanelFont                      = "Arial";

#define A4_BG       C'15,23,42'
#define A4_CARD     C'30,41,59'
#define A4_CARD2    C'24,33,48'
#define A4_BORDER   C'51,65,85'
#define A4_TEXT     C'241,245,249'
#define A4_MUTED    C'148,163,184'
#define A4_BLUE     C'56,189,248'
#define A4_GREEN    C'16,185,129'
#define A4_GREEN2   C'5,120,87'
#define A4_RED      C'244,63,94'
#define A4_RED2     C'159,18,57'
#define A4_AMBER    C'245,158,11'
#define A4_WHITE    C'255,255,255'

string g_prefix="";
string g_ui="";
string g_line="";
string g_day="";
string g_session="";
string g_timer="";
ARKO4_TAB g_tab=ARKO4_TAB_TRADE;
bool g_buy_side=true;
double g_risk=0.50;
double g_rr=2.0;
string g_status="Ready";
color g_status_color=A4_MUTED;
datetime g_status_until=0;
datetime g_last_tehran_day=0;
datetime g_last_stale_scan=0;
uint g_last_manage_ms=0;
int g_hedge_confirm_side=0;
datetime g_hedge_confirm_until=0;

// mutable runtime state
bool g_manual=false;
bool g_be=true;
bool g_partial=true;
bool g_trailing=false;
bool g_news=true;
bool g_overtrade=true;
ARKO4_HEDGE_POLICY g_hedge=ARKO4_HEDGE_WARN;
ARKO4_TRIGGER_MODE g_be_mode=ARKO4_TRIGGER_R;
ARKO4_TRIGGER_MODE g_part_mode=ARKO4_TRIGGER_R;
ARKO4_TRIGGER_MODE g_trail_mode=ARKO4_TRIGGER_PIPS;
double g_be_r=1.0,g_be_pips=10.0,g_be_lock=0.0;
double g_part_r=1.0,g_part_pips=10.0,g_part_pct=50.0;
double g_trail_start_r=1.5,g_trail_start_pips=15.0;
double g_trail_dist_r=0.5,g_trail_dist_pips=8.0;
double g_trail_step_r=0.1,g_trail_step_pips=2.0;
int g_news_before=15,g_news_after=15;
int g_max_trades=20,g_max_positions=5,g_max_pending=10;

string UI(string s) { return g_ui+s; }
string LN(string s) { return g_line+s; }

double Clamp(double v,double lo,double hi) { return MathMax(lo,MathMin(hi,v)); }

double PipSize()
  {
   return((Digits==3 || Digits==5)?Point*10.0:Point);
  }

double TickSize()
  {
   double v=MarketInfo(Symbol(),MODE_TICKSIZE);
   if(v<=0.0) v=Point;
   return v;
  }

int LotDigits()
  {
   double step=MarketInfo(Symbol(),MODE_LOTSTEP); int d=0;
   while(d<8 && MathAbs(step-MathRound(step))>1e-9) { step*=10.0; d++; }
   return d;
  }

double NormalizeLotFloor(double lots,bool allow_minimum=false)
  {
   double minimum=MarketInfo(Symbol(),MODE_MINLOT);
   double maximum=MarketInfo(Symbol(),MODE_MAXLOT);
   double step=MarketInfo(Symbol(),MODE_LOTSTEP);
   if(minimum<=0.0 || maximum<=0.0 || step<=0.0) return 0.0;
   if(lots<minimum-1e-12) return allow_minimum?NormalizeDouble(minimum,LotDigits()):0.0;
   lots=MathFloor((lots+1e-12)/step)*step;
   lots=MathMax(minimum,MathMin(maximum,lots));
   return NormalizeDouble(lots,LotDigits());
  }

double NormalizePrice(double p) { return NormalizeDouble(MathRound(p/TickSize())*TickSize(),Digits); }
double NormalizePriceDown(double p) { return NormalizeDouble(MathFloor(p/TickSize()+1e-10)*TickSize(),Digits); }
double NormalizePriceUp(double p) { return NormalizeDouble(MathCeil(p/TickSize()-1e-10)*TickSize(),Digits); }

datetime TehranNow() { return (datetime)((long)TimeGMT()+InpTehranUTCOffsetMinutes*60); }
long ServerUTCOffsetSeconds() { return (long)TimeCurrent()-(long)TimeGMT(); }

datetime TehranDayStart()
  {
   MqlDateTime tm; TimeToStruct(TehranNow(),tm); tm.hour=0; tm.min=0; tm.sec=0; return StructToTime(tm);
  }

void TehranDayServerBounds(datetime &from,datetime &to)
  {
   datetime local=TehranDayStart();
   datetime utc=(datetime)((long)local-InpTehranUTCOffsetMinutes*60);
   from=(datetime)((long)utc+ServerUTCOffsetSeconds());
   to=from+86400;
  }

string WeekdayName(int d)
  {
   if(d==0) return "SUNDAY"; if(d==1) return "MONDAY"; if(d==2) return "TUESDAY";
   if(d==3) return "WEDNESDAY"; if(d==4) return "THURSDAY"; if(d==5) return "FRIDAY"; return "SATURDAY";
  }

string SafeToken(string s)
  {
   StringReplace(s,"/","_"); StringReplace(s,"\\","_"); StringReplace(s,":","_");
   StringReplace(s,"*","_"); StringReplace(s,"?","_"); StringReplace(s,"\"","_");
   StringReplace(s,"<","_"); StringReplace(s,">","_"); StringReplace(s,"|","_");
   return s;
  }

void SetStatus(string s,color c=A4_MUTED,int seconds=5)
  {
   g_status=s; g_status_color=c; g_status_until=(seconds>0?TimeCurrent()+seconds:0);
   if(ObjectFind(0,UI("STATUS"))>=0) { ObjectSetString(0,UI("STATUS"),OBJPROP_TEXT,s); ObjectSetInteger(0,UI("STATUS"),OBJPROP_COLOR,c); }
  }

//+------------------------------------------------------------------+
//| Runtime state                                                    |
//+------------------------------------------------------------------+
string StateKey(string suffix)
  {
   return StringFormat("ARKO4_%d_%d_%s",AccountNumber(),InpMagicNumber,suffix);
  }

double ReadState(string suffix,double fallback)
  {
   string k=StateKey(suffix); return GlobalVariableCheck(k)?GlobalVariableGet(k):fallback;
  }

void SaveRuntime()
  {
   if(!InpRememberRuntimeControls) return;
   GlobalVariableSet(StateKey("MAN"),g_manual?1:0); GlobalVariableSet(StateKey("BE"),g_be?1:0);
   GlobalVariableSet(StateKey("PART"),g_partial?1:0); GlobalVariableSet(StateKey("TRAIL"),g_trailing?1:0);
   GlobalVariableSet(StateKey("NEWS"),g_news?1:0); GlobalVariableSet(StateKey("OVER"),g_overtrade?1:0);
   GlobalVariableSet(StateKey("HEDGE"),(double)g_hedge); GlobalVariableSet(StateKey("BEMODE"),(double)g_be_mode);
   GlobalVariableSet(StateKey("BER"),g_be_r); GlobalVariableSet(StateKey("BEP"),g_be_pips); GlobalVariableSet(StateKey("BEL"),g_be_lock);
   GlobalVariableSet(StateKey("PMODE"),(double)g_part_mode); GlobalVariableSet(StateKey("PR"),g_part_r);
   GlobalVariableSet(StateKey("PP"),g_part_pips); GlobalVariableSet(StateKey("PCT"),g_part_pct);
   GlobalVariableSet(StateKey("TMODE"),(double)g_trail_mode); GlobalVariableSet(StateKey("TSR"),g_trail_start_r);
   GlobalVariableSet(StateKey("TSP"),g_trail_start_pips); GlobalVariableSet(StateKey("TDR"),g_trail_dist_r);
   GlobalVariableSet(StateKey("TDP"),g_trail_dist_pips); GlobalVariableSet(StateKey("TSTR"),g_trail_step_r);
   GlobalVariableSet(StateKey("TSTP"),g_trail_step_pips); GlobalVariableSet(StateKey("NB"),g_news_before);
   GlobalVariableSet(StateKey("NA"),g_news_after); GlobalVariableSet(StateKey("MAXT"),g_max_trades);
   GlobalVariableSet(StateKey("MAXP"),g_max_positions); GlobalVariableSet(StateKey("MAXO"),g_max_pending);
  }

void InitRuntime()
  {
   g_manual=InpManageManualTrades; g_be=InpUseBreakEven; g_partial=InpUsePartialClose; g_trailing=InpUseTrailing;
   g_news=InpUseNewsGuard; g_hedge=InpHedgePolicy; g_be_mode=InpBreakEvenMode; g_be_r=InpBreakEvenAtR;
   g_be_pips=InpBreakEvenAtPips; g_be_lock=InpBreakEvenLockPips; g_part_mode=InpPartialMode;
   g_part_r=InpPartialAtR; g_part_pips=InpPartialAtPips; g_part_pct=InpPartialPercent;
   g_trail_mode=InpTrailingMode; g_trail_start_r=InpTrailStartR; g_trail_start_pips=InpTrailStartPips;
   g_trail_dist_r=InpTrailDistanceR; g_trail_dist_pips=InpTrailDistancePips; g_trail_step_r=InpTrailStepR;
   g_trail_step_pips=InpTrailStepPips; g_news_before=InpNewsBeforeMinutes; g_news_after=InpNewsAfterMinutes;
   g_max_trades=InpMaxDailyTrades; g_max_positions=InpMaxOpenPositions; g_max_pending=InpMaxPendingOrders;
   if(!InpRememberRuntimeControls) return;
   g_manual=ReadState("MAN",g_manual?1:0)>0.5; g_be=ReadState("BE",g_be?1:0)>0.5;
   g_partial=ReadState("PART",g_partial?1:0)>0.5; g_trailing=ReadState("TRAIL",g_trailing?1:0)>0.5;
   g_news=ReadState("NEWS",g_news?1:0)>0.5; g_overtrade=ReadState("OVER",1)>0.5;
   g_hedge=(ARKO4_HEDGE_POLICY)(int)ReadState("HEDGE",g_hedge); g_be_mode=(ARKO4_TRIGGER_MODE)(int)ReadState("BEMODE",g_be_mode);
   g_be_r=ReadState("BER",g_be_r); g_be_pips=ReadState("BEP",g_be_pips); g_be_lock=ReadState("BEL",g_be_lock);
   g_part_mode=(ARKO4_TRIGGER_MODE)(int)ReadState("PMODE",g_part_mode); g_part_r=ReadState("PR",g_part_r);
   g_part_pips=ReadState("PP",g_part_pips); g_part_pct=ReadState("PCT",g_part_pct);
   g_trail_mode=(ARKO4_TRIGGER_MODE)(int)ReadState("TMODE",g_trail_mode); g_trail_start_r=ReadState("TSR",g_trail_start_r);
   g_trail_start_pips=ReadState("TSP",g_trail_start_pips); g_trail_dist_r=ReadState("TDR",g_trail_dist_r);
   g_trail_dist_pips=ReadState("TDP",g_trail_dist_pips); g_trail_step_r=ReadState("TSTR",g_trail_step_r);
   g_trail_step_pips=ReadState("TSTP",g_trail_step_pips); g_news_before=(int)ReadState("NB",g_news_before);
   g_news_after=(int)ReadState("NA",g_news_after); g_max_trades=(int)ReadState("MAXT",g_max_trades);
   g_max_positions=(int)ReadState("MAXP",g_max_positions); g_max_pending=(int)ReadState("MAXO",g_max_pending);
  }

//+------------------------------------------------------------------+
//| UI helpers                                                       |
//+------------------------------------------------------------------+
void CommonProps(string name)
  {
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false); ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true); ObjectSetInteger(0,name,OBJPROP_BACK,false);
  }

bool Rect(string name,int x,int y,int w,int h,color bg,color border)
  {
   if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0)) return false; CommonProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w); ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT); return true;
  }

bool Label(string name,string text,int x,int y,int size,color c)
  {
   if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0)) return false; CommonProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size); ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont); ObjectSetString(0,name,OBJPROP_TEXT,text); return true;
  }

bool Button(string name,string text,int x,int y,int w,int h,color bg,color fg,color border)
  {
   if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0)) return false; CommonProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w); ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,name,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,border); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont); ObjectSetString(0,name,OBJPROP_TEXT,text); return true;
  }

bool Edit(string name,string text,int x,int y,int w,int h)
  {
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0)) return false; CommonProps(name);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w); ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,A4_BG); ObjectSetInteger(0,name,OBJPROP_COLOR,A4_TEXT);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,A4_BORDER); ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,name,OBJPROP_ALIGN,ALIGN_CENTER); ObjectSetString(0,name,OBJPROP_FONT,InpPanelFont);
   ObjectSetString(0,name,OBJPROP_TEXT,text); return true;
  }

void SetText(string suffix,string text,color c=clrNONE)
  {
   string name=UI(suffix); if(ObjectFind(0,name)<0) return; ObjectSetString(0,name,OBJPROP_TEXT,text);
   if(c!=clrNONE) ObjectSetInteger(0,name,OBJPROP_COLOR,c);
  }

void SetButton(string suffix,string text,bool active,color active_color=A4_GREEN2)
  {
   string name=UI(suffix); if(ObjectFind(0,name)<0) return;
   ObjectSetString(0,name,OBJPROP_TEXT,text); ObjectSetInteger(0,name,OBJPROP_BGCOLOR,active?active_color:A4_CARD);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,active?active_color:A4_BORDER);
  }

void DeletePanel() { ObjectsDeleteAll(0,g_ui); }

void BuildHeader(int x,int y)
  {
   Rect(UI("BG"),x,y,380,520,A4_BG,A4_BORDER);
   Label(UI("TITLE"),"ARKORISK MT4 v1.50",x+12,y+8,10,A4_TEXT);
   Label(UI("CLOCK"),"TEHRAN",x+230,y+10,8,A4_MUTED);
   Button(UI("TAB_TRADE"),"TRADE",x+10,y+37,84,28,g_tab==ARKO4_TAB_TRADE?A4_BLUE:A4_CARD,g_tab==ARKO4_TAB_TRADE?A4_BG:A4_TEXT,g_tab==ARKO4_TAB_TRADE?A4_BLUE:A4_BORDER);
   Button(UI("TAB_MANAGE"),"MANAGE",x+101,y+37,84,28,g_tab==ARKO4_TAB_MANAGE?A4_BLUE:A4_CARD,g_tab==ARKO4_TAB_MANAGE?A4_BG:A4_TEXT,g_tab==ARKO4_TAB_MANAGE?A4_BLUE:A4_BORDER);
   Button(UI("TAB_JOURNAL"),"JOURNAL",x+192,y+37,84,28,g_tab==ARKO4_TAB_JOURNAL?A4_BLUE:A4_CARD,g_tab==ARKO4_TAB_JOURNAL?A4_BG:A4_TEXT,g_tab==ARKO4_TAB_JOURNAL?A4_BLUE:A4_BORDER);
   Button(UI("TAB_CHART"),"CHART",x+283,y+37,84,28,g_tab==ARKO4_TAB_CHART?A4_BLUE:A4_CARD,g_tab==ARKO4_TAB_CHART?A4_BG:A4_TEXT,g_tab==ARKO4_TAB_CHART?A4_BLUE:A4_BORDER);
  }

void BuildTrade(int x,int y)
  {
   Rect(UI("ACCOUNT"),x+10,y+76,360,60,A4_CARD2,A4_BORDER);
   Label(UI("BAL"),"Balance",x+18,y+87,8,A4_TEXT); Label(UI("EQ"),"Equity",x+196,y+87,8,A4_TEXT);
   Label(UI("DAY"),"Tehran P/L",x+18,y+111,8,A4_TEXT); Label(UI("SPREAD"),"Spread",x+196,y+111,8,A4_TEXT);

   Label(UI("RISK_L"),"Risk",x+14,y+153,8,A4_MUTED); Edit(UI("RISK"),DoubleToString(g_risk,2),x+48,y+144,64,28);
   Label(UI("RISK_U"),"%",x+118,y+153,8,A4_MUTED); Label(UI("RR_L"),"RR",x+164,y+153,8,A4_MUTED);
   Edit(UI("RR"),DoubleToString(g_rr,2),x+190,y+144,60,28);
   Label(UI("PREVIEW"),"Create or drag Limit lines",x+14,y+184,8,A4_BLUE);

   Button(UI("BUY"),"BUY NOW",x+10,y+211,174,34,A4_GREEN,A4_WHITE,A4_GREEN);
   Button(UI("SELL"),"SELL NOW",x+196,y+211,174,34,A4_RED,A4_WHITE,A4_RED);
   Button(UI("BUY_LIMIT"),"BUY LIMIT",x+10,y+253,174,31,A4_GREEN2,A4_WHITE,A4_GREEN2);
   Button(UI("SELL_LIMIT"),"SELL LIMIT",x+196,y+253,174,31,A4_RED2,A4_WHITE,A4_RED2);
   Button(UI("PLACE"),"PLACE LIMIT",x+10,y+292,174,32,A4_BLUE,A4_BG,A4_BLUE);
   Button(UI("DELETE_LINES"),"DELETE LINES",x+196,y+292,174,32,A4_CARD,A4_AMBER,A4_BORDER);
   Label(UI("LEVELS"),"ENTRY / SL / TP",x+14,y+340,8,A4_MUTED);
   Label(UI("TRADE_NOTE"),"SL/TP safety uses full live spread + broker stop level",x+14,y+374,8,A4_MUTED);
  }

void BuildManage(int x,int y)
  {
   Label(UI("BE_L"),"RISK FREE",x+14,y+82,8,A4_MUTED);
   Button(UI("BE"),g_be?"ON":"OFF",x+92,y+75,46,28,g_be?A4_GREEN2:A4_CARD,A4_TEXT,g_be?A4_GREEN2:A4_BORDER);
   Button(UI("BE_MODE"),g_be_mode==ARKO4_TRIGGER_R?"R":"PIPS",x+144,y+75,48,28,A4_CARD,A4_TEXT,A4_BORDER);
   Edit(UI("BE_TRIG"),DoubleToString(g_be_mode==ARKO4_TRIGGER_R?g_be_r:g_be_pips,2),x+198,y+75,60,28);
   Label(UI("BE_LOCK_L"),"LOCK",x+266,y+84,7,A4_MUTED); Edit(UI("BE_LOCK"),DoubleToString(g_be_lock,1),x+307,y+75,60,28);

   Label(UI("PART_L"),"SAVE PROFIT",x+14,y+119,8,A4_MUTED);
   Button(UI("PART"),g_partial?"ON":"OFF",x+92,y+112,46,28,g_partial?A4_GREEN2:A4_CARD,A4_TEXT,g_partial?A4_GREEN2:A4_BORDER);
   Button(UI("PART_MODE"),g_part_mode==ARKO4_TRIGGER_R?"R":"PIPS",x+144,y+112,48,28,A4_CARD,A4_TEXT,A4_BORDER);
   Edit(UI("PART_TRIG"),DoubleToString(g_part_mode==ARKO4_TRIGGER_R?g_part_r:g_part_pips,2),x+198,y+112,60,28);
   Label(UI("PART_PCT_L"),"%",x+276,y+121,8,A4_MUTED); Edit(UI("PART_PCT"),DoubleToString(g_part_pct,0),x+307,y+112,60,28);

   Label(UI("TRAIL_L"),"TRAILING",x+14,y+156,8,A4_MUTED);
   Button(UI("TRAIL"),g_trailing?"ON":"OFF",x+92,y+149,46,28,g_trailing?A4_GREEN2:A4_CARD,A4_TEXT,g_trailing?A4_GREEN2:A4_BORDER);
   Button(UI("TRAIL_MODE"),g_trail_mode==ARKO4_TRIGGER_R?"R":"PIPS",x+144,y+149,48,28,A4_CARD,A4_TEXT,A4_BORDER);
   Edit(UI("TRAIL_START"),DoubleToString(g_trail_mode==ARKO4_TRIGGER_R?g_trail_start_r:g_trail_start_pips,2),x+198,y+149,52,28);
   Edit(UI("TRAIL_DIST"),DoubleToString(g_trail_mode==ARKO4_TRIGGER_R?g_trail_dist_r:g_trail_dist_pips,2),x+256,y+149,52,28);
   Edit(UI("TRAIL_STEP"),DoubleToString(g_trail_mode==ARKO4_TRIGGER_R?g_trail_step_r:g_trail_step_pips,2),x+314,y+149,53,28);
   Label(UI("TRAIL_HINT"),"start / distance / step",x+198,y+181,7,A4_MUTED);

   Button(UI("NEWS"),g_news?"NEWS BLOCK":"NEWS ALLOW",x+10,y+207,100,29,g_news?A4_RED2:A4_GREEN2,A4_TEXT,g_news?A4_RED2:A4_GREEN2);
   Edit(UI("NEWS_B"),IntegerToString(g_news_before),x+116,y+207,44,29); Edit(UI("NEWS_A"),IntegerToString(g_news_after),x+166,y+207,44,29);
   Button(UI("HEDGE"),"HEDGE "+HedgeText(),x+216,y+207,151,29,A4_CARD,A4_TEXT,A4_BORDER);

   Button(UI("MANUAL"),g_manual?"MANUAL ON":"MANUAL OFF",x+10,y+244,112,29,g_manual?A4_GREEN2:A4_CARD,A4_TEXT,g_manual?A4_GREEN2:A4_BORDER);
   Button(UI("OVER"),g_overtrade?"OVERTRADE ON":"OVERTRADE OFF",x+128,y+244,126,29,g_overtrade?A4_GREEN2:A4_CARD,A4_TEXT,g_overtrade?A4_GREEN2:A4_BORDER);
   Label(UI("MAX_L"),"T / P / O",x+270,y+253,7,A4_MUTED);
   Edit(UI("MAX_T"),IntegerToString(g_max_trades),x+10,y+282,54,27); Edit(UI("MAX_P"),IntegerToString(g_max_positions),x+70,y+282,54,27); Edit(UI("MAX_O"),IntegerToString(g_max_pending),x+130,y+282,54,27);
   Label(UI("MAX_NOTE"),"max trades / positions / pending",x+194,y+290,7,A4_MUTED);

   Button(UI("BE_NOW"),"BE NOW",x+10,y+327,80,30,A4_CARD,A4_TEXT,A4_BORDER);
   Button(UI("HALF"),"SAVE 50%",x+96,y+327,88,30,A4_CARD,A4_TEXT,A4_BORDER);
   Button(UI("CLOSE_P"),"CLOSE +",x+190,y+327,82,30,A4_GREEN2,A4_WHITE,A4_GREEN2);
   Button(UI("CLOSE_L"),"CLOSE -",x+278,y+327,89,30,A4_RED2,A4_WHITE,A4_RED2);
   Button(UI("CANCEL"),"CANCEL ORDERS",x+10,y+365,112,30,A4_CARD,A4_AMBER,A4_BORDER);
   Button(UI("CLOSE_ALL"),"EMERGENCY CLOSE",x+128,y+365,126,30,A4_RED,A4_WHITE,A4_RED);
   Button(UI("REVERSE"),"REVERSE",x+260,y+365,107,30,A4_CARD,A4_AMBER,A4_BORDER);
   Label(UI("MANAGE_NOTE"),"Smart BE covers spread + commission + negative swap + buffer",x+14,y+412,8,A4_MUTED);
  }

void BuildJournal(int x,int y)
  {
   Label(UI("JTITLE"),"TRADE JOURNAL • TEHRAN TIME",x+14,y+82,9,A4_TEXT);
   Label(UI("JPATH"),"MQL4\\Files\\"+InpScreenshotFolder,x+14,y+105,8,A4_MUTED);
   Button(UI("SHOT"),"TAKE SCREENSHOT",x+10,y+130,174,31,A4_BLUE,A4_BG,A4_BLUE);
   Button(UI("SHOW_PATH"),"SHOW PATH",x+196,y+130,174,31,A4_CARD,A4_TEXT,A4_BORDER);
   Label(UI("RECENT"),"RECENT MANAGED TRADES",x+14,y+181,8,A4_MUTED);
   for(int i=0;i<7;i++)
     {
      int ry=y+205+i*37; Rect(UI("JBG_"+IntegerToString(i)),x+10,ry,360,31,A4_CARD2,A4_BORDER);
      Label(UI("JROW_"+IntegerToString(i)),"",x+18,ry+8,8,A4_TEXT);
     }
   Label(UI("JNOTE"),"Screenshots are grouped by Tehran date",x+14,y+478,8,A4_MUTED);
  }

void BuildChartTab(int x,int y)
  {
   Label(UI("CTITLE"),"TEHRAN CHART TOOLS",x+14,y+84,9,A4_TEXT);
   Button(UI("DAYS"),InpShowTehranDays?"DAY MARKERS ON":"DAY MARKERS OFF",x+10,y+112,174,31,InpShowTehranDays?A4_GREEN2:A4_CARD,A4_TEXT,InpShowTehranDays?A4_GREEN2:A4_BORDER);
   Button(UI("SESSIONS"),InpShowForexSessions?"SESSIONS ON":"SESSIONS OFF",x+196,y+112,174,31,InpShowForexSessions?A4_GREEN2:A4_CARD,A4_TEXT,InpShowForexSessions?A4_GREEN2:A4_BORDER);
   Label(UI("TOKYO"),"TOKYO",x+18,y+172,9,InpTokyoColor); Label(UI("LONDON"),"LONDON",x+18,y+202,9,InpLondonColor);
   Label(UI("NEWYORK"),"NEW YORK",x+18,y+232,9,InpNewYorkColor); Label(UI("SYDNEY"),"SYDNEY",x+18,y+262,9,InpSydneyColor);
   Label(UI("TIME_NOTE"),"All labels and day boundaries are converted to Tehran UTC+03:30",x+14,y+312,8,A4_MUTED);
   Label(UI("NEWS_NOTE"),"MT4 News Guard uses local CSV because MT4 has no built-in calendar",x+14,y+342,8,A4_MUTED);
  }

void BuildPanel()
  {
   DeletePanel(); int x=InpPanelX,y=InpPanelY; BuildHeader(x,y);
   if(g_tab==ARKO4_TAB_TRADE) BuildTrade(x,y);
   else if(g_tab==ARKO4_TAB_MANAGE) BuildManage(x,y);
   else if(g_tab==ARKO4_TAB_JOURNAL) BuildJournal(x,y);
   else BuildChartTab(x,y);
   Label(UI("STATUS"),g_status,x+12,y+497,8,g_status_color);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Trade designer                                                   |
//+------------------------------------------------------------------+
bool Line(string name,double price,color c,int style)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,NormalizePrice(price))) return false;
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true); ObjectSetInteger(0,name,OBJPROP_SELECTED,true);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,false); ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
     }
   ObjectSetDouble(0,name,OBJPROP_PRICE1,NormalizePrice(price)); ObjectSetInteger(0,name,OBJPROP_COLOR,c); ObjectSetInteger(0,name,OBJPROP_STYLE,style); return true;
  }

double LinePrice(string suffix)
  {
   string n=LN(suffix); if(ObjectFind(0,n)<0) return 0.0; return ObjectGetDouble(0,n,OBJPROP_PRICE1);
  }

bool DesignerExists() { return ObjectFind(0,LN("ENTRY"))>=0 && ObjectFind(0,LN("SL"))>=0 && ObjectFind(0,LN("TP"))>=0; }
void DeleteLines() { ObjectsDeleteAll(0,g_line); }

double CurrentATR()
  {
   double atr=iATR(Symbol(),Period(),MathMax(2,InpATRPeriod),0);
   if(atr<=0.0) atr=MathMax(100*Point,MarketInfo(Symbol(),MODE_STOPLEVEL)*Point*2.0);
   return atr;
  }

double DefaultRiskDistance()
  {
   return MathMax(CurrentATR()*MathMax(0.1,InpDefaultSL_ATR),MathMax(InpMinimumSLPoints,1)*Point);
  }

void ResetDesigner(bool buy)
  {
   RefreshRates(); g_buy_side=buy; double risk=DefaultRiskDistance(); double gap=MathMax(risk*0.35,StopSafetyDistance());
   double entry=(buy?Bid-gap:Ask+gap); double sl=(buy?entry-risk:entry+risk); double tp=(buy?entry+risk*g_rr:entry-risk*g_rr);
   Line(LN("ENTRY"),entry,A4_BLUE,STYLE_SOLID); Line(LN("SL"),sl,A4_RED,STYLE_DASH); Line(LN("TP"),tp,A4_GREEN,STYLE_DASH);
   SetStatus(buy?"Buy Limit designer":"Sell Limit designer",A4_BLUE,4); UpdatePanel();
  }

void SyncDesigner(string dragged)
  {
   if(!DesignerExists()) return; double e=LinePrice("ENTRY"),sl=LinePrice("SL"),tp=LinePrice("TP");
   if(g_buy_side)
     {
      if(sl>=e) sl=e-DefaultRiskDistance();
      if(dragged==LN("TP") && tp>e) g_rr=Clamp((tp-e)/(e-sl),0.1,20.0); else tp=e+(e-sl)*g_rr;
     }
   else
     {
      if(sl<=e) sl=e+DefaultRiskDistance();
      if(dragged==LN("TP") && tp<e) g_rr=Clamp((e-tp)/(sl-e),0.1,20.0); else tp=e-(sl-e)*g_rr;
     }
   ObjectSetDouble(0,LN("ENTRY"),OBJPROP_PRICE1,NormalizePrice(e)); ObjectSetDouble(0,LN("SL"),OBJPROP_PRICE1,NormalizePrice(sl)); ObjectSetDouble(0,LN("TP"),OBJPROP_PRICE1,NormalizePrice(tp));
   UpdatePanel(); ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Risk calculation / spread-aware safety                           |
//+------------------------------------------------------------------+
double StopSafetyDistance(double multiplier=1.0)
  {
   RefreshRates(); double spread=MathMax(0.0,Ask-Bid); double broker=MathMax(MarketInfo(Symbol(),MODE_STOPLEVEL),MarketInfo(Symbol(),MODE_FREEZELEVEL))*Point;
   double rounding=MathMax(2*TickSize(),2*Point); return MathMax(MathMax(broker,TickSize())+rounding,spread+rounding)*MathMax(1.0,multiplier);
  }

bool PrepareMarketStops(bool buy,double &sl,double &tp,double multiplier,string &reason)
  {
   RefreshRates(); double d=StopSafetyDistance(multiplier);
   if(buy) { sl=NormalizePriceDown(MathMin(sl,Bid-d)); tp=NormalizePriceUp(MathMax(tp,Ask+d)); if(sl>=Bid || tp<=Ask) { reason="Invalid spread-safe BUY stops"; return false; } }
   else { sl=NormalizePriceUp(MathMax(sl,Ask+d)); tp=NormalizePriceDown(MathMin(tp,Bid-d)); if(sl<=Ask || tp>=Bid) { reason="Invalid spread-safe SELL stops"; return false; } }
   return true;
  }

bool ValidatePending(bool buy,double e,double sl,double tp,string &reason)
  {
   RefreshRates(); double d=StopSafetyDistance();
   if(buy) { if(e>Ask-d) { reason="Buy Limit too close to Ask/spread"; return false; } if(sl>=e-d || tp<=e+d) { reason="Buy Limit SL/TP too close"; return false; } }
   else { if(e<Bid+d) { reason="Sell Limit too close to Bid/spread"; return false; } if(sl<=e+d || tp>=e-d) { reason="Sell Limit SL/TP too close"; return false; } }
   return true;
  }

double RiskBudget()
  {
   if(InpRiskMode==ARKO4_FIXED_MONEY) return MathMax(0.0,g_risk);
   if(InpRiskMode==ARKO4_BALANCE_PERCENT) return AccountBalance()*MathMax(0.0,g_risk)/100.0;
   if(InpRiskMode==ARKO4_EQUITY_PERCENT) return AccountEquity()*MathMax(0.0,g_risk)/100.0;
   return 0.0;
  }

bool CalcVolume(double entry,double sl,double &lots,double &risk_money,string &reason)
  {
   lots=0; risk_money=0;
   if(InpRiskMode==ARKO4_FIXED_LOT) { lots=NormalizeLotFloor(g_risk,true); if(lots<=0) { reason="Invalid fixed lot"; return false; } }
   else
     {
      double tick_size=TickSize(); double tick_value=MarketInfo(Symbol(),MODE_TICKVALUE);
      if(tick_size<=0 || tick_value<=0) { reason="No tick value"; return false; }
      double loss_one=MathAbs(entry-sl)/tick_size*tick_value;
      if(loss_one<=0) { reason="Invalid SL distance"; return false; }
      double budget=RiskBudget(); lots=NormalizeLotFloor(budget/loss_one,false);
      if(lots<=0) { reason="Risk below broker minimum lot"; return false; }
     }
   double tick_value=MarketInfo(Symbol(),MODE_TICKVALUE); risk_money=MathAbs(entry-sl)/TickSize()*tick_value*lots; return true;
  }

bool IsMarketType(int type) { return type==OP_BUY || type==OP_SELL; }
bool IsPendingType(int type) { return type==OP_BUYLIMIT || type==OP_SELLLIMIT || type==OP_BUYSTOP || type==OP_SELLSTOP; }
bool TypeBuy(int type) { return type==OP_BUY || type==OP_BUYLIMIT || type==OP_BUYSTOP; }

bool ManagedMagic(int magic) { return magic==InpMagicNumber || (g_manual && magic==0); }
bool ManagedSelected() { return OrderSymbol()==Symbol() && ManagedMagic(OrderMagicNumber()); }

int ManagedPositions(bool current_symbol_only=true)
  {
   int n=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsMarketType(OrderType()) && ManagedMagic(OrderMagicNumber()) && (!current_symbol_only || OrderSymbol()==Symbol())) n++; return n;
  }

int ManagedPending(bool current_symbol_only=true)
  {
   int n=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsPendingType(OrderType()) && ManagedMagic(OrderMagicNumber()) && (!current_symbol_only || OrderSymbol()==Symbol())) n++; return n;
  }

bool ScopeMatches(string symbol,int magic)
  {
   if(InpDailyScope==ARKO4_SCOPE_ACCOUNT) return true; if(!ManagedMagic(magic)) return false; if(InpDailyScope==ARKO4_SCOPE_EA_SYMBOL && symbol!=Symbol()) return false; return true;
  }

double OpenRisk(bool &unprotected)
  {
   unprotected=false; double risk=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !ScopeMatches(OrderSymbol(),OrderMagicNumber())) continue;
      if(!IsMarketType(OrderType()) && !IsPendingType(OrderType())) continue;
      double sl=OrderStopLoss(); if(sl<=0) { unprotected=true; continue; }
      double tv=MarketInfo(OrderSymbol(),MODE_TICKVALUE); double ts=MarketInfo(OrderSymbol(),MODE_TICKSIZE); if(ts<=0 || tv<=0) continue;
      risk+=MathAbs(OrderOpenPrice()-sl)/ts*tv*OrderLots();
     }
   return risk;
  }

bool CheckOpenRisk(double new_risk,string &reason)
  {
   if(InpMaxOpenRiskPercent<=0) return true; bool unprotected=false; double current=OpenRisk(unprotected);
   if(unprotected && InpBlockForTradeWithoutSL) { reason="Managed trade without SL detected"; return false; }
   double allowed=AccountEquity()*InpMaxOpenRiskPercent/100.0; if(current+new_risk>allowed+0.01) { reason="Open risk limit exceeded"; return false; } return true;
  }

//+------------------------------------------------------------------+
//| Tehran daily stats / guard                                       |
//+------------------------------------------------------------------+
void DailyStats(double &realized,double &floating,int &trades)
  {
   realized=0; floating=0; trades=0; datetime from,to; TehranDayServerBounds(from,to); datetime now=TimeCurrent();
   for(int i=0;i<OrdersHistoryTotal();i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) || !ScopeMatches(OrderSymbol(),OrderMagicNumber())) continue;
      if(IsMarketType(OrderType()) && OrderCloseTime()>=from && OrderCloseTime()<=now) realized+=OrderProfit()+OrderSwap()+OrderCommission();
      if(IsMarketType(OrderType()) && OrderOpenTime()>=from && OrderOpenTime()<=now) trades++;
     }
   for(int i=0;i<OrdersTotal();i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !ScopeMatches(OrderSymbol(),OrderMagicNumber())) continue;
      if(IsMarketType(OrderType())) { floating+=OrderProfit()+OrderSwap()+OrderCommission(); if(OrderOpenTime()>=from && OrderOpenTime()<=now) trades++; }
     }
  }

string GuardKey(string suffix)
  {
   string s=(InpDailyScope==ARKO4_SCOPE_EA_SYMBOL?Symbol():"ALL"); return StringFormat("ARKO4_G_%d_%d_%d_%s_%s",AccountNumber(),InpMagicNumber,(int)InpDailyScope,s,suffix);
  }

bool DailyLocked(int &kind)
  {
   kind=0; if(!GlobalVariableCheck(GuardKey("DAY")) || (datetime)GlobalVariableGet(GuardKey("DAY"))!=TehranDayStart()) return false;
   kind=GlobalVariableCheck(GuardKey("TYPE"))?(int)GlobalVariableGet(GuardKey("TYPE")):1;
   return !((kind==1 && !InpUseDailyLossGuard) || (kind==2 && !InpUseDailyProfitTarget));
  }

int DailyThreshold(double &result,double &limit)
  {
   double r,f; int t; DailyStats(r,f,t); result=r+(InpIncludeFloatingInDailyGuard?f:0); double start=MathMax(0.01,AccountBalance()-r);
   if(InpUseDailyLossGuard) { limit=(InpDailyLossMode==ARKO4_GUARD_MONEY?InpDailyLossMoney:start*InpDailyLossPercent/100.0); if(limit>0 && result<=-limit) return 1; }
   if(InpUseDailyProfitTarget) { limit=(InpDailyProfitMode==ARKO4_GUARD_MONEY?InpDailyProfitMoney:start*InpDailyProfitPercent/100.0); if(limit>0 && result>=limit) return 2; }
   limit=0; return 0;
  }

void LockDaily(int kind) { GlobalVariableSet(GuardKey("DAY"),TehranDayStart()); GlobalVariableSet(GuardKey("TYPE"),kind); }

int CloseGuardScope()
  {
   int n=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !IsMarketType(OrderType()) || !ScopeMatches(OrderSymbol(),OrderMagicNumber())) continue;
      RefreshRates(); double px=(OrderType()==OP_BUY?MarketInfo(OrderSymbol(),MODE_BID):MarketInfo(OrderSymbol(),MODE_ASK));
      if(OrderClose(OrderTicket(),OrderLots(),px,InpSlippagePoints,clrNONE)) n++;
     }
   return n;
  }

int CancelGuardScope()
  {
   int n=0; for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsPendingType(OrderType()) && ScopeMatches(OrderSymbol(),OrderMagicNumber()) && OrderDelete(OrderTicket(),clrNONE)) n++; return n;
  }

void EnforceDailyGuard()
  {
   int kind=0; if(DailyLocked(kind)) { if(kind==1 && InpCloseAtDailyLoss) CloseGuardScope(); if(kind==1 && InpCancelPendingAtDailyLoss) CancelGuardScope(); if(kind==2 && InpCloseAtDailyProfit) CloseGuardScope(); if(kind==2 && InpCancelPendingAtDailyProfit) CancelGuardScope(); return; }
   double result,limit; kind=DailyThreshold(result,limit); if(kind==0) return; LockDaily(kind);
   int c=(kind==1 && InpCloseAtDailyLoss)||(kind==2 && InpCloseAtDailyProfit)?CloseGuardScope():0;
   int d=(kind==1 && InpCancelPendingAtDailyLoss)||(kind==2 && InpCancelPendingAtDailyProfit)?CancelGuardScope():0;
   SetStatus(StringFormat("TEHRAN %s LOCK %.2f • closed %d cancelled %d",kind==1?"LOSS":"PROFIT",result,c,d),A4_RED,0);
  }

//+------------------------------------------------------------------+
//| MT4 news provider (CSV in Tehran time)                           |
//+------------------------------------------------------------------+
bool CurrencyRelevant(string cur)
  {
   if(!InpNewsCurrentSymbolOnly) return true; string s=Symbol(); StringToUpper(s); StringToUpper(cur); return StringFind(s,cur)>=0;
  }

bool NewsWindow(string &reason)
  {
   reason=""; if(!g_news) return false;
   int h=FileOpen(InpNewsCsvFile,FILE_READ|FILE_CSV|FILE_ANSI,';');
   if(h==INVALID_HANDLE) { if(InpBlockIfNewsFileMissing) { reason="NEWS BLOCK: CSV missing"; return true; } return false; }
   datetime now=TehranNow(); int before=MathMax(0,g_news_before)*60,after=MathMax(0,g_news_after)*60;
   while(!FileIsEnding(h))
     {
      string date=FileReadString(h); string time=FileReadString(h); string cur=FileReadString(h); string impact=FileReadString(h); string title=FileReadString(h);
      StringToUpper(impact); if(date=="" || impact!="HIGH" || !CurrencyRelevant(cur)) continue;
      datetime event=StringToTime(date+" "+time); if(event>0 && now>=event-before && now<=event+after) { reason="NEWS BLOCK "+time+" "+cur+" "+title; FileClose(h); return true; }
     }
   FileClose(h); return false;
  }

//+------------------------------------------------------------------+
//| Hedge / entry guards                                             |
//+------------------------------------------------------------------+
string HedgeText() { if(g_hedge==ARKO4_HEDGE_ALLOW) return "ALLOW"; if(g_hedge==ARKO4_HEDGE_BLOCK) return "BLOCK"; return "WARN"; }

bool HedgeScope(int magic) { return InpHedgeCheckAllAccountTrades || ManagedMagic(magic); }

bool HasOpposite(bool buy,string &details,bool include_positions=true)
  {
   details="";
   for(int i=0;i<OrdersTotal();i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || OrderSymbol()!=Symbol() || !HedgeScope(OrderMagicNumber())) continue;
      int type=OrderType(); if(!include_positions && IsMarketType(type)) continue;
      if((IsMarketType(type)||IsPendingType(type)) && TypeBuy(type)!=buy) { details=StringFormat("opposite #%d",OrderTicket()); return true; }
     }
   return false;
  }

bool ConfirmHedge(bool buy,string &reason,bool include_positions=true)
  {
   if(g_hedge==ARKO4_HEDGE_ALLOW) return true; string d=""; if(!HasOpposite(buy,d,include_positions)) { g_hedge_confirm_side=0; return true; }
   if(g_hedge==ARKO4_HEDGE_BLOCK) { reason="HEDGE BLOCKED • "+d; return false; }
   int side=buy?1:-1; datetime now=TimeCurrent(); if(g_hedge_confirm_side==side && now<=g_hedge_confirm_until) { g_hedge_confirm_side=0; g_hedge_confirm_until=0; return true; }
   g_hedge_confirm_side=side; g_hedge_confirm_until=now+MathMax(3,InpHedgeConfirmationSeconds); reason="HEDGE WARNING • click again"; return false;
  }

bool BasicGuards(string &reason,bool ignore_position_limits=false)
  {
   if(!IsTradeAllowed() || IsTradeContextBusy()) { reason="Trading disabled/busy"; return false; } RefreshRates();
   double spread=(Ask-Bid)/Point; if(InpMaxSpreadPoints>0 && spread>InpMaxSpreadPoints) { reason="Spread limit exceeded"; return false; }
   int lock=0; if(DailyLocked(lock)) { reason="Tehran daily guard locked"; return false; } double day,limit; if(DailyThreshold(day,limit)>0) { reason="Tehran daily threshold reached"; return false; }
   string news=""; if(NewsWindow(news)) { reason=news; return false; }
   if(g_overtrade)
     {
      double r,f; int t; DailyStats(r,f,t); if(g_max_trades>0 && t>=g_max_trades) { reason="Max Tehran-day trades reached"; return false; }
      if(!ignore_position_limits && g_max_positions>0 && ManagedPositions(false)>=g_max_positions) { reason="Max positions reached"; return false; }
     }
   if(!ignore_position_limits && InpOnePositionPerSymbol && ManagedPositions(true)>0) { reason="Position already exists on symbol"; return false; }
   return true;
  }

//+------------------------------------------------------------------+
//| Order execution                                                  |
//+------------------------------------------------------------------+
void DefaultStops(bool buy,double entry,double &sl,double &tp)
  {
   double risk=DefaultRiskDistance(); sl=buy?entry-risk:entry+risk; tp=buy?entry+risk*g_rr:entry-risk*g_rr;
   if(DesignerExists() && g_buy_side==buy)
     {
      double ls=LinePrice("SL"),lt=LinePrice("TP"); if((buy && ls<entry && lt>entry)||(!buy && ls>entry && lt<entry)) { sl=ls; tp=lt; }
     }
  }

void PlaceMarket(bool buy)
  {
   string reason=""; if(!BasicGuards(reason) || !ConfirmHedge(buy,reason)) { SetStatus(reason,A4_RED,8); return; }
   RefreshRates(); double entry=buy?Ask:Bid,sl,tp; DefaultStops(buy,entry,sl,tp); if(!PrepareMarketStops(buy,sl,tp,1.0,reason)) { SetStatus(reason,A4_RED,8); return; }
   double lots,risk; if(!CalcVolume(entry,sl,lots,risk,reason) || !CheckOpenRisk(risk,reason)) { SetStatus(reason,A4_RED,8); return; }
   int type=buy?OP_BUY:OP_SELL; double price=buy?Ask:Bid; int ticket=OrderSend(Symbol(),type,lots,price,InpSlippagePoints,sl,tp,buy?"ArkoRisk MT4 BUY":"ArkoRisk MT4 SELL",InpMagicNumber,0,buy?A4_GREEN:A4_RED);
   if(ticket>0) SetStatus(StringFormat("%s opened • %s lots",buy?"BUY":"SELL",DoubleToString(lots,LotDigits())),A4_GREEN,7); else SetStatus(StringFormat("OrderSend failed %d",GetLastError()),A4_RED,8); UpdatePanel();
  }

void PlaceLimit()
  {
   string reason=""; if(!BasicGuards(reason) || !ConfirmHedge(g_buy_side,reason)) { SetStatus(reason,A4_RED,8); return; }
   if(g_overtrade && g_max_pending>0 && ManagedPending(false)>=g_max_pending) { SetStatus("Max pending orders reached",A4_RED,7); return; }
   if(!DesignerExists()) { SetStatus("Limit lines missing",A4_RED,6); return; }
   double e=NormalizePrice(LinePrice("ENTRY")),sl=NormalizePrice(LinePrice("SL")),tp=NormalizePrice(LinePrice("TP")); if(!ValidatePending(g_buy_side,e,sl,tp,reason)) { SetStatus(reason,A4_RED,8); return; }
   double lots,risk; if(!CalcVolume(e,sl,lots,risk,reason) || !CheckOpenRisk(risk,reason)) { SetStatus(reason,A4_RED,8); return; }
   int type=g_buy_side?OP_BUYLIMIT:OP_SELLLIMIT; int ticket=OrderSend(Symbol(),type,lots,e,InpSlippagePoints,sl,tp,"ArkoRisk MT4 Limit",InpMagicNumber,0,g_buy_side?A4_GREEN:A4_RED);
   if(ticket>0) SetStatus("Limit placed",A4_GREEN,7); else SetStatus(StringFormat("Limit failed %d",GetLastError()),A4_RED,8); UpdatePanel();
  }

//+------------------------------------------------------------------+
//| Smart break-even / management                                    |
//+------------------------------------------------------------------+
double EstimateOneWayCommissionPerLot()
  {
   double cost=0,lots=0; int samples=0;
   for(int i=OrdersHistoryTotal()-1;i>=0 && samples<150;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) || OrderSymbol()!=Symbol() || !IsMarketType(OrderType()) || OrderLots()<=0) continue;
      double c=MathAbs(OrderCommission()); if(c<=0) continue;
      // Closed MT4 orders normally contain round-turn commission; divide by 2.
      cost+=c*0.5; lots+=OrderLots(); samples++;
     }
   return lots>0?cost/lots:0.0;
  }

double SmartBEOffset()
  {
   double offset=MathMax(g_be_lock,InpBreakEvenExtraBufferPips)*PipSize(); if(InpBreakEvenCoverLiveSpread) { RefreshRates(); offset+=Ask-Bid; }
   if(InpBreakEvenCoverCommission)
     {
      double accrued=MathAbs(OrderCommission())+MathMax(0.0,-OrderSwap()); double total=accrued;
      if(InpCommissionPerLotRoundTurn>0) total=MathMax(total,InpCommissionPerLotRoundTurn*OrderLots());
      else { double roundturn=2.0*EstimateOneWayCommissionPerLot()*OrderLots(); total=MathMax(total,roundturn); }
      double tv=MarketInfo(OrderSymbol(),MODE_TICKVALUE),ts=MarketInfo(OrderSymbol(),MODE_TICKSIZE); if(tv>0 && ts>0 && OrderLots()>0) offset+=MathCeil(total/(tv*OrderLots())-1e-12)*ts;
     }
   return offset;
  }

string TradeStateKey(int ticket,string suffix) { return StringFormat("ARKO4_T_%d_%d_%s",AccountNumber(),ticket,suffix); }
double TradeState(int ticket,string suffix,double fallback) { string k=TradeStateKey(ticket,suffix); if(!GlobalVariableCheck(k)) GlobalVariableSet(k,fallback); return GlobalVariableGet(k); }

bool TriggerReached(ARKO4_TRIGGER_MODE mode,double r,double progress,double at_r,double at_pips)
  {
   return mode==ARKO4_TRIGGER_PIPS?progress>=MathMax(0.0,at_pips)*PipSize():r>=MathMax(0.0,at_r);
  }

void ManageOpenTrades()
  {
   uint now=GetTickCount(); if(now-g_last_manage_ms<200) return; g_last_manage_ms=now; RefreshRates(); double min_stop=StopSafetyDistance();
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !IsMarketType(OrderType()) || !ManagedSelected()) continue;
      int ticket=OrderTicket(); bool buy=OrderType()==OP_BUY; double entry=OrderOpenPrice(),sl=OrderStopLoss(),tp=OrderTakeProfit(),lots=OrderLots();
      double fallback=sl>0?MathAbs(entry-sl):DefaultRiskDistance(); double initial=TradeState(ticket,"R",fallback); double initial_lots=TradeState(ticket,"V",lots); double partial_done=TradeState(ticket,"P",0);
      if(initial<=0) initial=DefaultRiskDistance(); double current=buy?Bid:Ask; double progress=buy?current-entry:entry-current; double r=progress/initial;

      if(g_partial && partial_done<0.5 && TriggerReached(g_part_mode,r,progress,g_part_r,g_part_pips))
        {
         double close_lots=NormalizeLotFloor(initial_lots*Clamp(g_part_pct,1,99)/100.0,false); double minimum=MarketInfo(Symbol(),MODE_MINLOT);
         if(close_lots>0 && lots-close_lots>=minimum-1e-12)
           {
            double px=buy?Bid:Ask; if(OrderClose(ticket,close_lots,px,InpSlippagePoints,clrNONE)) { GlobalVariableSet(TradeStateKey(ticket,"P"),1); SetStatus("Auto save-profit completed",A4_GREEN,5); }
           }
         else GlobalVariableSet(TradeStateKey(ticket,"P"),1);
        }

      if(!OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) continue; sl=OrderStopLoss(); tp=OrderTakeProfit(); double desired=sl; bool modify=false;
      if(g_be && TriggerReached(g_be_mode,r,progress,g_be_r,g_be_pips))
        {
         double be=buy?NormalizePriceUp(entry+SmartBEOffset()):NormalizePriceDown(entry-SmartBEOffset()); bool valid=buy?be<=Bid-min_stop:be>=Ask+min_stop; bool improves=buy?(sl<=0 || be>sl+Point*0.5):(sl<=0 || be<sl-Point*0.5);
         if(valid && improves) { desired=be; modify=true; }
        }
      if(g_trailing && TriggerReached(g_trail_mode,r,progress,g_trail_start_r,g_trail_start_pips))
        {
         double dist=g_trail_mode==ARKO4_TRIGGER_PIPS?MathMax(0.1,g_trail_dist_pips)*PipSize():initial*MathMax(0.05,g_trail_dist_r);
         double step=g_trail_mode==ARKO4_TRIGGER_PIPS?MathMax(0.1,g_trail_step_pips)*PipSize():initial*MathMax(0.01,g_trail_step_r);
         double cand=buy?NormalizePriceDown(Bid-dist):NormalizePriceUp(Ask+dist); bool valid=buy?cand<=Bid-min_stop:cand>=Ask+min_stop; bool improves=buy?(desired<=0 || cand>desired+step):(desired<=0 || cand<desired-step);
         if(valid && improves) { desired=cand; modify=true; }
        }
      if(modify && !OrderModify(ticket,OrderOpenPrice(),desired,tp,0,clrNONE)) Print("ArkoRisk MT4 OrderModify failed #",ticket," err=",GetLastError());
     }
  }

void BreakEvenAll()
  {
   RefreshRates(); double min_stop=StopSafetyDistance(); int changed=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !IsMarketType(OrderType()) || !ManagedSelected()) continue; bool buy=OrderType()==OP_BUY; double next=buy?NormalizePriceUp(OrderOpenPrice()+SmartBEOffset()):NormalizePriceDown(OrderOpenPrice()-SmartBEOffset());
      bool valid=buy?next<Bid-min_stop:next>Ask+min_stop; bool improves=buy?(OrderStopLoss()<=0 || next>OrderStopLoss()):(OrderStopLoss()<=0 || next<OrderStopLoss()); if(valid && improves && OrderModify(OrderTicket(),OrderOpenPrice(),next,OrderTakeProfit(),0,clrNONE)) changed++;
     }
   SetStatus(StringFormat("Smart BE applied to %d trade(s)",changed),changed>0?A4_GREEN:A4_AMBER,6);
  }

void CloseHalfAll()
  {
   int n=0; RefreshRates(); for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsMarketType(OrderType()) && ManagedSelected()) { double half=NormalizeLotFloor(OrderLots()*0.5,false); if(half>0 && OrderLots()-half>=MarketInfo(Symbol(),MODE_MINLOT)-1e-12 && OrderClose(OrderTicket(),half,OrderType()==OP_BUY?Bid:Ask,InpSlippagePoints,clrNONE)) n++; }
   SetStatus(StringFormat("Saved 50%% on %d trade(s)",n),n>0?A4_GREEN:A4_AMBER,6);
  }

void CloseByProfit(bool profit)
  {
   int n=0; RefreshRates(); for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsMarketType(OrderType()) && ManagedSelected()) { double pnl=OrderProfit()+OrderSwap()+OrderCommission(); if((profit&&pnl>0)||(!profit&&pnl<0)) if(OrderClose(OrderTicket(),OrderLots(),OrderType()==OP_BUY?Bid:Ask,InpSlippagePoints,clrNONE)) n++; }
   SetStatus(StringFormat("Closed %d %s trade(s)",n,profit?"profitable":"losing"),n>0?A4_GREEN:A4_AMBER,6);
  }

void CloseAllManaged()
  {
   int n=0; RefreshRates(); for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsMarketType(OrderType()) && ManagedSelected() && OrderClose(OrderTicket(),OrderLots(),OrderType()==OP_BUY?Bid:Ask,InpSlippagePoints,clrNONE)) n++; SetStatus(StringFormat("Emergency closed %d trade(s)",n),n>0?A4_GREEN:A4_AMBER,6);
  }

void CancelPending()
  {
   int n=0; for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsPendingType(OrderType()) && OrderSymbol()==Symbol() && ManagedMagic(OrderMagicNumber()) && OrderDelete(OrderTicket(),clrNONE)) n++; SetStatus(StringFormat("Cancelled %d pending",n),n>0?A4_GREEN:A4_AMBER,6);
  }

void CancelStale()
  {
   if(InpCancelPendingAfterMinutes<=0 || TimeCurrent()-g_last_stale_scan<30) return; g_last_stale_scan=TimeCurrent();
   for(int i=OrdersTotal()-1;i>=0;i--) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsPendingType(OrderType()) && ManagedMagic(OrderMagicNumber()) && TimeCurrent()-OrderOpenTime()>=InpCancelPendingAfterMinutes*60) OrderDelete(OrderTicket(),clrNONE);
  }

void ReverseManaged()
  {
   string reason=""; if(!BasicGuards(reason,true)) { SetStatus(reason,A4_RED,8); return; } int direction=0,count=0; double lots=0;
   for(int i=0;i<OrdersTotal();i++) if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && IsMarketType(OrderType()) && ManagedSelected()) { int side=OrderType()==OP_BUY?1:-1; if(direction!=0 && side!=direction) { SetStatus("Reverse refused: mixed directions",A4_RED,7); return; } direction=side; lots+=OrderLots(); count++; }
   if(count==0) { SetStatus("No managed trade to reverse",A4_AMBER,6); return; } bool buy=direction<0; if(!ConfirmHedge(buy,reason,false)) { SetStatus(reason,A4_AMBER,7); return; }
   CloseAllManaged(); RefreshRates(); double sl,tp; double entry=buy?Ask:Bid; DefaultStops(buy,entry,sl,tp); if(!PrepareMarketStops(buy,sl,tp,1.0,reason)) { SetStatus(reason,A4_RED,7); return; }
   int ticket=OrderSend(Symbol(),buy?OP_BUY:OP_SELL,NormalizeLotFloor(lots,true),buy?Ask:Bid,InpSlippagePoints,sl,tp,"ArkoRisk MT4 Reverse",InpMagicNumber,0,clrNONE); if(ticket>0) SetStatus("Position reversed",A4_GREEN,7); else SetStatus(StringFormat("Reverse failed %d",GetLastError()),A4_RED,7);
  }

//+------------------------------------------------------------------+
//| Journal                                                          |
//+------------------------------------------------------------------+
string JournalFolder(datetime tehran)
  {
   MqlDateTime tm; TimeToStruct(tehran,tm); return StringFormat("%s\\%04d-%02d-%02d",InpScreenshotFolder,tm.year,tm.mon,tm.day);
  }

void TakeScreenshot(string tag)
  {
   if(!InpTakeEntryScreenshot) { SetStatus("Screenshots disabled",A4_AMBER,5); return; } datetime now=TehranNow(); MqlDateTime tm; TimeToStruct(now,tm); string folder=JournalFolder(now);
   FolderCreate("ArkoRisk"); FolderCreate(InpScreenshotFolder); FolderCreate(folder); string file=StringFormat("%s\\%02d%02d%02d_%s_%s.png",folder,tm.hour,tm.min,tm.sec,StringSubstr(SafeToken(Symbol()),0,10),tag);
   if(WindowScreenShot(file,MathMax(640,InpScreenshotWidth),MathMax(360,InpScreenshotHeight))) { SetStatus("Screenshot saved • "+file,A4_GREEN,8); Print("ArkoRisk journal: ",TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\Files\\",file); }
   else SetStatus(StringFormat("Screenshot failed %d",GetLastError()),A4_RED,7);
  }

void ScanEntryScreenshots()
  {
   if(!InpTakeEntryScreenshot) return;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !IsMarketType(OrderType()) || !ManagedSelected()) continue;
      string key=StringFormat("ARKO4_SHOT_%d_%d",AccountNumber(),OrderTicket()); if(GlobalVariableCheck(key)) continue;
      GlobalVariableSet(key,1); TakeScreenshot(StringFormat("%s_%d",OrderType()==OP_BUY?"BUY":"SELL",OrderTicket()%100000));
     }
  }

void UpdateJournalRows()
  {
   if(g_tab!=ARKO4_TAB_JOURNAL) return; int row=0;
   for(int i=OrdersTotal()-1;i>=0 && row<7;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES) || !IsMarketType(OrderType()) || !ManagedSelected()) continue; datetime tt=(datetime)((long)OrderOpenTime()-ServerUTCOffsetSeconds()+InpTehranUTCOffsetMinutes*60);
      SetText("JROW_"+IntegerToString(row),StringFormat("%s  %-8s %-4s #%05d",TimeToString(tt,TIME_MINUTES),OrderSymbol(),OrderType()==OP_BUY?"BUY":"SELL",OrderTicket()%100000),OrderType()==OP_BUY?A4_GREEN:A4_RED); row++;
     }
   for(int i=OrdersHistoryTotal()-1;i>=0 && row<7;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) || !IsMarketType(OrderType()) || !ManagedMagic(OrderMagicNumber()) || OrderSymbol()!=Symbol()) continue; datetime tt=(datetime)((long)OrderOpenTime()-ServerUTCOffsetSeconds()+InpTehranUTCOffsetMinutes*60);
      SetText("JROW_"+IntegerToString(row),StringFormat("%s  %-8s %-4s #%05d",TimeToString(tt,TIME_MINUTES),OrderSymbol(),OrderType()==OP_BUY?"BUY":"SELL",OrderTicket()%100000),A4_MUTED); row++;
     }
   for(int j=row;j<7;j++) SetText("JROW_"+IntegerToString(j),j==0?"No managed trades":"",A4_MUTED);
  }

//+------------------------------------------------------------------+
//| Tehran day/session markers                                       |
//+------------------------------------------------------------------+
int DaysInMonth(int year,int mon)
  {
   if(mon==2) { bool leap=(year%4==0 && (year%100!=0 || year%400==0)); return leap?29:28; }
   if(mon==4||mon==6||mon==9||mon==11) return 30; return 31;
  }

int WeekdayOfDate(int year,int mon,int day)
  {
   MqlDateTime tm; tm.year=year; tm.mon=mon; tm.day=day; tm.hour=12; tm.min=0; tm.sec=0; datetime d=StructToTime(tm); TimeToStruct(d,tm); return tm.day_of_week;
  }

int LastSunday(int year,int mon)
  {
   int d=DaysInMonth(year,mon); while(WeekdayOfDate(year,mon,d)!=0) d--; return d;
  }

int NthSunday(int year,int mon,int nth)
  {
   int d=1; while(WeekdayOfDate(year,mon,d)!=0) d++; return d+(nth-1)*7;
  }

bool EuropeDST(datetime utc)
  {
   MqlDateTime t; TimeToStruct(utc,t); MqlDateTime a,b; a.year=t.year;a.mon=3;a.day=LastSunday(t.year,3);a.hour=1;a.min=0;a.sec=0; b.year=t.year;b.mon=10;b.day=LastSunday(t.year,10);b.hour=1;b.min=0;b.sec=0; return utc>=StructToTime(a)&&utc<StructToTime(b);
  }

bool USDST(datetime utc)
  {
   MqlDateTime t; TimeToStruct(utc,t); MqlDateTime a,b; a.year=t.year;a.mon=3;a.day=NthSunday(t.year,3,2);a.hour=7;a.min=0;a.sec=0; b.year=t.year;b.mon=11;b.day=NthSunday(t.year,11,1);b.hour=6;b.min=0;b.sec=0; return utc>=StructToTime(a)&&utc<StructToTime(b);
  }

bool SydneyDST(datetime utc)
  {
   MqlDateTime t; TimeToStruct(utc,t); if(t.mon>=10 || t.mon<=3) return true; return false; // boundary weeks are intentionally conservative
  }

int SessionTehranMinutes(int session,datetime local_day)
  {
   datetime utc_probe=(datetime)((long)local_day-InpTehranUTCOffsetMinutes*60+12*3600);
   if(session==0) return SydneyDST(utc_probe)?30:90;      // 00:30 / 01:30 Tehran
   if(session==1) return 3*60+30;                        // Tokyo 03:30
   if(session==2) return EuropeDST(utc_probe)?10*60+30:11*60+30;
   return USDST(utc_probe)?15*60+30:16*60+30;
  }

string SessionName(int s) { if(s==0)return "SYDNEY"; if(s==1)return "TOKYO"; if(s==2)return "LONDON"; return "NEW YORK"; }
color SessionColor(int s) { if(s==0)return InpSydneyColor; if(s==1)return InpTokyoColor; if(s==2)return InpLondonColor; return InpNewYorkColor; }

void DrawMarkers(bool force=false)
  {
   datetime today=TehranDayStart(); if(!force && g_last_tehran_day==today) return; g_last_tehran_day=today;
   ObjectsDeleteAll(0,g_day); ObjectsDeleteAll(0,g_session); int lookback=MathMax(1,MathMin(20,InpMarkerLookbackDays)); long server_offset=ServerUTCOffsetSeconds();
   for(int i=0;i<lookback;i++)
     {
      datetime local=(datetime)((long)today-i*86400); MqlDateTime tm; TimeToStruct(local,tm); datetime server=(datetime)((long)local-InpTehranUTCOffsetMinutes*60+server_offset);
      if(InpShowTehranDays)
        {
         string n=g_day+IntegerToString(i); if(ObjectCreate(0,n,OBJ_VLINE,0,server,0)) { ObjectSetInteger(0,n,OBJPROP_COLOR,A4_BORDER); ObjectSetInteger(0,n,OBJPROP_STYLE,STYLE_DASHDOTDOT); ObjectSetString(0,n,OBJPROP_TEXT,StringFormat("%s %04d-%02d-%02d TEHRAN",WeekdayName(tm.day_of_week),tm.year,tm.mon,tm.day)); ObjectSetInteger(0,n,OBJPROP_BACK,true); }
        }
      if(InpShowForexSessions)
         for(int s=0;s<4;s++)
           {
            int mins=SessionTehranMinutes(s,local); datetime st=(datetime)((long)local+mins*60-InpTehranUTCOffsetMinutes*60+server_offset); string n=g_session+IntegerToString(i)+"_"+IntegerToString(s);
            if(ObjectCreate(0,n,OBJ_VLINE,0,st,0)) { ObjectSetInteger(0,n,OBJPROP_COLOR,SessionColor(s)); ObjectSetInteger(0,n,OBJPROP_STYLE,STYLE_DOT); ObjectSetString(0,n,OBJPROP_TEXT,SessionName(s)+" • "+TimeToString((datetime)((long)local+mins*60),TIME_MINUTES)+" TEHRAN"); ObjectSetInteger(0,n,OBJPROP_BACK,true); }
           }
     }
  }

void UpdateCandleTimer()
  {
   if(!InpShowCandleTimer) { ObjectDelete(0,g_timer); return; } int sec=PeriodSeconds(); if(sec<=0) return; datetime open=iTime(Symbol(),Period(),0); int left=(int)MathMax(0,(long)(open+sec-TimeCurrent()));
   string text=StringFormat("%s • %02d:%02d",Period()==1?"M1":IntegerToString(Period()),left/60,left%60);
   if(ObjectFind(0,g_timer)<0) { ObjectCreate(0,g_timer,OBJ_LABEL,0,0,0); ObjectSetInteger(0,g_timer,OBJPROP_CORNER,CORNER_RIGHT_UPPER); ObjectSetInteger(0,g_timer,OBJPROP_XDISTANCE,15); ObjectSetInteger(0,g_timer,OBJPROP_YDISTANCE,15); ObjectSetInteger(0,g_timer,OBJPROP_FONTSIZE,9); ObjectSetString(0,g_timer,OBJPROP_FONT,InpPanelFont); ObjectSetInteger(0,g_timer,OBJPROP_COLOR,A4_BLUE); }
   ObjectSetString(0,g_timer,OBJPROP_TEXT,text);
  }

//+------------------------------------------------------------------+
//| Panel live update                                                |
//+------------------------------------------------------------------+
void UpdatePanel()
  {
   if(g_status_until>0 && TimeCurrent()>g_status_until) { g_status="Ready • Tehran protections active"; g_status_color=A4_MUTED; g_status_until=0; }
   SetText("CLOCK",TimeToString(TehranNow(),TIME_MINUTES)+" TEHRAN",A4_MUTED); SetText("STATUS",g_status,g_status_color);
   if(g_tab==ARKO4_TAB_TRADE)
     {
      double r,f; int t; DailyStats(r,f,t); double day=r+(InpIncludeFloatingInDailyGuard?f:0); RefreshRates();
      SetText("BAL",StringFormat("Balance %.2f",AccountBalance()),A4_TEXT); SetText("EQ",StringFormat("Equity %.2f",AccountEquity()),A4_TEXT);
      SetText("DAY",StringFormat("Tehran P/L %+.2f (%d)",day,t),day>=0?A4_GREEN:A4_RED); SetText("SPREAD",StringFormat("Spread %.0f pts",(Ask-Bid)/Point),A4_TEXT);
      if(DesignerExists())
        {
         double lots,risk; string reason=""; if(CalcVolume(LinePrice("ENTRY"),LinePrice("SL"),lots,risk,reason)) { SetText("PREVIEW",StringFormat("Lot %s • Risk %.2f • RR %.2f",DoubleToString(lots,LotDigits()),risk,g_rr),A4_BLUE); SetText("LEVELS",StringFormat("%s E %s / SL %s / TP %s",g_buy_side?"BUY LIMIT":"SELL LIMIT",DoubleToString(LinePrice("ENTRY"),Digits),DoubleToString(LinePrice("SL"),Digits),DoubleToString(LinePrice("TP"),Digits)),A4_MUTED); } else SetText("PREVIEW",reason,A4_AMBER);
        }
     }
   else if(g_tab==ARKO4_TAB_JOURNAL) UpdateJournalRows();
  }

void Toggle(bool &value,string title) { value=!value; SaveRuntime(); SetStatus(title+(value?" ON":" OFF"),value?A4_GREEN:A4_AMBER,5); BuildPanel(); UpdatePanel(); }
void ToggleMode(ARKO4_TRIGGER_MODE &mode) { mode=mode==ARKO4_TRIGGER_R?ARKO4_TRIGGER_PIPS:ARKO4_TRIGGER_R; SaveRuntime(); BuildPanel(); UpdatePanel(); }
void CycleHedge() { if(g_hedge==ARKO4_HEDGE_WARN)g_hedge=ARKO4_HEDGE_ALLOW; else if(g_hedge==ARKO4_HEDGE_ALLOW)g_hedge=ARKO4_HEDGE_BLOCK; else g_hedge=ARKO4_HEDGE_WARN; SaveRuntime(); SetStatus("Hedge "+HedgeText(),A4_BLUE,5); BuildPanel(); }

bool RuntimeEdit(string n)
  {
   return n==UI("BE_TRIG")||n==UI("BE_LOCK")||n==UI("PART_TRIG")||n==UI("PART_PCT")||n==UI("TRAIL_START")||n==UI("TRAIL_DIST")||n==UI("TRAIL_STEP")||n==UI("NEWS_B")||n==UI("NEWS_A")||n==UI("MAX_T")||n==UI("MAX_P")||n==UI("MAX_O")||n==UI("RISK")||n==UI("RR");
  }

void ReadEdit(string n)
  {
   double v=StringToDouble(ObjectGetString(0,n,OBJPROP_TEXT));
   if(n==UI("RISK") && v>0) g_risk=v; else if(n==UI("RR")&&v>0) { g_rr=Clamp(v,0.1,20); if(DesignerExists()) SyncDesigner(LN("ENTRY")); }
   else if(n==UI("BE_TRIG")&&v>0) { if(g_be_mode==ARKO4_TRIGGER_R)g_be_r=Clamp(v,0.05,20); else g_be_pips=Clamp(v,0.1,10000); }
   else if(n==UI("BE_LOCK"))g_be_lock=Clamp(v,0,10000); else if(n==UI("PART_TRIG")&&v>0){if(g_part_mode==ARKO4_TRIGGER_R)g_part_r=Clamp(v,0.05,20);else g_part_pips=Clamp(v,0.1,10000);} else if(n==UI("PART_PCT"))g_part_pct=Clamp(v,1,99);
   else if(n==UI("TRAIL_START")&&v>0){if(g_trail_mode==ARKO4_TRIGGER_R)g_trail_start_r=Clamp(v,0.05,20);else g_trail_start_pips=Clamp(v,0.1,10000);} else if(n==UI("TRAIL_DIST")&&v>0){if(g_trail_mode==ARKO4_TRIGGER_R)g_trail_dist_r=Clamp(v,0.01,20);else g_trail_dist_pips=Clamp(v,0.1,10000);} else if(n==UI("TRAIL_STEP")&&v>0){if(g_trail_mode==ARKO4_TRIGGER_R)g_trail_step_r=Clamp(v,0.01,20);else g_trail_step_pips=Clamp(v,0.1,10000);}
   else if(n==UI("NEWS_B"))g_news_before=(int)Clamp(v,0,240); else if(n==UI("NEWS_A"))g_news_after=(int)Clamp(v,0,240); else if(n==UI("MAX_T"))g_max_trades=(int)Clamp(v,0,1000); else if(n==UI("MAX_P"))g_max_positions=(int)Clamp(v,0,1000); else if(n==UI("MAX_O"))g_max_pending=(int)Clamp(v,0,1000);
   SaveRuntime(); BuildPanel(); UpdatePanel();
  }

//+------------------------------------------------------------------+
//| Standard events                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_prefix=StringFormat("ARKO4_%I64d_",ChartID()); g_ui=g_prefix+"UI_"; g_line=g_prefix+"LINE_"; g_day=g_prefix+"DAY_"; g_session=g_prefix+"SESSION_"; g_timer=g_prefix+"TIMER";
   g_risk=(InpRiskMode==ARKO4_FIXED_MONEY?InpFixedRiskMoney:(InpRiskMode==ARKO4_FIXED_LOT?InpFixedLot:InpDefaultRisk)); g_rr=InpDefaultRR; InitRuntime();
   FolderCreate("ArkoRisk"); FolderCreate(InpScreenshotFolder); BuildPanel(); DrawMarkers(true); UpdateCandleTimer(); EventSetTimer(1); SetStatus("ArkoRisk MT4 v1.50 ready",A4_BLUE,6); return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer(); SaveRuntime(); DeletePanel(); DeleteLines(); ObjectsDeleteAll(0,g_day); ObjectsDeleteAll(0,g_session); ObjectDelete(0,g_timer); ChartRedraw();
  }

void OnTick()
  {
   ManageOpenTrades(); ScanEntryScreenshots();
  }

void OnTimer()
  {
   EnforceDailyGuard(); CancelStale(); DrawMarkers(false); UpdateCandleTimer(); UpdatePanel(); ChartRedraw();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      if(sparam==UI("TAB_TRADE")){g_tab=ARKO4_TAB_TRADE;BuildPanel();UpdatePanel();return;}
      if(sparam==UI("TAB_MANAGE")){g_tab=ARKO4_TAB_MANAGE;BuildPanel();UpdatePanel();return;}
      if(sparam==UI("TAB_JOURNAL")){g_tab=ARKO4_TAB_JOURNAL;BuildPanel();UpdatePanel();return;}
      if(sparam==UI("TAB_CHART")){g_tab=ARKO4_TAB_CHART;BuildPanel();UpdatePanel();return;}
      if(sparam==UI("BUY")){PlaceMarket(true);return;} if(sparam==UI("SELL")){PlaceMarket(false);return;}
      if(sparam==UI("BUY_LIMIT")){ResetDesigner(true);return;} if(sparam==UI("SELL_LIMIT")){ResetDesigner(false);return;}
      if(sparam==UI("PLACE")){PlaceLimit();return;} if(sparam==UI("DELETE_LINES")){DeleteLines();SetStatus("Lines deleted",A4_AMBER,4);UpdatePanel();return;}
      if(sparam==UI("BE")){Toggle(g_be,"Risk-free");return;} if(sparam==UI("BE_MODE")){ToggleMode(g_be_mode);return;}
      if(sparam==UI("PART")){Toggle(g_partial,"Save-profit");return;} if(sparam==UI("PART_MODE")){ToggleMode(g_part_mode);return;}
      if(sparam==UI("TRAIL")){Toggle(g_trailing,"Trailing");return;} if(sparam==UI("TRAIL_MODE")){ToggleMode(g_trail_mode);return;}
      if(sparam==UI("NEWS")){Toggle(g_news,"News block");return;} if(sparam==UI("HEDGE")){CycleHedge();return;}
      if(sparam==UI("MANUAL")){Toggle(g_manual,"Manual management");return;} if(sparam==UI("OVER")){Toggle(g_overtrade,"Overtrading guard");return;}
      if(sparam==UI("BE_NOW")){BreakEvenAll();return;} if(sparam==UI("HALF")){CloseHalfAll();return;} if(sparam==UI("CLOSE_P")){CloseByProfit(true);return;} if(sparam==UI("CLOSE_L")){CloseByProfit(false);return;}
      if(sparam==UI("CANCEL")){CancelPending();return;} if(sparam==UI("CLOSE_ALL")){CloseAllManaged();return;} if(sparam==UI("REVERSE")){ReverseManaged();return;}
      if(sparam==UI("SHOT")){TakeScreenshot("MANUAL");return;} if(sparam==UI("SHOW_PATH")){SetStatus("MQL4\\Files\\"+InpScreenshotFolder,A4_BLUE,10);Print("Journal: ",TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\Files\\",InpScreenshotFolder);return;}
     }
   if(id==CHARTEVENT_OBJECT_ENDEDIT && RuntimeEdit(sparam)){ReadEdit(sparam);return;}
   if(id==CHARTEVENT_OBJECT_DRAG && (sparam==LN("ENTRY")||sparam==LN("SL")||sparam==LN("TP"))){SyncDesigner(sparam);return;}
   if(id==CHARTEVENT_CHART_CHANGE){DrawMarkers(true);BuildPanel();UpdatePanel();}
  }
