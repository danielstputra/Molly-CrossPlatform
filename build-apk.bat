@echo off
echo =====================================================================
echo  Molly AI Studio - Build Android Release APK (Flutter Standalone)
echo =====================================================================
echo.

where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter SDK belum terdeteksi di PATH sistem Windows ini.
    echo.
    echo Silakan unduh Flutter SDK dari https://flutter.dev atau jalankan:
    echo   winget install Google.Flutter
    echo.
    echo Atau gunakan GitHub Actions yang telah dikonfigurasi di:
    echo   .github/workflows/build-crossplatform.yml
    echo   untuk otomatis build Android APK dan iOS IPA di cloud.
    echo.
    pause
    exit /b 1
)

echo [1/3] Mengambil dependensi paket (flutter pub get)...
call flutter pub get
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Gagal menjalankan flutter pub get.
    pause
    exit /b 1
)

echo.
echo [2/3] Membangun Android Release APK...
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Gagal melakukan compile APK.
    pause
    exit /b 1
)

echo.
echo [3/3] Sukses! File APK Release berada di:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
pause
