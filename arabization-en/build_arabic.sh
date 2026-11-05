#!/usr/bin/env bash
set -euo pipefail
# بناء WordCraft بالعربية — سكربت جاهز للتنفيذ على Linux/macOS/Windows (WSL)
# المتطلبات: Rust 1.95+, cargo, git
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
# أو حدد مجلد craft-i18n المُرقّع
CRAFT_I18N_DIR="${CRAFT_I18N_DIR:-/tmp/craft-i18n}"
VERSION="$(grep -E '^version =' "$ROOT/../wordcraft/Cargo.toml" 2>/dev/null | head -1 | cut -d'"' -f2 || echo "0.15.1")"

echo "==> WordCraft Arabic Build"
echo "    CRAFT_I18N_DIR=$CRAFT_I18N_DIR"
echo "    craft-i18n.rev=$(cat "$ROOT/../wordcraft/craft-i18n.rev" 2>/dev/null || echo "?")"
echo "    WORDCRAFT_LANGUAGE=ar"

if [[ ! -d "$CRAFT_I18N_DIR/locales/ar" ]]; then
  echo "خطأ: لا يوجد $CRAFT_I18N_DIR/locales/ar — استنسخ craft-i18n المُرقّع أولاً"
  echo "  git clone https://github.com/storytold/craft-i18n /tmp/craft-i18n"
  echo "  # ثم طبق patch من arabization/ أو انسخ /tmp/craft-i18n الحالي"
  exit 1
fi

export CRAFT_I18N_DIR
export WORDCRAFT_LANGUAGE=ar

echo "==> 1) فحص سريع (cargo check)..."
cargo check -p wordcraft-ui-egui -p wordcraft-fonts --manifest-path "$ROOT/../wordcraft/Cargo.toml"

echo "==> 2) بناء wordcraft + wordcraft-cli (release)..."
cargo build --release --locked -p wordcraft -p wordcraft-cli --manifest-path "$ROOT/../wordcraft/Cargo.toml"

echo "==> 3) تحقق من اللغة العربية..."
"$ROOT/../wordcraft/target/release/wordcraft-cli" --version
WORDCRAFT_LANGUAGE=ar "$ROOT/../wordcraft/target/release/wordcraft-cli" --help | head -n 20 || true

echo "==> 4) إنشاء مستند عربي تجريبي..."
mkdir -p "$HERE/dist"
cat > /tmp/ar_sample.json << 'JSON'
[
  {"command":"text.insert","params":{"text":"بسم الله الرحمن الرحيم\n"}},
  {"command":"format.bold","params":{"value":true}},
  {"command":"para.align","params":{"align":"center"}},
  {"command":"text.insert","params":{"text":"\nهذا مستند تجريبي باللغة العربية — WordCraft RTL\n"}},
  {"command":"format.bold","params":{"value":false}},
  {"command":"para.align","params":{"align":"right"}},
  {"command":"text.insert","params":{"text":"إن اللغة العربية لغة غنية بمفرداتها وأساليبها. تعكس تاريخاً حضارياً عريقاً يمتد لقرون.\n"}},
  {"command":"text.insert","params":{"text":"Mixed test: WordCraft يدعم العربية و English 123 في نفس السطر.\n"}}
]
JSON
if [[ -x "$ROOT/../wordcraft/target/release/wordcraft-cli" ]]; then
  WORDCRAFT_LANGUAGE=ar "$ROOT/../wordcraft/target/release/wordcraft-cli" run --template blank --script /tmp/ar_sample.json --save "$HERE/dist/عينة-عربية.docx" || echo "تعذر إنشاء DOCX: جرّب يدوياً"
  WORDCRAFT_LANGUAGE=ar "$ROOT/../wordcraft/target/release/wordcraft-cli" run --template blank --script /tmp/ar_sample.json --save "$HERE/dist/عينة-عربية.pdf" || echo "PDF اختياري"
  ls -lh "$HERE/dist/" || true
fi

echo "==> تم! شغّل الآن:"
echo "  WORDCRAFT_LANGUAGE=ar $ROOT/../wordcraft/target/release/wordcraft --sample"
echo "  أو: WORDCRAFT_LANGUAGE=ar $ROOT/../wordcraft/target/release/wordcraft dist/عينة-عربية.docx"
echo ""
echo "لإنشاء AppImage/Tarball كامل:"
echo "  packaging/linux/package.sh --formats \"tar appimage\"  # يحتاج nfpm + appimagetool"
