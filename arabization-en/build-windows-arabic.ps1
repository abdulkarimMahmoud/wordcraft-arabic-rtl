# بناء WordCraft بالعربية على Windows — MSI + Portable
# المتطلبات على Windows 10/11:
#   - Rust 1.95 MSVC (https://rustup.rs) — rustup toolchain install stable
#   - Windows SDK (rc.exe, signtool) — يأتي مع Visual Studio
#   - WiX Toolset v5.0.2 + UI/Util extensions:
#       dotnet tool install --global wix --version 5.0.2
#       wix extension add -g WixToolset.UI.wixext/5.0.2
#       wix extension add -g WixToolset.Util.wixext/5.0.2
#   - Git

param(
  [ValidateSet('x64','x86','arm64')] [string]$Arch = 'x64'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
# إذا كان هذا السكربت في arabization/، فالجذر هو مجلد wordcraft المجاور
if (-not (Test-Path (Join-Path $Root 'Cargo.toml'))) {
  $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\wordcraft')).Path
}
if (-not (Test-Path (Join-Path $Root 'Cargo.toml'))) {
  $Root = $PWD.Path
}

Write-Host "==> WordCraft Arabic — Windows $Arch" -ForegroundColor Cyan
Write-Host "    Root: $Root"
Write-Host "    craft-i18n.rev: $(Get-Content (Join-Path $Root 'craft-i18n.rev') -ErrorAction SilentlyContinue)"
Write-Host "    WORDCRAFT_LANGUAGE=ar"

# 1) التأكد من craft-i18n بالعربية
$CraftI18n = $env:CRAFT_I18N_DIR
if (-not $CraftI18n -or -not (Test-Path (Join-Path $CraftI18n 'locales\ar\wordcraft.tsv'))) {
  $CraftI18n = Join-Path $env:TEMP 'craft-i18n'
  if (-not (Test-Path $CraftI18n)) {
    Write-Host "==> استنساخ craft-i18n..." -ForegroundColor Yellow
    git clone https://github.com/storytold/craft-i18n $CraftI18n
  }
  # تطبيق الباتش العربي إذا وجد
  $Patch = Join-Path $PSScriptRoot '0001-ar-professional-terminology.patch'
  if (Test-Path $Patch) {
    Write-Host "==> تطبيق الباتش العربي..." -ForegroundColor Yellow
    Push-Location $CraftI18n
    git config user.email "arabization@local"
    git config user.name "WordCraft AR"
    try { git am $Patch } catch { Write-Host "الباتش مطبق مسبقاً أو فشل — تابع" -ForegroundColor DarkYellow }
    Pop-Location
  }
  $env:CRAFT_I18N_DIR = $CraftI18n
  Write-Host "CRAFT_I18N_DIR=$CraftI18n"
}

# 2) تثبيت الأدوات إن لزم
try { wix --version | Out-Null } catch {
  Write-Host "==> تثبيت WiX 5.0.2..." -ForegroundColor Yellow
  dotnet tool install --global wix --version 5.0.2
  wix extension add -g WixToolset.UI.wixext/5.0.2
  wix extension add -g WixToolset.Util.wixext/5.0.2
}

# 3) البناء
Write-Host "==> cargo build + WiX MSI ($Arch)..." -ForegroundColor Cyan
$env:CRAFT_I18N_DIR = $CraftI18n
$env:WORDCRAFT_LANGUAGE = "ar"
# البناء عبر سكربت التوزيع الرسمي
$PackageScript = Join-Path $Root 'packaging\windows\package.ps1'
if (Test-Path $PackageScript) {
  & $PackageScript -Arch $Arch
} else {
  # fallback: بناء يدوي
  $Target = switch ($Arch) { 'x64' { 'x86_64-pc-windows-msvc' } 'x86' { 'i686-pc-windows-msvc' } 'arm64' { 'aarch64-pc-windows-msvc' } }
  cargo build --release --locked -p wordcraft -p wordcraft-cli --target $Target
}

Write-Host "`n==> تم! الملفات في dist\release\" -ForegroundColor Green
Get-ChildItem (Join-Path $Root 'dist\release') -Filter "*windows-$Arch*" | Format-Table Name, Length, LastWriteTime

Write-Host "`n==> تثبيت MSI (يحتاج مسؤول):" -ForegroundColor Cyan
Write-Host "  msiexec /i dist\release\wordcraft-*-windows-$Arch.msi"
Write-Host "`n==> تشغيل محمول بدون تثبيت:" -ForegroundColor Cyan
Write-Host "  Expand-Archive dist\release\wordcraft-*-windows-$Arch-portable.zip -DestinationPath C:\WordCraft-Arabic"
Write-Host "  C:\WordCraft-Arabic\wordcraft.exe --sample"

# 4) إنشاء مستند عربي تجريبي
$Cli = Join-Path $Root "target\$Target\release\wordcraft-cli.exe"
if (-not (Test-Path $Cli)) { $Cli = Join-Path $Root 'target\release\wordcraft-cli.exe' }
if (Test-Path $Cli) {
  $SampleJson = Join-Path $env:TEMP 'ar_sample.json'
  $SampleContent = @'
[
  {"command":"text.insert","params":{"text":"Bism Allah al-Rahman al-Rahim\n"}},
  {"command":"para.align","params":{"align":"center"}},
  {"command":"text.insert","params":{"text":"Hatha mustanad tajribi - WordCraft RTL\n"}},
  {"command":"para.align","params":{"align":"right"}},
  {"command":"text.insert","params":{"text":"Inna al-lugha al-Arabiya lugha ghaniya.\n"}},
  {"command":"text.insert","params":{"text":"Mixed: WordCraft supports Arabic and English 123.\n"}}
]
'@
  [System.IO.File]::WriteAllText($SampleJson, $SampleContent, [System.Text.Encoding]::UTF8)
  & $Cli run --template blank --script $SampleJson --save "$PSScriptRoot\sample-arabic.docx"
  Write-Host "تم إنشاء عينة-عربية.docx" -ForegroundColor Green
}

Write-Host "`n==> للتشغيل بالعربية دائماً:" -ForegroundColor Yellow
Write-Host '  $env:WORDCRAFT_LANGUAGE="ar"; wordcraft.exe'
Write-Host '  أو: ملف › خيارات › لغة الواجهة › العربية'
