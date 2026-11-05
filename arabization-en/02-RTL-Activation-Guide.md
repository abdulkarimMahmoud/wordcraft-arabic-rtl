# دليل تفعيل العربية و RTL في WordCraft

## للمستخدم العادي (بدون بناء)

### الطريقة 1 — من داخل التطبيق (موصى بها)
1. افتح WordCraft
2. `ملف › خيارات › لغة الواجهة` (File › Options › Interface language)
3. اختر **العربية — Arabic**
4. أعد تشغيل التطبيق
5. ستجد:
   - الشريط يبدأ من اليمين: `ملف | الصفحة الرئيسية | إدراج | رسم | تصميم | تخطيط | مراجع | مراسلات | مراجعة | عرض`
   - لوحة التنقل على اليمين
   - مربعات الحوار: التسميات يمين والحقول يسار

### الطريقة 2 — متغير البيئة (للاختبار السريع)
```bash
WORDCRAFT_LANGUAGE=ar wordcraft
# أو
WORDCRAFT_LANGUAGE=ar wordcraft document.docx
```

### الطريقة 3 — لغة النظام
- غيّر لغة النظام إلى العربية وأعد التشغيل — WordCraft يتبعها تلقائياً (`auto`).

---

## للمطور — بناء نسخة عربية

```bash
# 1) جهّز craft-i18n
git clone https://github.com/storytold/craft-i18n /tmp/craft-i18n
git -C /tmp/craft-i18n checkout 9d6d54d  # أو أحدث

# 2) ابنِ وشغّل بالعربية
CRAFT_I18N_DIR=/tmp/craft-i18n WORDCRAFT_LANGUAGE=ar cargo run --release -p wordcraft -- --sample

# 3) تحقّق من الترجمة
cargo xtask i18n-report  # يطبع نسبة الترجمة لكل لغة

# 4) ابنِ كل المنصات
CRAFT_I18N_DIR=/tmp/craft-i18n cargo build --release -p wordcraft
CRAFT_I18N_DIR=/tmp/craft-i18n cargo build --release -p wordcraft-cli
```

---

## كتابة مستند عربي صحيح

### مستند جديد
- بعد التصحيح البرمجي، أي مستند جديد مع واجهة عربية يبدأ `ar-SA` تلقائياً.
- للتحقق: `wordcraft-cli inspect doc.docx | grep lang`

### تنسيق الفقرة
- `الصفحة الرئيسية › فقرة › محاذاة`:
  - `محاذاة إلى اليمين` — للعربية
  - `توسيط` — للعناوين
  - `ضبط` — للنص الطويل (يوزع الكلمات)
- `تخطيط › اتجاه النص` — يغير `w:textDirection` للقسم

### نص مختلط (عربي + إنجليزي + أرقام)
```
WordCraft يدعم العربية و English في نفس السطر 123
مرحباً World 2026 — اختبار Bidi
```
- المحرك يطبق UAX #9 تلقائياً — لا تحتاج لوسوم يدوية.
- لتحديد اتجاه الفقرة يدوياً: عدّل `w:bidi` في DOCX أو استخدم `Review › Language`.

---

## إضافة التدقيق الإملائي العربي

WordCraft لا يضم قاموساً عربياً (الترخيص). ثبّت واحداً:

### Linux (Ubuntu/Debian)
```bash
sudo apt install hunspell-ar
# أو حمّل من LibreOffice:
# https://github.com/LibreOffice/dictionaries
```

### macOS
```bash
brew install hunspell
# ضع ar_SA.dic و ar_SA.aff في ~/Library/Spelling/
```

### Windows
- ضع `ar_SA.dic` و `ar_SA.aff` في مجلد تختاره، ثم:
  `ملف › خيارات › تدقيق › مجلد القواميس` وأشر إليه.

بعد التثبيت، `مراجعة › اللغة › تعيين لغة التدقيق › العربية (السعودية)` ستبدأ بوضع خطوط حمراء.

---

## استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| الواجهة ما زالت إنجليزية | تأكد أن البناء تم مع `CRAFT_I18N_DIR` — بدونه يبقى إنجليزي فقط |
| النص العربي يظهر مربعات □ | ثبّت خطاً عربياً: `sudo apt install fonts-noto-core fonts-amiri` |
| الكتابة تبدأ من اليسار | تأكد أن `editing_lang` هو `ar-SA` — أنشئ مستنداً جديداً بعد تغيير اللغة |
| الأرقام تظهر إنجليزية | طبيعي — Word العربي يستخدم Western digits افتراضياً. للهندية غيّر `ملف › خيارات › خيارات متقدمة › إظهار أرقام المستند` |

---

## اختبار RTL برمجياً

```bash
# فحص أن الانعكاس يعمل:
cargo test -p wordcraft-ui-egui rtl -- --nocapture
# يجب أن يمر: a_form_row_puts_the_label_at_the_reading_start

# فحص Bidi:
cargo test -p wordcraft-doc bidi -- --nocapture
cargo test -p wordcraft-docx bidi -- --nocapture

# فحص شامل:
cargo xtask ci  # يفشل إذا كُسر RTL
```
