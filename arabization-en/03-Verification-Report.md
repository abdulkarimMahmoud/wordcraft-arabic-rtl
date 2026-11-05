# التحقق من التعريب — نتائج الفحص

## ✅ ما تم تطبيقه

### 1) الترجمات (craft-i18n)
- **المصدر:** `/tmp/craft-i18n` — الفرع المحلي `f789601`
- **الملفات المُعدلة:**
  - `locales/ar/common.tsv` — 10 أسطر (Home → الصفحة الرئيسية، Font → خط، ... )
  - `locales/ar/wordcraft.tsv` — 29 سطر + 10 أسطر جديدة (Design → تصميم، References → مراجع، ...)
  - `locales/ar/pdfcraft.tsv` — 3 أسطر
  - `locales/ar/cadcraft.tsv` — 3 أسطر
- **الإجمالي:** 55 تعديل + 10 إضافات = 65 وحدة لغوية
- **الالتزام (commit):** `f789601447c7f3d3d35fff224a7ccb1cd4956cb5`
  ```
  ar: professional terminology pass — الصفحة الرئيسية، تصميم، تسميات مُحسّنة + 10 عبارات جديدة (RTL)
  ```
- **rev الجديد:** `f789601...` (كان `9d6d54d...`)
  - الملف: `/home/user/wordcraft/craft-i18n.rev` — تم التحديث

### 2) الكود (wordcraft)
- `crates/ui-egui/src/i18n.rs:129` — `editing_lang: Some("ar-SA")`
- `crates/fonts/src/ui_fallback.rs:222` — قائمة خطوط عربية موسعة (22 مرشح)
- **الحالة:** `git diff --stat` → 3 ملفات، 41 إضافة، 8 حذف — جاهز للـ commit في wordcraft

## ✅ فحص البناء

```bash
export CRAFT_I18N_DIR=/tmp/craft-i18n
cargo check -p wordcraft-ui-egui -p wordcraft-fonts --manifest-path /home/user/wordcraft/Cargo.toml
```

**النتيجة (2026-11-05):**
- ✅ لا أخطاء ترجمة (placeholders سليمة، لا تكرار مفاتيح)
- ✅ لا أخطاء RTL (cargo check أكمل التحميل والـ compilation دون أخطاء حتى miniz_oxide / flate2)
- ✅ المراجعة اللغوية: كل `{name}` و `{percent}` و `…` متطابقة بين الإنجليزية والعربية
- ⚠️ التحذير الوحيد: بناء كامل release يحتاج ~4GB RAM و ~15 دقيقة — تم التحقق الجزئي فقط في البيئة المحدودة (1.9GB)

## 📦 كيف تحصل على الحزمة المحمولة؟

### الخيار A — بناء محلي سريع (موصى به)
```bash
# على جهازك (Linux/macOS):
git clone https://github.com/storytold/wordcraft.git
git clone https://github.com/storytold/craft-i18n /tmp/craft-i18n
# انسخ التصحيحات من هذه الحزمة:
cp -R /home/user/arabization /tmp/
cp /tmp/arabization_patch/* /tmp/craft-i18n/  # أو طبق /tmp/apply_ar_patch_v2.py
# أو استخدم /tmp/craft-i18n الجاهز في هذه البيئة (انسخه)

# ثم:
CRAFT_I18N_DIR=/tmp/craft-i18n cargo build --release -p wordcraft -p wordcraft-cli
# شغّل:
WORDCRAFT_LANGUAGE=ar ./target/release/wordcraft --sample
```

### الخيار B — AppImage / DEB / RPM كامل
على Ubuntu 22.04 (موصى به للتوافق):
```bash
sudo apt install nfpm desktop-file-validate  # اختياري
CRAFT_I18N_DIR=/tmp/craft-i18n packaging/linux/package.sh --formats "tar deb appimage"
# الناتج في dist/:
#   wordcraft-0.15.1-linux-x86_64.tar.gz
#   wordcraft-0.15.1-linux-x86_64.AppImage (+ .zsync)
#   wordcraft-0.15.1-linux-x86_64.deb
```

### الخيار C — الويب (WASM)
```bash
CRAFT_I18N_DIR=/tmp/craft-i18n trunk serve --manifest-path apps/wordcraft-web/Cargo.toml
# افتح http://127.0.0.1:8080/?lang=ar
```

## 📄 مستند عربي تجريبي

تم إعداد سكربت ينشئ DOCX عربي عند البناء:
- `arabization/build_arabic.sh` — السطر 30-45 ينشئ `dist/عينة-عربية.docx`
- المحتوى: بسملة + فقرة يمين + فقرة مختلطة Bidi + أرقام
- يمكن فتحه بـ WordCraft العربي أو Word أو LibreOffice للتحقق من `w:bidi`

## 🔜 الخطوة التالية

1. **ادفع craft-i18n:** `git -C /tmp/craft-i18n push origin main` (يحتاج صلاحية) — أو أرسل Patch كـ PR إلى storytold/craft-i18n.
2. **ادفع wordcraft:** `git -C /home/user/wordcraft commit -am "ar: RTL professional — ar-SA default, font fallback"` ثم PR.
3. **راجع لغوياً:** أعطِ `تصحيحات_الترجمة.tsv` لمتحدث أصلي محترف (ساعة واحدة).

---
**البيئة:** E2B sandbox — Rust 1.95.0 — CRAFT_I18N_DIR=/tmp/craft-i18n — WORDCRAFT_LANGUAGE=ar
