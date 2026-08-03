# راهنمای کامل ArkoRisk MT5 — نسخه 1.40

ArkoRisk یک Expert Advisor برای اجرای سریع، اندازه‌گیری ریسک و مدیریت پوزیشن در MetaTrader 5 است. این اکسپرت تحلیل یا سیگنال تولید نمی‌کند؛ شما جهت و ساختار معامله را تعیین می‌کنید و ArkoRisk حجم، محدودیت‌ها و اجرای آن را کنترل می‌کند.

## فهرست

1. [نصب](#نصب)
2. [آشنایی با پنل](#آشنایی-با-پنل)
3. [معامله Market](#معامله-market)
4. [معامله Limit و خطوط](#معامله-limit-و-خطوط)
5. [مدیریت سرمایه](#مدیریت-سرمایه)
6. [مدیریت خودکار پوزیشن](#مدیریت-خودکار-پوزیشن)
7. [محافظ حساب و پراپ](#محافظ-حساب-و-پراپ)
8. [اخبار و ساعت تهران](#اخبار-و-ساعت-تهران)
9. [هج، ژورنال و اسکرین‌شات](#هج-ژورنال-و-اسکرین‌شات)
10. [تم، سشن و تایمر کندل](#تم-سشن-و-تایمر-کندل)
11. [Inputها](#inputها)
12. [چک‌لیست پیش از حساب واقعی](#چک‌لیست-پیش-از-حساب-واقعی)

## نصب

1. در MT5 روی `File → Open Data Folder` کلیک کنید.
2. پوشه `MQL5` بسته ArkoRisk را روی پوشه `MQL5` ترمینال کپی کنید. ساختار نهایی باید چنین باشد:

   ```text
   MQL5/Experts/ArkoRisk/ArkoRisk.mq5
   MQL5/Images/ArkoRisk/ArkoRisk.ico
   ```

3. فایل `ArkoRisk.mq5` را در MetaEditor باز کنید و `F7` را بزنید.
4. به MT5 برگردید، در Navigator روی Expert Advisors راست‌کلیک و `Refresh` را انتخاب کنید.
5. اکسپرت را روی چارت موردنظر بیندازید و `Algo Trading` را فعال کنید.
6. ابتدا همه مراحل را روی Demo انجام دهید.

> فایل EX5 داخل مخزن قرار نگرفته تا کاربر آن را با MetaEditor و Build ترمینال خودش کامپایل کند.

## آشنایی با پنل

پنل چهار تب دارد:

| تب | کاربرد |
| --- | --- |
| `TRADE` | ریسک، R:R، ورود Market و طراحی Limit |
| `MANAGE` | وضعیت Guard، Break-even، خروج پله‌ای، بستن و Reverse |
| `NEWS` | اخبار امروز با ساعت تهران و سطح اهمیت |
| `CHART` | تم تیره/روشن، سشن‌ها و تایمر کندل |

برای جابه‌جایی پنل، ناحیه عنوان `ARKORISK MT5` را بکشید. جابه‌جایی فقط اشیای خود پنل را حرکت می‌دهد؛ خطوط معامله هنگام Drag پنل موقتاً غیرفعال و بعد از رهاکردن ماوس دوباره آزاد می‌شوند. دکمه `−` پنل را جمع می‌کند.

## معامله Market

1. Risk و RR را در تب TRADE تنظیم کنید.
2. جهت را با `BUY NOW` یا `SELL NOW` انتخاب کنید.
3. اکسپرت پیش از ارسال موارد زیر را بررسی می‌کند:
   - فعال بودن مجوز معامله و وضعیت Guard
   - محدودیت Spread، تعداد Position و تعداد معامله روزانه
   - News Pause و Hedge Policy
   - ریسک باز و وجود SL
4. Stopها بر اساس فاصله پیش‌فرض ATR یا خطوط معتبر فعلی ساخته می‌شوند.

در نسخه 1.40، ATR مستقیماً از کندل‌های بسته محاسبه می‌شود و به Indicator Handle وابسته نیست. Stopهای Market بر اساس Tick Size، Bid/Ask صحیح و فاصله امن بروکر رو به بیرون نرمال می‌شوند. اگر بروکر با وجود این کار `Invalid Stops` برگرداند، فقط یک بار با Tick تازه و فاصله بیشتر Retry انجام می‌شود.

## معامله Limit و خطوط

### ساخت سفارش

1. `BUY LIMIT` یا `SELL LIMIT` را بزنید.
2. سه خط روی چارت ساخته می‌شود:
   - آبی: `ENTRY`
   - قرمز: `STOP LOSS`
   - سبز: `TAKE PROFIT`
3. هر خط را مستقیم بکشید. خطوط در حالت پیش‌فرض Selected هستند تا Drag با یک حرکت انجام شود.
4. پیش‌نمایش Lot، Risk، Target و R:R را بررسی کنید.
5. `PLACE BUY LIMIT` یا `PLACE SELL LIMIT` را بزنید.

### کنترل خطوط

- `LINES FREE`: خطوط قابل انتخاب و Drag هستند.
- `UNLOCK`: خطوط قفل‌اند؛ با این دکمه آزادشان کنید.
- `RR LINK`: با حرکت Entry یا SL، خط TP بر اساس R:R به‌روزرسانی می‌شود.
- `FREE LINES`: هر سه خط مستقل حرکت می‌کنند.
- `DELETE`: سه خط و متن‌های پیش‌نمایش را حذف می‌کند.
- `RESET`: خطوط را بر اساس قیمت و ATR فعلی دوباره می‌چیند.
- `CANCEL`: سفارش‌های Pending تحت مدیریت را لغو می‌کند.

اگر `InpLockDesignerLinesOnStart=true` باشد، خطوط هنگام شروع قفل‌اند. اگر `InpKeepLimitLinesSelected=false` باشد، ممکن است برای شروع Drag لازم باشد ابتدا خط را انتخاب کنید.

## مدیریت سرمایه

`InpRiskMode` چهار حالت دارد:

| حالت | مبنای محاسبه |
| --- | --- |
| `RP_BALANCE_PERCENT` | درصدی از Balance |
| `RP_EQUITY_PERCENT` | درصدی از Equity |
| `RP_FIXED_MONEY` | زیان پولی ثابت در ارز حساب |
| `RP_FIXED_LOT` | حجم لات ثابت |

حجم بر اساس فاصله Entry تا SL و Tick Value نماد محاسبه و با Min/Max/Step حجم بروکر نرمال می‌شود. وقتی حجم حداقل بروکر بیشتر از حجم مجاز ریسک باشد، سفارش به‌صورت پیش‌فرض مسدود می‌شود؛ فعال‌کردن `InpAllowMinimumLotRiskOverflow` این محافظ را کنار می‌زند و باید با احتیاط انجام شود.

`InpMaxOpenRiskPercent` مجموع ریسک باز Positionها و Pendingهای تحت Scope را محدود می‌کند. اگر Position بدون SL شناسایی شود و `InpBlockForPositionWithoutSL=true` باشد، ورود جدید مسدود می‌شود.

## مدیریت خودکار پوزیشن

مدیریت خودکار فقط Positionهای دارای Magic Number اکسپرت را پوشش می‌دهد، مگر اینکه `InpManageManualPositions=true` شود.

### Auto Break-even

- فعال‌سازی: `InpUseBreakEven`
- نوع تریگر: R یا Pip
- انتقال SL به Entry پس از `InpBreakEvenAtR` یا `InpBreakEvenAtPips`
- قفل سود با `InpBreakEvenLockPips` و بافر Points

### Partial Close

- فعال‌سازی: `InpUsePartialClose`
- تریگر بر اساس R یا Pip
- درصد خروج: `InpPartialClosePercent`
- فقط یک بار برای هر Position اجرا می‌شود و حجم با Step بروکر هماهنگ می‌گردد.

### Trailing Stop

- فعال‌سازی: `InpUseTrailing`
- شروع، فاصله و Step جداگانه در حالت R یا Pip
- Stop فقط در جهت کاهش ریسک حرکت می‌کند.

### دکمه‌های سریع

- `BREAK EVEN`: انتقال فوری SL پوزیشن‌های قابل مدیریت به نقطه ورود
- `CLOSE 50%`: بستن نیمی از حجم با رعایت حداقل و Step بروکر
- `CLOSE PROFIT`: بستن فقط پوزیشن‌های سودده
- `CLOSE LOSS`: بستن فقط پوزیشن‌های زیان‌ده
- `REVERSE SAME LOT`: بستن پوزیشن فعلی و بازکردن جهت مخالف با حجم تجمیع‌شده
- `EMERGENCY CLOSE`: بستن همه Positionهای تحت مدیریت

## محافظ حساب و پراپ

Scope محافظ روزانه با `InpDailyGuardScope` تعیین می‌شود:

- `RP_SCOPE_EA_SYMBOL`: فقط Magic Number و نماد چارت
- `RP_SCOPE_EA_ALL`: همان Magic Number در تمام نمادها
- `RP_SCOPE_ACCOUNT`: کل حساب

قابلیت‌های اصلی:

- `Max Daily Loss` به درصد Balance ابتدای روز یا مبلغ ثابت
- `Daily Profit Target` به درصد یا مبلغ ثابت
- امکان محاسبه Floating P/L در نتیجه روزانه
- بستن Position و لغو Pending هنگام فعال‌شدن Guard
- قفل ورود تا شروع روز بعد سرور
- Max Daily Trades، Max Open Positions و Max Pending Orders
- One Position Per Symbol
- حذف Pendingهای قدیمی پس از تعداد دقیقه تعیین‌شده
- Max Spread Filter بر حسب Point

قوانین پراپ‌فرم‌ها یکسان نیستند. بعضی شرکت‌ها Equity، بعضی Balance و بعضی زمان یا Reset روزانه متفاوت دارند؛ Inputها را دقیقاً مطابق قرارداد حساب خود تنظیم کنید.

## اخبار و ساعت تهران

تب NEWS از Economic Calendar خود MetaTrader استفاده می‌کند و زمان را با `InpTehranUTCOffsetMinutes=210` به UTC+03:30 تبدیل می‌کند. هر خبر دارای Currency، Time، Impact و عنوان است.

`News Auto-Pause` دکمه‌های ورود را در بازه X دقیقه قبل و بعد از رویداد High Impact غیرفعال می‌کند. اگر `InpNewsPauseCurrentSymbolOnly=true` باشد، فقط ارز پایه و ارز سود نماد بررسی می‌شوند.

تقویم اقتصادی ممکن است در Strategy Tester، بعضی بروکرها یا زمان نبود اتصال در دسترس نباشد. رفتار اکسپرت با `InpBlockIfCalendarUnavailable` مشخص می‌شود.

## هج، ژورنال و اسکرین‌شات

### Hedge Policy

- `RP_HEDGE_WARN`: کلیک اول هشدار می‌دهد؛ برای تأیید باید در بازه تعیین‌شده دوباره کلیک کنید.
- `RP_HEDGE_BLOCK`: ورود مخالف Position/Pending موجود را مسدود می‌کند.
- `RP_HEDGE_ALLOW`: بدون هشدار اجازه می‌دهد.

این کنترل فقط در حساب Hedging معنا دارد. در Netting، ورود مخالف معمولاً Position موجود را کم یا معکوس می‌کند.

### اسکرین‌شات ژورنال

وقتی `InpTakeEntryScreenshot=true` باشد، پس از ثبت Deal ورودی یک اسکرین‌شات ذخیره می‌شود. محل پیش‌فرض:

```text
MQL5/Files/ArkoRisk/Journal/
```

نام فایل شامل زمان، نماد و شماره Deal است. ثبت اسکرین‌شات خارج از `OnTradeTransaction` صف‌بندی می‌شود تا مسیر ارسال معامله سبک بماند. این فایل‌ها محلی هستند و خود اکسپرت آن‌ها را آپلود نمی‌کند.

## تم، سشن و تایمر کندل

- تم `DARK` و `LIGHT` رنگ‌های مناسب ترید را روی چارت اعمال می‌کنند.
- `ORIGINAL` رنگ‌های ذخیره‌شده پیش از اجرای اکسپرت را برمی‌گرداند.
- سشن‌های Sydney، Tokyo، London و New York با خط و Label روی چارت نمایش داده می‌شوند.
- در صورت فعال‌بودن Auto DST، ساعت تابستانی London/New York به‌صورت تقویمی محاسبه می‌شود.
- Candle Countdown کنار کندل جاری باقی‌مانده زمان را متناسب با تایم‌فریم نشان می‌دهد و در 30 و 10 ثانیه آخر تغییر رنگ می‌دهد.

## Inputها

### Core Risk

- `InpMagicNumber`: شناسه معاملات ArkoRisk
- `InpRiskMode`: حالت محاسبه حجم
- `InpDefaultRiskPercent`, `InpFixedRiskMoney`, `InpFixedLot`: مقدار پیش‌فرض ریسک
- `InpDefaultRR`: نسبت سود به زیان پیش‌فرض
- `InpMaxOpenRiskPercent`: سقف مجموع ریسک باز

### Fast Order Designer

- `InpATRPeriod`, `InpDefaultSL_ATR`, `InpLimitGap_ATR`: فاصله اولیه خطوط
- `InpMinimumSLPoints`: حداقل فاصله داخلی SL
- `InpAutoTPFromRR`: اتصال TP به RR
- `InpKeepLimitLinesSelected`: Selected ماندن خطوط برای Drag سریع
- `InpLockDesignerLinesOnStart`: قفل خطوط در شروع
- `InpMaxSpreadPoints`: سقف Spread؛ صفر یعنی غیرفعال
- `InpDeviationPoints`: Deviation ارسال سفارش

### Automatic Management

Inputهای Break-even، Partial و Trailing هر کدام Enable، Trigger Mode، آستانه و فاصله مخصوص دارند. مقدار Pip با Digits نماد تطبیق داده می‌شود.

### Guard, News, Hedge, Journal

همه قابلیت‌های حساس Enable جداگانه دارند. پیشنهاد می‌شود فقط گزینه‌هایی را روشن کنید که منطقشان با قوانین حساب شما کاملاً تطبیق دارد.

## چک‌لیست پیش از حساب واقعی

- [ ] Compile بدون Error انجام شده است.
- [ ] فایل Icon در مسیر `MQL5/Images/ArkoRisk` قرار دارد.
- [ ] Magic Number روی چند چارت تداخل ناخواسته ندارد.
- [ ] Risk Mode و درصد/مبلغ ریسک کنترل شده است.
- [ ] Daily Guard مطابق Timezone و تعریف Drawdown پراپ تنظیم شده است.
- [ ] Max Spread با Points نماد و شرایط بازار تناسب دارد.
- [ ] News Pause روی دیتای بروکر تست شده است.
- [ ] رفتار Hedge/Netting حساب مشخص است.
- [ ] حجم Min/Step و Stop Level نماد در Demo تست شده است.
- [ ] مسیر اسکرین‌شات و فضای دیسک بررسی شده است.
- [ ] یک Market و یک Limit کوچک روی Demo با موفقیت اجرا شده است.

برای خطاها و پیام‌های رایج به [راهنمای رفع اشکال](TROUBLESHOOTING_FA.md) مراجعه کنید.

