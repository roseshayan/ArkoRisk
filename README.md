# ArkoRisk MT5

یک اکسپرت رایگان و متن‌باز برای **مدیریت سرمایه، سفارش و پوزیشن در MetaTrader 5**؛ طراحی‌شده برای اجرای سریع معاملات اسکلپ، سفارش‌های Limit و حساب‌های پراپ‌فرم.

> ArkoRisk سیگنال معاملاتی تولید نمی‌کند. این پروژه ابزار اجرای معامله و کنترل ریسک است و باید پیش از استفاده واقعی روی حساب دمو آزمایش شود.

## امکانات اصلی

- محاسبه حجم بر پایه درصد Balance، درصد Equity، مبلغ ثابت یا لات ثابت
- طراح Buy/Sell Limit با خطوط قابل جابه‌جایی Entry، SL و TP
- قفل، آزادسازی و حذف مستقل خطوط طراح سفارش
- پیش‌نمایش زنده حجم، سود/زیان دلاری و ضریب R:R روی چارت
- Break-even خودکار، Partial Close و Trailing Stop با تریگر پیپ یا R
- Max Daily Loss، Daily Profit Target، Max Spread و محدودیت تعداد معاملات
- Close Profit، Close Loss، Emergency Close و Reverse با همان حجم
- نمایش اخبار روز با ساعت تهران و توقف ورود اطراف اخبار High Impact
- هشدار/مسدودسازی Hedge برای حساب‌ها و پراپ‌فرم‌های حساس به هج
- اسکرین‌شات خودکار ورود برای ژورنال معاملاتی
- تایمر بسته‌شدن کندل، تم تیره/روشن و مارکر سشن‌های فارکس
- پنل مینیمال، جمع‌شونده و قابل جابه‌جایی

## نصب سریع

1. در MetaTrader 5 از منوی `File → Open Data Folder` وارد پوشه داده شوید.
2. محتوای پوشه [`MQL5`](MQL5) این مخزن را داخل پوشه `MQL5` ترمینال کپی کنید.
3. فایل `MQL5/Experts/ArkoRisk/ArkoRisk.mq5` را در MetaEditor باز و Compile کنید.
4. پوشه `ArkoRisk` در `Images\ArkoRisk` را در `C:\Program Files\MetaTrader 5\MQL5\Images` کپی کنید.
5. در Navigator روی Expert Advisors راست‌کلیک و `Refresh` را بزنید.
6. ArkoRisk را روی چارت بیندازید و Algo Trading را فعال کنید.

راهنمای کامل نصب، ورودی‌ها و همه قابلیت‌ها در [مستندات فارسی](docs/USER_GUIDE_FA.md) آمده است.

## نکته نسخه 1.40

این نسخه مشکل قفل ماندن خطوط پس از جابه‌جایی پنل را رفع می‌کند، ATR را بدون Indicator Handle محاسبه می‌کند تا خطای 4805 روی نمادهای پسونددار ایجاد نشود و Stopهای Market را با Bid/Ask صحیح، Tick Size و فاصله امن بروکر آماده می‌کند. در صورت `Invalid Stops` فقط یک تلاش مجدد کنترل‌شده با قیمت تازه انجام می‌شود.

## ساختار مخزن

```text
MQL5/Experts/ArkoRisk/ArkoRisk.mq5   سورس اکسپرت
MQL5/Images/ArkoRisk/ArkoRisk.ico   آیکون داخل MetaTrader
docs/USER_GUIDE_FA.md                راهنمای کامل فارسی
docs/TROUBLESHOOTING_FA.md           رفع اشکال
index.html                            لندینگ‌پیج GitHub Pages
assets/                               هویت بصری و فایل‌های سایت
```

## انتشار و مشارکت

پروژه با مجوز [MIT](LICENSE) منتشر شده است. پیش از Pull Request، راهنمای [CONTRIBUTING](CONTRIBUTING.md) را بخوانید. برای انتشار اولین Release نیز [چک‌لیست انتشار](docs/PUBLISH_GITHUB_FA.md) آماده است.

## نویسنده

**Shayan Namayandeh** — `SudoShayanNA`

- GitHub: [@ArkoRisk](https://github.com/roseshayan/ArkoRisk)
- Telegram: [@SudoShayanNA](https://t.me/SudoShayanNA)
- Email: [namayandeshayan@gmail.com](mailto:namayandeshayan@gmail.com)

## سلب مسئولیت

معامله در بازارهای مالی با ریسک از دست‌دادن سرمایه همراه است. عملکرد صحیح نرم‌افزار جایگزین تصمیم معاملاتی، بررسی قوانین بروکر یا قوانین پراپ‌فرم نیست. هیچ تضمینی درباره سودآوری یا پذیرش در یک پراپ‌فرم خاص وجود ندارد.

