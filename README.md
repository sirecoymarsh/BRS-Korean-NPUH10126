# BLACK★ROCK SHOOTER THE GAME 한국어 패치 v1.0

대상은 미국 PSN판 `NPUH10126`입니다. 배포본에는 게임 ISO가 들어 있지 않으며,
사용자가 보유한 지원 원본으로 새 한국어판 ISO를 생성합니다. 원본 ISO는 수정하지 않습니다.

## 현재 후보 상태

- 누적 패치 재빌드: 통과
- 빌더 델타 왕복 적용: 통과
- Windows PowerShell 설치 스크립트 왕복 적용: 통과
- 번역 릴리스 게이트: `4,777`항목, 오류 `0`, 경고 `0`
- PPSSPP `v1.20.4` 실기동 및 플레이 스모크 테스트: 통과

현재 대상 SHA-256의 부팅 로그와 정상 종료를 확인했으며, 사용자가 직접 플레이 후
정상 작동을 확인했습니다.

## 지원 원본

- 크기: `1,360,363,520`바이트
- SHA-256: `4735b0d0f59d480991fd8cf034e5b0f2d98798cec275ab4162df09b8a6d23f0e`

크기와 SHA-256이 모두 일치하지 않으면 설치 스크립트가 작업을 거부합니다.

## 설치

가장 쉬운 방법은 원본 ISO를 `Apply-KoreanPatch.bat` 위에 끌어다 놓는 것입니다.
또는 이 폴더에서 Windows PowerShell로 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Apply-KoreanPatch.ps1" -SourceIso "<원본_ISO_경로>"
```

출력 경로를 생략하면 원본과 같은 폴더에 `_Korean_v1.0.iso`가 생성됩니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Apply-KoreanPatch.ps1" -SourceIso "<원본_ISO_경로>" -OutputIso "<출력_ISO_경로>"
```

완성본 검증값:

- 크기: `1,379,434,496`바이트
- SHA-256: `e62bcb20ed9e341626a41e27c561a490a023a0b5339d6c1058901b281968c7b9`

## 패치 범위와 표기 원칙

- 대사, 컷씬 자막, 아이템명, 시스템 문구 등 텍스트 `4,777`항목을 반영했습니다.
- `General` 직함은 문맥에 맞게 `총독`으로 통일했습니다.
- 인간 및 시스템 발신자 이름은 한국어로 표시합니다.
- 외계인 고유명은 원작의 라틴 문자열을 유지합니다:
  `Mii / Mazuma / Shizu / Karli / Lilio / Nafe / Zaha`.
- 스테이지 그래픽 코드도 원작 표기
  `MEFE / MZMA / SZZU / CKRY / LLWO / XNFE / SAHA`를 유지합니다.
- ★MENU의 `CUSTOMIZE / ITEMS / CHALLENGES / OPTIONS / EXP / NEXT / LEVEL` 같은
  고정 그래픽 메뉴 라벨은 무리하게 ISO에 삽입하지 않고 영어를 유지합니다.

## 선택 설치: PPSSPP HD UI 팩

`BRS_Korean_HD_UI_Pack.zip`은 PPSSPP 전용 선택 설치 팩입니다. 27개 UI 텍스처를
8배 해상도로 제공합니다. 압축 안의 `PSP` 폴더를 PPSSPP 메모리 스틱 루트에
합친 뒤 **Replace Textures(텍스처 교체)** 를 켜십시오.

스테이지 외계인 코드는 LLWO 기준으로 중앙 정렬했고, SAHA 뒤에 `I`처럼 보이던
잔여 픽셀을 제거했습니다. 이 팩은 표시 전용이며 ISO 자체를 바꾸지 않습니다.

## 복원

설치 과정은 원본을 덮어쓰지 않습니다. `Restore-Original.bat`은 패치가 만든
한국어판 ISO가 패치 헤더의 크기와 SHA-256에 정확히 일치할 때만 그 출력물을
삭제합니다.

## 무결성

```powershell
Get-Content ".\CHECKSUMS.sha256"
Get-FileHash ".\BRS_Korean_NPUH10126_v1.0.brspatch" -Algorithm SHA256
```

패치 파일:

- 크기: `91,513,924`바이트
- SHA-256: `bf1e5acca39dc432aebcb58c0dabca5b85f3179b5737c0a370deaf47e76c1404`
- BRSPATCH 레코드: `4,080`개

상세 검증 결과는 `REPORTS/README.md`와 `RELEASE_REPORT.json`을 확인하십시오.
