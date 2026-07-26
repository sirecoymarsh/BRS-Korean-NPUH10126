@echo off
setlocal
chcp 65001 >nul
set "PATCHED=%~1"
if not defined PATCHED set /p "PATCHED=삭제할 한국어판 ISO 경로를 입력하세요: "
if not defined PATCHED (
  echo 한국어판 ISO 경로가 필요합니다.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Restore-Original.ps1" -PatchedIso "%PATCHED%" -PatchFile "%~dp0BRS_Korean_NPUH10126_v1.0.brspatch"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo 복원에 실패했습니다. 검증되지 않은 ISO는 삭제되지 않습니다.
pause
exit /b %RC%
