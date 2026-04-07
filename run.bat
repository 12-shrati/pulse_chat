@echo off
REM Auto-detect local IP and run Flutter with the correct SERVER_IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R "IPv4"') do (
    set "IP=%%a"
    goto :found
)
:found
set IP=%IP: =%
if "%IP%"=="" set IP=10.0.2.2
echo Detected IP: %IP%
echo Starting Flutter with SERVER_IP=%IP% ...
flutter run --dart-define=SERVER_IP=%IP% %*
