# رفع اشکال ArkoRisk MT5

## `automated trading is disabled because the account has been changed`

این پیام از خود MetaTrader 5 است، نه ArkoRisk. ترمینال هنگام تغییر حساب برای امنیت Algo Trading را غیرفعال می‌کند. پس از اطمینان از حساب فعال، دکمه Algo Trading را دوباره روشن کنید. در تنظیمات Expert Advisors نیز گزینه غیرفعال‌شدن خودکار هنگام تغییر Account/Profile را بررسی کنید.

## `cannot load indicator 'Average True Range' ... [4805]`

نسخه 1.40 دیگر `iATR` یا Indicator Handle ایجاد نمی‌کند و ATR را از کندل‌های بسته محاسبه می‌کند. اگر این پیام را می‌بینید:

1. مطمئن شوید فایل نسخه 1.40 را Compile کرده‌اید.
2. EX5 قدیمی را از Navigator حذف/Refresh کنید.
3. نسخه اکسپرت روی چارت را Remove و دوباره Attach کنید.

در نبود تاریخچه کافی، ArkoRisk موقتاً از فاصله امن جایگزین استفاده می‌کند و پس از دریافت کندل‌ها ATR محلی در دسترس می‌شود.

## `invalid stops`

نسخه 1.40 مرجع Stop را اصلاح کرده است: SL خرید از Bid، TP خرید از Ask، SL فروش از Ask و TP فروش از Bid سنجیده می‌شود. قیمت‌ها رو به بیرون با Tick Size نرمال می‌شوند و یک بافر Stop/Freeze دارند.

اگر خطا ادامه داشت:

- مشخصات نماد و `Stops level` را بررسی کنید.
- فاصله SL را بیشتر کنید؛ بعضی بروکرها Stop Level پویا دارند.
- در زمان Spread شدید، خبر یا بازشدن بازار سفارش نفرستید.
- Digits و Tick Size نمادهای پسونددار مانند `XAUUSD.` را بررسی کنید.
- Journal و Experts را برای Retcode نهایی بخوانید.

ArkoRisk فقط یک Retry با Tick تازه انجام می‌دهد و وارد حلقه ارسال تکراری نمی‌شود.

## خطوط Limit حرکت نمی‌کنند

1. در تب TRADE دکمه باید `LINES FREE` باشد. اگر `UNLOCK` می‌بینید، آن را بزنید.
2. روی `BUY LIMIT` یا `SELL LIMIT` بزنید تا خطوط تازه ساخته شوند.
3. خط را خارج از محدوده پنل بکشید.
4. Inputهای زیر را بررسی کنید:
   - `InpLockDesignerLinesOnStart=false`
   - `InpKeepLimitLinesSelected=true`
5. اگر پنل را جابه‌جا کرده‌اید، ماوس را رها کنید؛ نسخه 1.40 خطوط را در رویداد Release و یک Timeout محافظ دوباره فعال می‌کند.

## پنل یا خطوط لرزش دارند

- پنل را فقط از ناحیه عنوان بکشید.
- هنگام حرکت پنل، خطوط عمداً موقتاً غیرقابل انتخاب می‌شوند.
- تعداد Indicatorها و اشیای سنگین چارت را کاهش دهید.
- اگر VPS ضعیف است، Session Lookback و Preview Label را سبک‌تر کنید.

## اخبار نمایش داده نمی‌شوند

- اتصال ترمینال و Economic Calendar را بررسی کنید.
- بعضی بروکرها یا محیط Strategy Tester تقویم را ارائه نمی‌کنند.
- `InpEnableEconomicCalendar=true` باشد.
- `InpBlockIfCalendarUnavailable` فقط زمانی روشن شود که می‌خواهید نبود تقویم تمام ورودها را مسدود کند.

## اسکرین‌شات ساخته نمی‌شود

- `InpTakeEntryScreenshot=true` باشد.
- Deal باید با Magic Number/Scope مناسب شناسایی شود.
- پوشه `MQL5/Files/ArkoRisk/Journal` و دسترسی نوشتن ترمینال را بررسی کنید.
- اندازه Screenshot را متناسب با محیط/VPS کاهش دهید.

## Partial Close اجرا نمی‌شود

- حساب و نماد باید Partial Close را پشتیبانی کنند.
- حجم باقی‌مانده نباید زیر `SYMBOL_VOLUME_MIN` باشد.
- Trigger مربوط به R یا Pip باید واقعاً رسیده باشد.
- `InpManageManualPositions` برای معاملات دستی به‌صورت پیش‌فرض خاموش است.

## Compile هشدار Icon می‌دهد

محتوای پوشه MQL5 مخزن را کامل کپی کنید تا فایل زیر موجود باشد:

```text
MQL5/Images/ArkoRisk/ArkoRisk.ico
```

سورس از مسیر `\\Images\\ArkoRisk\\ArkoRisk.ico` استفاده می‌کند.

