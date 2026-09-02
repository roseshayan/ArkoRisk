# ArkoRisk MT5

یک اکسپرت رایگان و متن‌باز برای **مدیریت سرمایه، سفارش و پوزیشن در MetaTrader 5**؛ طراحی‌شده برای اجرای سریع معاملات اسکلپ، سفارش‌های Limit و حساب‌های پراپ‌فرم.

> ArkoRisk سیگنال معاملاتی تولید نمی‌کند. این پروژه ابزار اجرای معامله و کنترل ریسک است و باید پیش از استفاده واقعی روی حساب دمو آزمایش شود.

## امکانات اصلی

- محاسبه حجم بر پایه درصد Balance، درصد Equity، مبلغ ثابت یا لات ثابت
- طراح Buy/Sell Limit با خطوط قابل جابه‌جایی Entry، SL و TP
- قفل، آزادسازی و حذف مستقل خطوط طراح سفارش
- پیش‌نمایش زنده حجم، سود/زیان دلاری و ضریب R:R روی چارت
- **Smart Break-even** با لحاظ اسپرد لحظه‌ای، کمیسیون/Fee، Swap منفی و Buffer قابل تنظیم
- Break-even، Save Profit / Partial Close و Trailing Stop با تریگر Pip یا R و کنترل Runtime از پنل
- روشن/خاموش کردن توقف معامله هنگام خبر و تنظیم بازه قبل/بعد خبر از پنل
- سیاست Hedge قابل تغییر از پنل: `WARN / ALLOW / BLOCK`
- Overtrading Guard قابل روشن/خاموش شدن با Max Trades / Positions / Pending
- مدیریت معاملات دستی `Magic=0` در کنار معاملات خود ArkoRisk
- Max Daily Loss و Daily Profit Target با **مرز روز تهران** به‌جای نیمه‌شب بروکر
- نمایش اخبار، روزها و سشن‌ها بر مبنای ساعت تهران `UTC+03:30`
- Close Profit، Close Loss، Emergency Close و Reverse با همان حجم
- اسکرین‌شات خودکار ورود و اسکرین‌شات دستی برای ژورنال
- گروه‌بندی تصاویر ژورنال بر اساس تاریخ تهران
- تایمر بسته‌شدن کندل، تم تیره/روشن و مارکر سشن‌های فارکس
- پنل مینیمال، جمع‌شونده و قابل جابه‌جایی به همراه پنل Runtime در تب Manage

## نصب سریع

1. پکیج کامل پروژه را دانلود کنید؛ نسخه 1.50 چند فایل داخلی دارد و دانلود تنها `ArkoRisk.mq5` کافی نیست.
2. در MetaTrader 5 از منوی `File → Open Data Folder` وارد پوشه داده شوید.
3. محتوای پوشه [`MQL5`](MQL5) این مخزن را داخل پوشه `MQL5` ترمینال کپی کنید.
4. فایل `MQL5/Experts/ArkoRisk/ArkoRisk.mq5` را در MetaEditor باز و Compile کنید.
5. در Navigator روی Expert Advisors راست‌کلیک و `Refresh` را بزنید.
6. ArkoRisk را روی چارت بیندازید و Algo Trading را فعال کنید.

راهنمای کامل نصب، ورودی‌ها و همه قابلیت‌ها در [مستندات فارسی](docs/USER_GUIDE_FA.md) آمده است. توضیحات کنترل‌های نسخه 1.50 نیز در [V150_RUNTIME_CONTROLS_FA.md](docs/V150_RUNTIME_CONTROLS_FA.md) قرار دارد.

## نسخه 1.50

نسخه 1.50 منطق تست‌شده 1.40 را در `ArkoRiskCore.mqh` نگه می‌دارد و لایه Runtime جدید را در `ArkoRiskV150.mqh` روی آن قرار می‌دهد. فایل `ArkoRisk.mq5` ورودی رسمی Expert است.

### Smart Break-even

Break-even دیگر صرفاً Stop Loss را روی Entry قرار نمی‌دهد. در صورت فعال بودن گزینه‌های v1.50، فاصله محافظتی می‌تواند شامل موارد زیر باشد:

- اسپرد زنده `Ask - Bid` هنگام اعمال ریسک‌فری
- کمیسیون و Fee ثبت‌شده روی Position
- تخمین هزینه سمت خروج از تاریخچه همان Symbol
- مقدار دستی `InpV150CommissionPerLotRoundTurn` برای بروکرهایی که تاریخچه هزینه قابل اتکا نمی‌دهند
- Swap منفی باز
- Lock Pips، `InpBreakEvenPlusPoints` و Buffer اضافه v1.50

این محاسبه احتمال بسته‌شدن خالص مثبت در Break-even را بیشتر می‌کند، اما **سود مثبت را تضمین نمی‌کند**؛ Gap، Slippage و Spread widening در لحظه اجرای Stop می‌توانند قیمت نهایی را تغییر دهند.

## ساختار مخزن

```text
MQL5/Experts/ArkoRisk/ArkoRisk.mq5       ورودی رسمی اکسپرت
MQL5/Experts/ArkoRisk/ArkoRiskV150.mqh   لایه Runtime نسخه 1.50
MQL5/Experts/ArkoRisk/ArkoRiskCore.mqh   هسته پایدار نسخه 1.40
MQL5/Images/ArkoRisk/ArkoRisk.ico        آیکون داخل MetaTrader
docs/USER_GUIDE_FA.md                    راهنمای کامل فارسی
docs/V150_RUNTIME_CONTROLS_FA.md         راهنمای قابلیت‌های 1.50
docs/TROUBLESHOOTING_FA.md               رفع اشکال
index.html                                لندینگ‌پیج GitHub Pages
assets/                                   هویت بصری و فایل‌های سایت
```

## انتشار و مشارکت

پروژه با مجوز [MIT](LICENSE) منتشر شده است. پیش از Pull Request، راهنمای [CONTRIBUTING](CONTRIBUTING.md) را بخوانید. برای انتشار Release نیز [چک‌لیست انتشار](docs/PUBLISH_GITHUB_FA.md) آماده است.

## نویسنده

**Shayan Namayandeh** — `SudoShayanNA`

- GitHub: [@ArkoRisk](https://github.com/roseshayan/ArkoRisk)
- Telegram: [@SudoShayanNA](https://t.me/SudoShayanNA)
- Email: [namayandeshayan@gmail.com](mailto:namayandeshayan@gmail.com)

## سلب مسئولیت

معامله در بازارهای مالی با ریسک از دست‌دادن سرمایه همراه است. عملکرد صحیح نرم‌افزار جایگزین تصمیم معاملاتی، بررسی قوانین بروکر یا قوانین پراپ‌فرم نیست. هیچ تضمینی درباره سودآوری یا پذیرش در یک پراپ‌فرم خاص وجود ندارد.
