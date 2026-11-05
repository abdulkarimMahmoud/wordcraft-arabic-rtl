@echo off
chcp 65001 >nul
echo ========================================
echo WordCraft Arabic - One-Click Installer
echo ========================================
echo.

REM Go to Downloads
cd /d "%USERPROFILE%\Downloads"
if not exist "wordcraft\.git" (
  echo Cloning wordcraft...
  git clone https://github.com/storytold/wordcraft.git
  if errorlevel 1 (
    echo ERROR: git clone failed. Install Git from https://git-scm.com
    pause
    exit /b 1
  )
)
cd wordcraft

echo Applying Arabic patch...
copy /Y "%USERPROFILE%\Downloads\WordCraft-Arabic-Package-EN\arabization-en\0002-wordcraft-ar-code.patch" . >nul
git config user.email "arabization@local" >nul 2>&1
git config user.name "Arabization" >nul 2>&1
git am --abort >nul 2>&1
git am 0002-wordcraft-ar-code.patch
if errorlevel 1 (
  echo Patch already applied or failed, continuing...
  git am --abort >nul 2>&1
)

echo.
echo Building WordCraft Arabic (15-20 minutes, please wait)...
echo.

REM Check for craft-i18n patch - build script will handle it
set CRAFT_I18N_DIR=%TEMP%\craft-i18n
if not exist "%CRAFT_I18N_DIR%\locales\ar\wordcraft.tsv" (
  if not exist "%TEMP%\craft-i18n" git clone https://github.com/storytold/craft-i18n "%TEMP%\craft-i18n"
)

REM Run the PowerShell build script
powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\Downloads\WordCraft-Arabic-Package-EN\arabization-en\build-windows-arabic.ps1" -Arch x64

echo.
echo ========================================
echo DONE! Check dist\release\
echo ========================================
dir dist\release\*.msi 2>nul
dir dist\release\*.zip 2>nul
echo.
echo To install MSI: double-click dist\release\wordcraft-*-windows-x64.msi
echo To run portable: Expand-Archive dist\release\*-portable.zip -DestinationPath C:\WordCraft-Arabic -Force
echo.
pause
