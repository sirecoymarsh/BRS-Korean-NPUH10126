@echo off
setlocal
chcp 65001 >nul
set "SOURCE=%~1"
if not defined SOURCE set /p "SOURCE=지원되는 원본 ISO 경로를 입력하세요: "
if not defined SOURCE (
  echo 원본 ISO 경로가 필요합니다.
  pause
  exit /b 2
)
if "%~2"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply-KoreanPatch.ps1" -SourceIso "%SOURCE%" -PatchFile "%~dp0BRS_Korean_NPUH10126_v1.0.brspatch"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply-KoreanPatch.ps1" -SourceIso "%SOURCE%" -OutputIso "%~2" -PatchFile "%~dp0BRS_Korean_NPUH10126_v1.0.brspatch"
)
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" echo 패치 적용에 실패했습니다. 위 오류를 확인하세요.
pause
exit /b %RC%
