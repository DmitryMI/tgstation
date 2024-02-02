@echo off

set BYOND_PATH=C:\Program Files (x86)\BYOND\bin
set BYOND_EXE_PATH="%BYOND_PATH%\byond.exe"
set DREAMDAEMON_EXE_PATH="%BYOND_PATH%\dreamdaemon.exe"

echo Checking for Byond.exe...
tasklist /fi "ImageName eq byond.exe" /fo csv 2>NUL | find /I "byond.exe">NUL

IF %ERRORLEVEL% EQU 0 (
	echo Byond already running
) ELSE (
	echo Byond not running. Starting BYOND, please wait...
	echo Starting: %BYOND_EXE_PATH%
	start "byond" %BYOND_EXE_PATH%
	timeout /t 10
)

echo Starting tgstation server...

start "tgstation" %DREAMDAEMON_EXE_PATH% tgstation.dmb 1337 -trusted

echo Console will close automatically in 5 seconds.
timeout /t 5