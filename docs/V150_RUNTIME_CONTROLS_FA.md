# ArkoRisk MT5 v1.50 — کنترل‌های Runtime و Smart Break-even

این نسخه برای انتقال تنظیمات پرکاربرد از Expert Properties به پنل روی چارت طراحی شده است.

## Smart Break-even

ریسک‌فری دیگر صرفاً SL را روی قیمت ورود قرار نمی‌دهد. در صورت فعال بودن گزینه‌ها، فاصله محافظتی از این موارد تشکیل می‌شود:

- اسپرد زنده Ask-Bid در همان لحظه اعمال Break-even.
- کمیسیون و Fee ثبت‌شده برای Position.
- تخمین کمیسیون سمت خروج بر اساس تاریخچه همان Symbol.
- در صورت تعریف `InpCommissionPerLotRoundTurn`، مقدار دستی کمیسیون Round-turn به ازای یک لات به‌عنوان حداقل هزینه کل در نظر گرفته می‌شود.
- Swap منفی باز نیز برای جلوگیری از بسته‌شدن خالص منفی لحاظ می‌شود.
- `InpBreakEvenPlusPoints` و Lock Pips به‌عنوان buffer اضافه باقی می‌مانند.

این محاسبه تضمین قطعی سود مثبت نیست، چون Slippage، Gap و Spread widening لحظه اجرای Stop قابل تضمین نیست؛ هدف این است که SL ریسک‌فری با حاشیه هزینه واقعی قرار بگیرد.

## کنترل‌های پنل

- Risk Free: روشن/خاموش، R/Pips، Trigger و Lock.
- Save Profit: روشن/خاموش، R/Pips، Trigger و درصد Partial Close.
- Trailing: روشن/خاموش، R/Pips، Start، Distance و Step.
- News: `NEWS BLOCK` یا `NEWS ALLOW` و زمان قبل/بعد خبر.
- Hedge: چرخه `WARN → ALLOW → BLOCK`.
- Manual: مدیریت معاملات Magic=0.
- Overtrading: روشن/خاموش و Max trades / Max positions / Max pending.
- Journal: ثبت Screenshot با تاریخ و ساعت تهران و Screenshot دستی.

## زمان تهران

- Daily statistics و Daily Guard از نیمه‌شب تهران محاسبه می‌شوند.
- مرز روزها روی چارت با نام روز و تاریخ تهران رسم می‌شود.
- Screenshot journal با تاریخ/ساعت تهران دسته‌بندی می‌شود.
- Session و News همان منطق تهران را حفظ می‌کنند.
